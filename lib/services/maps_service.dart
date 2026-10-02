import '../models/geo_place.dart';
import '../models/route_info.dart';
import '../utils/app_exception.dart';
import '../utils/config.dart';
import '../utils/geo_math.dart';
import 'api_client.dart';

/// Geocoding (Open-Meteo), reverse geocoding (Nominatim) and routing (OSRM).
class MapsService {
  /// Accepts "Goa" or "Paris, France". The part after the comma narrows results.
  Future<List<GeoPlace>> search(String query) async {
    final parts = query.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return [];
    final uri = Uri.parse('${AppConfig.geocodingBase}/v1/search').replace(queryParameters: {
      'name': parts.first,
      'count': '10',
      'language': 'en',
      'format': 'json',
    });
    final j = await ApiClient.instance.getJson(uri);
    if (j is! Map<String, dynamic>) return [];
    final results = (j['results'] as List?) ?? const [];
    var places = results.whereType<Map<String, dynamic>>().map(GeoPlace.fromOpenMeteo).toList();

    if (parts.length > 1 && places.isNotEmpty) {
      final hint = parts.sublist(1).join(' ').toLowerCase();
      bool matches(String field) {
        final f = field.toLowerCase();
        return f.isNotEmpty && (f.contains(hint) || hint.contains(f));
      }

      final narrowed =
          places.where((p) => matches(p.country) || matches(p.region) || p.countryCode.toLowerCase() == hint).toList();
      if (narrowed.isNotEmpty) places = narrowed;
    }
    return places;
  }

  Future<GeoPlace> reverse(double lat, double lon) async {
    final uri = Uri.parse('${AppConfig.nominatimBase}/reverse').replace(queryParameters: {
      'format': 'jsonv2',
      'lat': '$lat',
      'lon': '$lon',
      'zoom': '10',
      'accept-language': 'en',
    });
    final j = await ApiClient.instance.getJson(uri);
    if (j is! Map<String, dynamic> || j['address'] is! Map) {
      throw const AppException('Couldn\'t identify your current town. Type your starting city instead.');
    }
    final a = Map<String, dynamic>.from(j['address'] as Map);
    final name = (a['city'] ?? a['town'] ?? a['village'] ?? a['county'] ?? a['state'] ?? 'Current location') as String;
    return GeoPlace(
      name: name,
      lat: lat,
      lon: lon,
      country: a['country'] as String? ?? '',
      countryCode: (a['country_code'] as String? ?? '').toUpperCase(),
      region: a['state'] as String? ?? '',
    );
  }

  /// Road distance when OSRM can route it, otherwise straight-line distance.
  Future<RouteInfo> route(GeoPlace from, GeoPlace to) async {
    final straight = haversineKm(from.lat, from.lon, to.lat, to.lon);
    if (straight > 2500) return RouteInfo(straightKm: straight);
    try {
      final uri = Uri.parse('${AppConfig.osrmBase}/route/v1/driving/${from.lon},${from.lat};${to.lon},${to.lat}')
          .replace(queryParameters: {'overview': 'false'});
      final j = await ApiClient.instance.getJson(uri);
      if (j is Map<String, dynamic> && j['code'] == 'Ok') {
        final routes = j['routes'];
        if (routes is List && routes.isNotEmpty && routes.first is Map<String, dynamic>) {
          final r = routes.first as Map<String, dynamic>;
          return RouteInfo(
            straightKm: straight,
            roadKm: (r['distance'] as num).toDouble() / 1000,
            driveMinutes: ((r['duration'] as num).toDouble() / 60).round(),
          );
        }
      }
    } on AppException {
      // Fall through to the straight-line estimate.
    }
    return RouteInfo(straightKm: straight);
  }
}
