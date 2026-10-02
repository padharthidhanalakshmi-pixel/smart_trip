import '../models/geo_place.dart';
import '../models/trip.dart';
import '../utils/app_exception.dart';
import '../utils/config.dart';
import '../utils/geo_math.dart';
import 'api_client.dart';

/// Points of interest from OpenStreetMap via the Overpass API (no key needed).
/// OSM has no ratings, so [PlaceItem.rating] stays null for these results.
class PlacesService {
  Future<List<PlaceItem>> nearby(GeoPlace center) async {
    final query = _query(center.lat, center.lon);
    AppException? lastError;
    for (final url in AppConfig.overpassEndpoints) {
      try {
        final j = await ApiClient.instance.postForm(Uri.parse(url), {'data': query}, timeout: const Duration(seconds: 45));
        return _parse(j, center);
      } on AppException catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? const AppException('Places are unavailable right now.');
  }

  String _query(double lat, double lon) {
    final wide = 'around:10000,$lat,$lon';
    final mid = 'around:8000,$lat,$lon';
    final near = 'around:2500,$lat,$lon';
    return '''
[out:json][timeout:40];
(
  nwr["tourism"~"^(attraction|museum|gallery|viewpoint|theme_park|zoo|aquarium)\$"]["name"]($wide);
  nwr["historic"~"^(monument|memorial|castle|ruins|archaeological_site|fort|palace)\$"]["name"]($wide);
  nwr["leisure"~"^(park|nature_reserve|water_park|garden)\$"]["name"]($mid);
  nwr["amenity"~"^(theatre|arts_centre|marketplace|nightclub)\$"]["name"]($mid);
  nwr["shop"~"^(mall|department_store)\$"]["name"]($mid);
)->.sights;
(
  nwr["amenity"~"^(restaurant|cafe|bar|pub)\$"]["name"]($near);
)->.food;
.sights out center 250;
.food out center 120;
''';
  }

  List<PlaceItem> _parse(dynamic j, GeoPlace c) {
    if (j is! Map<String, dynamic>) return [];
    final elements = (j['elements'] as List?) ?? const [];
    final seen = <String>{};
    final out = <PlaceItem>[];
    for (final raw in elements) {
      if (raw is! Map<String, dynamic>) continue;
      final tags = raw['tags'];
      if (tags is! Map<String, dynamic>) continue;
      final name = (tags['name:en'] ?? tags['name']) as String?;
      if (name == null || name.trim().isEmpty) continue;
      var lat = (raw['lat'] as num?)?.toDouble();
      var lon = (raw['lon'] as num?)?.toDouble();
      final center = raw['center'];
      if ((lat == null || lon == null) && center is Map<String, dynamic>) {
        lat = (center['lat'] as num?)?.toDouble();
        lon = (center['lon'] as num?)?.toDouble();
      }
      if (lat == null || lon == null) continue;
      final category = _category(tags);
      if (!seen.add('${name.toLowerCase()}|$category')) continue;
      out.add(PlaceItem(
        id: '${raw['type']}/${raw['id']}',
        name: name.trim(),
        category: category,
        lat: lat,
        lon: lon,
        distanceKm: haversineKm(c.lat, c.lon, lat, lon),
        openingHours: tags['opening_hours'] as String?,
      ));
    }
    out.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return out;
  }

  String _category(Map<String, dynamic> tags) {
    final t = tags['tourism'];
    final h = tags['historic'];
    final l = tags['leisure'];
    final a = tags['amenity'];
    final s = tags['shop'];
    if (t == 'museum' || t == 'gallery') return 'Museum';
    if (a == 'theatre' || a == 'arts_centre') return 'Culture';
    if (t == 'viewpoint') return 'Viewpoint';
    if (t == 'theme_park' || t == 'zoo' || t == 'aquarium' || l == 'water_park') return 'Adventure';
    if (h != null) return 'Historic';
    if (l == 'park' || l == 'garden') return 'Park';
    if (l == 'nature_reserve') return 'Nature';
    if (a == 'restaurant') return 'Restaurant';
    if (a == 'cafe') return 'Cafe';
    if (a == 'bar' || a == 'pub' || a == 'nightclub') return 'Nightlife';
    if (s != null || a == 'marketplace') return 'Shopping';
    return 'Attraction';
  }
}
