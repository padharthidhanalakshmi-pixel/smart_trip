import 'package:flutter_test/flutter_test.dart';
import 'package:smart_trip_assistant/models/geo_place.dart';
import 'package:smart_trip_assistant/models/trip.dart';
import 'package:smart_trip_assistant/services/demo_data.dart';
import 'package:smart_trip_assistant/services/emergency_service.dart';
import 'package:smart_trip_assistant/utils/checklists.dart';
import 'package:smart_trip_assistant/utils/format.dart';
import 'package:smart_trip_assistant/utils/itinerary_builder.dart';

void main() {
  const goa = GeoPlace(name: 'Goa', lat: 15.49, lon: 73.82, country: 'India', countryCode: 'IN');
  final request = TripRequest(
    origin: 'Vijayawada',
    destination: 'Goa',
    start: DateTime(2026, 12, 20),
    end: DateTime(2026, 12, 22),
    travelers: 2,
    travelType: TravelType.friends,
    budget: BudgetLevel.low,
    interests: const ['Nature', 'Food'],
  );

  test('formats numbers with thousands separators', () {
    expect(fmtNumber(1234567.891), '1,234,567.89');
    expect(fmtNumber(999, decimals: 0), '999');
  });

  test('counts trip days inclusively', () {
    expect(request.days, 3);
  });

  test('builds a plan for every day without repeating places', () {
    final places = DemoData.places(goa);
    final items = ItineraryBuilder.build(request: request, places: places, forecast: const []);
    for (var d = 1; d <= request.days; d++) {
      expect(items.where((i) => i.day == d), isNotEmpty);
    }
    final ids = items.map((i) => i.placeId).whereType<String>().toList();
    expect(ids.toSet().length, ids.length);
  });

  test('packing and documents depend on trip type', () {
    final packing = buildPackingList(request: request, forecast: const [], imperial: false, international: false);
    expect(packing.any((i) => i.label.startsWith('Clothes for 3 days')), isTrue);
    final intl = buildDocumentList(international: true, travelType: TravelType.solo);
    expect(intl.any((i) => i.label == 'Passport'), isTrue);
  });

  test('unknown countries are marked unverified', () {
    expect(EmergencyService.forCountry('IN').known, isTrue);
    expect(EmergencyService.forCountry('XX').known, isFalse);
  });

  test('trips survive a JSON round trip', () {
    final trip = Trip(
      id: 't1',
      request: request,
      destination: goa,
      places: DemoData.places(goa),
      itinerary: [],
      packing: [],
      documents: [],
      budget: {'Food': 2500},
    );
    final copy = Trip.fromJson(trip.toJson());
    expect(copy.destination.name, 'Goa');
    expect(copy.budget['Food'], 2500);
    expect(copy.places.length, trip.places.length);
  });
}
