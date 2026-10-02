import 'package:flutter/foundation.dart';

import '../models/geo_place.dart';
import '../models/trip.dart';
import '../models/weather.dart';
import '../services/demo_data.dart';
import '../services/services.dart';
import '../storage/local_store.dart';
import '../utils/app_exception.dart';
import '../utils/checklists.dart';
import '../utils/ids.dart';
import '../utils/itinerary_builder.dart';
import '../utils/weather_tips.dart';
import 'settings_provider.dart';

class TripProvider extends ChangeNotifier {
  TripProvider(this.settings);

  final SettingsProvider settings;
  final _store = LocalStore();
  List<Trip> _trips = [];

  List<Trip> get trips => List.unmodifiable(_trips);
  Trip? get latest => _trips.isEmpty ? null : _trips.first;

  Trip? byId(String id) {
    for (final t in _trips) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> load() async {
    _trips = await _store.loadTrips();
    notifyListeners();
  }

  /// Persists a trip after it was changed in place.
  Future<void> save(Trip trip) async {
    notifyListeners();
    await _store.saveTrips(_trips);
  }

  /// Saves without notifying listeners. Safe to call from dispose().
  Future<void> persist() => _store.saveTrips(_trips);

  Future<void> delete(String id) async {
    _trips.removeWhere((t) => t.id == id);
    notifyListeners();
    await _store.saveTrips(_trips);
  }

  Future<void> clearAll() async {
    _trips = [];
    notifyListeners();
    await _store.saveTrips(_trips);
  }

  Future<Trip> plan(TripRequest request, {GeoPlace? originOverride, void Function(String step)? onStep}) async {
    final demo = settings.demoMode;

    onStep?.call('Finding ${request.destination}…');
    final matches = await Services.maps.search(request.destination);
    if (matches.isEmpty) {
      throw NotFoundException('We couldn\'t find "${request.destination}". Check the spelling, '
          'or add the country (for example "Paris, France").');
    }
    final destination = matches.first;

    GeoPlace? origin = originOverride;
    if (origin == null && request.origin.isNotEmpty) {
      try {
        final found = await Services.maps.search(request.origin);
        if (found.isNotEmpty) origin = found.first;
      } on AppException {
        origin = null;
      }
    }

    onStep?.call('Finding places to visit…');
    var places = <PlaceItem>[];
    var placesDemo = false;
    if (!demo) {
      try {
        places = await Services.places.nearby(destination);
      } on AppException {
        places = [];
      }
    }
    if (places.isEmpty) {
      places = DemoData.places(destination);
      placesDemo = true;
    }

    onStep?.call('Checking the weather…');
    WeatherReport? report;
    try {
      report = demo
          ? DemoData.weather(imperial: settings.imperial, place: destination)
          : await Services.weather.fetch(destination.lat, destination.lon, imperial: settings.imperial);
    } on AppException {
      report = null;
    }
    final forecast = report?.forRange(request.start, request.end) ?? const <DayForecast>[];

    onStep?.call('Building your itinerary…');
    final international = origin != null &&
        origin.countryCode.isNotEmpty &&
        destination.countryCode.isNotEmpty &&
        origin.countryCode != destination.countryCode;

    final trip = Trip(
      id: newId(),
      request: request,
      destination: destination,
      origin: origin,
      places: places,
      placesDemo: placesDemo,
      international: international,
      itinerary: ItineraryBuilder.build(request: request, places: places, forecast: forecast),
      packing: buildPackingList(
          request: request, forecast: forecast, imperial: settings.imperial, international: international),
      documents: buildDocumentList(international: international, travelType: request.travelType),
      weatherSummary: report == null || report.isDemo ? null : summarizeForecast(forecast, report),
    );
    _trips.insert(0, trip);
    notifyListeners();
    await _store.saveTrips(_trips);
    return trip;
  }

  Future<void> refreshPlaces(Trip trip) async {
    if (settings.demoMode) throw const AppException('Turn off demo data in Settings to load live places.');
    final fresh = await Services.places.nearby(trip.destination);
    if (fresh.isEmpty) throw const AppException('No places were found near this destination.');
    trip.places = fresh;
    trip.placesDemo = false;
    trip.favorites.removeWhere((id) => !fresh.any((p) => p.id == id));
    await save(trip);
  }

  Future<void> regenerateItinerary(Trip trip) async {
    trip.itinerary =
        ItineraryBuilder.build(request: trip.request, places: trip.places, forecast: const <DayForecast>[]);
    await save(trip);
  }

  Future<void> toggleFavorite(Trip trip, String placeId) async {
    if (!trip.favorites.remove(placeId)) trip.favorites.add(placeId);
    await save(trip);
  }

  // ---- Itinerary editing ----

  List<ItineraryItem> dayItems(Trip trip, int day) => trip.itinerary.where((i) => i.day == day).toList();

  void _setDay(Trip trip, int day, List<ItineraryItem> items) {
    final rebuilt = <ItineraryItem>[];
    for (var d = 1; d <= trip.days; d++) {
      rebuilt.addAll(d == day ? items : trip.itinerary.where((i) => i.day == d));
    }
    trip.itinerary = rebuilt;
  }

  Future<void> insertActivity(Trip trip, ItineraryItem item) async {
    final items = dayItems(trip, item.day)
      ..add(item)
      ..sort((a, b) => a.minutes.compareTo(b.minutes));
    _setDay(trip, item.day, items);
    await save(trip);
  }

  Future<void> addActivity(Trip trip,
      {required int day, required int minutes, required String title, PlaceItem? place}) {
    final hours = place?.openingHours;
    return insertActivity(
      trip,
      ItineraryItem(
        id: newId(),
        day: day,
        minutes: minutes,
        title: title,
        category: place?.category,
        placeId: place?.id,
        lat: place?.lat,
        lon: place?.lon,
        note: hours == null ? null : 'Hours: $hours (check before visiting)',
      ),
    );
  }

  /// Moves an activity and keeps the day's time slots in order.
  Future<void> reorder(Trip trip, int day, int oldIndex, int newIndex) async {
    final items = dayItems(trip, day);
    if (newIndex > oldIndex) newIndex -= 1;
    final times = items.map((i) => i.minutes).toList()..sort();
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    for (var k = 0; k < items.length; k++) {
      items[k].minutes = times[k];
    }
    _setDay(trip, day, items);
    await save(trip);
  }

  Future<void> setTime(Trip trip, ItineraryItem item, int minutes) async {
    item.minutes = minutes;
    final items = dayItems(trip, item.day)..sort((a, b) => a.minutes.compareTo(b.minutes));
    _setDay(trip, item.day, items);
    await save(trip);
  }

  Future<void> removeActivity(Trip trip, ItineraryItem item) async {
    trip.itinerary.remove(item);
    await save(trip);
  }

  Future<void> toggleDone(Trip trip, ItineraryItem item) async {
    item.done = !item.done;
    await save(trip);
  }
}
