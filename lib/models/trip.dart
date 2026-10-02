import '../utils/format.dart';
import 'geo_place.dart';

enum TravelType {
  solo('Solo'),
  family('Family'),
  friends('Friends'),
  business('Business'),
  couple('Couple');

  const TravelType(this.label);
  final String label;
}

enum BudgetLevel {
  low('Low'),
  medium('Medium'),
  high('High');

  const BudgetLevel(this.label);
  final String label;
}

const kInterests = ['Nature', 'History', 'Food', 'Shopping', 'Adventure', 'Culture', 'Photography', 'Nightlife'];

const kBudgetCategories = ['Transportation', 'Accommodation', 'Food', 'Activities', 'Shopping', 'Emergency', 'Other'];

class TripRequest {
  const TripRequest({
    required this.origin,
    required this.destination,
    required this.start,
    required this.end,
    required this.travelers,
    required this.travelType,
    required this.budget,
    required this.interests,
  });

  final String origin;
  final String destination;
  final DateTime start;
  final DateTime end;
  final int travelers;
  final TravelType travelType;
  final BudgetLevel budget;
  final List<String> interests;

  int get days => daysBetween(start, end) + 1;

  Map<String, dynamic> toJson() => {
        'origin': origin,
        'destination': destination,
        'start': isoDate(start),
        'end': isoDate(end),
        'travelers': travelers,
        'travelType': travelType.name,
        'budget': budget.name,
        'interests': interests,
      };

  factory TripRequest.fromJson(Map<String, dynamic> j) => TripRequest(
        origin: j['origin'] as String? ?? '',
        destination: j['destination'] as String? ?? '',
        start: DateTime.parse(j['start'] as String),
        end: DateTime.parse(j['end'] as String),
        travelers: (j['travelers'] as num?)?.toInt() ?? 1,
        travelType: TravelType.values.byName(j['travelType'] as String? ?? 'solo'),
        budget: BudgetLevel.values.byName(j['budget'] as String? ?? 'medium'),
        interests: List<String>.from((j['interests'] as List?) ?? const []),
      );
}

class PlaceItem {
  const PlaceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lon,
    required this.distanceKm,
    this.openingHours,
    this.rating,
    this.isDemo = false,
  });

  final String id;
  final String name;
  final String category;
  final double lat;
  final double lon;
  final double distanceKm;
  final String? openingHours;
  final double? rating;
  final bool isDemo;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'lat': lat,
        'lon': lon,
        'distanceKm': distanceKm,
        'openingHours': openingHours,
        'rating': rating,
        'isDemo': isDemo,
      };

  factory PlaceItem.fromJson(Map<String, dynamic> j) => PlaceItem(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        category: j['category'] as String? ?? 'Attraction',
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        distanceKm: (j['distanceKm'] as num?)?.toDouble() ?? 0,
        openingHours: j['openingHours'] as String?,
        rating: (j['rating'] as num?)?.toDouble(),
        isDemo: j['isDemo'] == true,
      );
}

class ItineraryItem {
  ItineraryItem({
    required this.id,
    required this.day,
    required this.minutes,
    required this.title,
    this.category,
    this.note,
    this.placeId,
    this.lat,
    this.lon,
    this.done = false,
  });

  final String id;
  int day;
  int minutes;
  String title;
  final String? category;
  String? note;
  final String? placeId;
  final double? lat;
  final double? lon;
  bool done;

  bool get hasLocation => lat != null && lon != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'day': day,
        'minutes': minutes,
        'title': title,
        'category': category,
        'note': note,
        'placeId': placeId,
        'lat': lat,
        'lon': lon,
        'done': done,
      };

  factory ItineraryItem.fromJson(Map<String, dynamic> j) => ItineraryItem(
        id: j['id'] as String,
        day: (j['day'] as num).toInt(),
        minutes: (j['minutes'] as num).toInt(),
        title: j['title'] as String? ?? '',
        category: j['category'] as String?,
        note: j['note'] as String?,
        placeId: j['placeId'] as String?,
        lat: (j['lat'] as num?)?.toDouble(),
        lon: (j['lon'] as num?)?.toDouble(),
        done: j['done'] == true,
      );
}

class CheckItem {
  CheckItem({required this.id, required this.label, this.checked = false, this.custom = false});

  final String id;
  final String label;
  bool checked;
  final bool custom;

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'checked': checked, 'custom': custom};

  factory CheckItem.fromJson(Map<String, dynamic> j) => CheckItem(
        id: j['id'] as String,
        label: j['label'] as String? ?? '',
        checked: j['checked'] == true,
        custom: j['custom'] == true,
      );
}

class Trip {
  Trip({
    required this.id,
    required this.request,
    required this.destination,
    this.origin,
    required this.places,
    required this.itinerary,
    required this.packing,
    required this.documents,
    Set<String>? favorites,
    this.budgetTotal = 0,
    Map<String, double>? budget,
    this.notes = '',
    this.placesDemo = false,
    this.international = false,
    this.weatherSummary,
    DateTime? createdAt,
  })  : favorites = favorites ?? <String>{},
        budget = budget ?? <String, double>{},
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final TripRequest request;
  final GeoPlace destination;
  final GeoPlace? origin;
  List<PlaceItem> places;
  List<ItineraryItem> itinerary;
  final List<CheckItem> packing;
  final List<CheckItem> documents;
  final Set<String> favorites;
  double budgetTotal;
  final Map<String, double> budget;
  String notes;
  bool placesDemo;
  final bool international;
  String? weatherSummary;
  final DateTime createdAt;

  int get days => request.days;

  DateTime dateForDay(int day) => addDays(request.start, day - 1);

  Map<String, dynamic> toJson() => {
        'id': id,
        'request': request.toJson(),
        'destination': destination.toJson(),
        'origin': origin?.toJson(),
        'places': places.map((p) => p.toJson()).toList(),
        'itinerary': itinerary.map((i) => i.toJson()).toList(),
        'packing': packing.map((i) => i.toJson()).toList(),
        'documents': documents.map((i) => i.toJson()).toList(),
        'favorites': favorites.toList(),
        'budgetTotal': budgetTotal,
        'budget': budget,
        'notes': notes,
        'placesDemo': placesDemo,
        'international': international,
        'weatherSummary': weatherSummary,
        'createdAt': createdAt.toIso8601String(),
      };

  static List<Map<String, dynamic>> _maps(Object? list) =>
      ((list as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
        id: j['id'] as String,
        request: TripRequest.fromJson(Map<String, dynamic>.from(j['request'] as Map)),
        destination: GeoPlace.fromJson(Map<String, dynamic>.from(j['destination'] as Map)),
        origin: j['origin'] == null ? null : GeoPlace.fromJson(Map<String, dynamic>.from(j['origin'] as Map)),
        places: _maps(j['places']).map(PlaceItem.fromJson).toList(),
        itinerary: _maps(j['itinerary']).map(ItineraryItem.fromJson).toList(),
        packing: _maps(j['packing']).map(CheckItem.fromJson).toList(),
        documents: _maps(j['documents']).map(CheckItem.fromJson).toList(),
        favorites: Set<String>.from((j['favorites'] as List?) ?? const []),
        budgetTotal: (j['budgetTotal'] as num?)?.toDouble() ?? 0,
        budget: ((j['budget'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
        notes: j['notes'] as String? ?? '',
        placesDemo: j['placesDemo'] == true,
        international: j['international'] == true,
        weatherSummary: j['weatherSummary'] as String?,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      );
}
