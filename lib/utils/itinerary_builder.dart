import '../models/trip.dart';
import '../models/weather.dart';
import 'format.dart';
import 'geo_math.dart';
import 'ids.dart';
import 'interests.dart';
import 'weather_codes.dart';

/// Builds a day-by-day plan from nearby places.
///
/// Considers: trip length, interests (preferred categories), budget (low budget
/// favours free sights), distance (each stop is near the previous one) and
/// weather (indoor picks on rainy days). Opening hours are shown as notes.
class ItineraryBuilder {
  ItineraryBuilder._();

  static List<ItineraryItem> build({
    required TripRequest request,
    required List<PlaceItem> places,
    required List<DayForecast> forecast,
  }) {
    final cafes = places.where((p) => p.category == 'Cafe').toList();
    final restaurants = places.where((p) => p.category == 'Restaurant').toList();
    final shopping = places.where((p) => p.category == 'Shopping').toList();
    final nightlife = places.where((p) => p.category == 'Nightlife').toList();
    final sights = places.where((p) => !nonSightCategories.contains(p.category)).toList();
    final wanted = <String>{for (final i in request.interests) ...?interestCategories[i]};
    final lowBudget = request.budget == BudgetLevel.low;
    final used = <String>{};

    int score(PlaceItem p) {
      var s = 0;
      if (wanted.contains(p.category)) s += 10;
      if (lowBudget && freeCategories.contains(p.category)) s += 3;
      return s;
    }

    double dist(PlaceItem a, PlaceItem b) => haversineKm(a.lat, a.lon, b.lat, b.lon);

    PlaceItem? take(List<PlaceItem> pool, {PlaceItem? near, bool Function(PlaceItem)? where}) {
      final c = pool.where((p) => !used.contains(p.id) && (where == null || where(p))).toList();
      if (c.isEmpty) return null;
      c.sort((a, b) {
        final s = score(b) - score(a);
        if (s != 0) return s;
        return near == null ? a.distanceKm.compareTo(b.distanceKm) : dist(near, a).compareTo(dist(near, b));
      });
      used.add(c.first.id);
      return c.first;
    }

    final items = <ItineraryItem>[];
    void add(int day, int minutes, String title, {PlaceItem? place, String? category, String? note}) {
      final hours = place?.openingHours;
      items.add(ItineraryItem(
        id: newId(),
        day: day,
        minutes: minutes,
        title: title,
        category: place?.category ?? category,
        placeId: place?.id,
        lat: place?.lat,
        lon: place?.lon,
        note: note ?? (hours == null ? null : 'Hours: $hours (check before visiting)'),
      ));
    }

    bool indoor(PlaceItem p) => indoorCategories.contains(p.category);

    for (var day = 1; day <= request.days; day++) {
      final date = addDays(request.start, day - 1);
      DayForecast? fc;
      for (final f in forecast) {
        if (sameDate(f.date, date)) {
          fc = f;
          break;
        }
      }
      final wet = fc != null && ((fc.rainChance ?? 0) >= 60 || isRainCode(fc.code));
      const wetNote = 'Rain likely, so an indoor option was chosen';

      final breakfast = take(cafes) ?? take(restaurants);
      add(day, 9 * 60, breakfast == null ? 'Breakfast' : 'Breakfast at ${breakfast.name}',
          place: breakfast, category: 'Food');

      final first = (wet ? take(sights, where: indoor) : null) ?? take(sights);
      add(day, 10 * 60, first == null ? 'Explore the area at your own pace' : first.name,
          place: first, category: 'Sightseeing', note: first != null && wet && indoor(first) ? wetNote : null);

      final lunch = take(restaurants, near: first) ?? take(cafes, near: first);
      add(day, 13 * 60, lunch == null ? 'Lunch' : 'Lunch at ${lunch.name}', place: lunch, category: 'Food');

      final second = (wet ? take(sights, near: first, where: indoor) : null) ?? take(sights, near: first);
      add(day, 15 * 60, second == null ? 'Free time or rest' : second.name,
          place: second, category: 'Sightseeing', note: second != null && wet && indoor(second) ? wetNote : null);

      final anchor = second ?? first;
      final preferShopping = request.interests.contains('Shopping') || wet;
      final evening = (preferShopping ? take(shopping, near: anchor) : null) ??
          take(sights, near: anchor) ??
          take(shopping, near: anchor);
      final eveningTitle = evening == null
          ? 'Evening walk or local market'
          : (evening.category == 'Shopping' ? 'Shopping at ${evening.name}' : evening.name);
      add(day, 18 * 60, eveningTitle, place: evening, category: 'Evening');

      final dinner = take(restaurants, near: evening ?? anchor);
      add(day, 20 * 60, dinner == null ? 'Dinner' : 'Dinner at ${dinner.name}', place: dinner, category: 'Food');

      if (request.interests.contains('Nightlife')) {
        final night = take(nightlife, near: dinner ?? anchor);
        if (night != null) add(day, 21 * 60 + 30, 'Night out at ${night.name}', place: night, category: 'Nightlife');
      }
    }
    return items;
  }
}
