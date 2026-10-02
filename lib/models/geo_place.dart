class GeoPlace {
  const GeoPlace({
    required this.name,
    required this.lat,
    required this.lon,
    this.country = '',
    this.countryCode = '',
    this.region = '',
    this.timezone,
  });

  final String name;
  final double lat;
  final double lon;
  final String country;
  final String countryCode;
  final String region;
  final String? timezone;

  String get label {
    final parts = <String>[name];
    if (region.isNotEmpty && region != name) parts.add(region);
    if (country.isNotEmpty && country != name) parts.add(country);
    return parts.join(', ');
  }

  factory GeoPlace.fromOpenMeteo(Map<String, dynamic> j) => GeoPlace(
        name: j['name'] as String? ?? 'Unknown',
        lat: (j['latitude'] as num).toDouble(),
        lon: (j['longitude'] as num).toDouble(),
        country: j['country'] as String? ?? '',
        countryCode: (j['country_code'] as String? ?? '').toUpperCase(),
        region: j['admin1'] as String? ?? '',
        timezone: j['timezone'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'lat': lat,
        'lon': lon,
        'country': country,
        'countryCode': countryCode,
        'region': region,
        'timezone': timezone,
      };

  factory GeoPlace.fromJson(Map<String, dynamic> j) => GeoPlace(
        name: j['name'] as String? ?? '',
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        country: j['country'] as String? ?? '',
        countryCode: j['countryCode'] as String? ?? '',
        region: j['region'] as String? ?? '',
        timezone: j['timezone'] as String?,
      );
}
