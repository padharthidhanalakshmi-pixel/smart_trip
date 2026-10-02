import '../models/geo_place.dart';
import '../models/trip.dart';
import '../models/weather.dart';
import '../utils/format.dart';
import '../utils/geo_math.dart';
import '../utils/weather_codes.dart';
import 'currency_service.dart';

/// Placeholder data for testing without internet. Every screen that shows
/// it labels it as demo data, and names start with "Demo:".
class DemoData {
  DemoData._();

  static const _places = [
    ('City Museum', 'Museum', 0.012, 0.006),
    ('Heritage Fort', 'Historic', -0.018, 0.010),
    ('Central Park', 'Park', 0.004, -0.009),
    ('Riverside Viewpoint', 'Viewpoint', 0.020, 0.015),
    ('Art Gallery', 'Museum', -0.006, -0.004),
    ('Nature Reserve', 'Nature', 0.040, -0.030),
    ('Adventure Park', 'Adventure', -0.030, 0.025),
    ('Old Town Square', 'Attraction', 0.002, 0.003),
    ('Performing Arts Theatre', 'Culture', -0.009, 0.012),
    ('Market Street', 'Shopping', 0.006, 0.010),
    ('Shopping Mall', 'Shopping', -0.015, -0.012),
    ('Breakfast Cafe', 'Cafe', 0.001, -0.002),
    ('Corner Coffee House', 'Cafe', -0.004, 0.006),
    ('Family Restaurant', 'Restaurant', 0.003, 0.005),
    ('Local Kitchen', 'Restaurant', -0.007, -0.003),
    ('Rooftop Restaurant', 'Restaurant', 0.009, -0.006),
    ('Street Food Lane', 'Restaurant', -0.002, 0.009),
    ('Night Club', 'Nightlife', 0.011, 0.004),
  ];

  static List<PlaceItem> places(GeoPlace c) => [
        for (var i = 0; i < _places.length; i++)
          PlaceItem(
            id: 'demo/$i',
            name: 'Demo: ${_places[i].$1}',
            category: _places[i].$2,
            lat: c.lat + _places[i].$3,
            lon: c.lon + _places[i].$4,
            distanceKm: haversineKm(c.lat, c.lon, c.lat + _places[i].$3, c.lon + _places[i].$4),
            isDemo: true,
          ),
      ];

  static Duration offset(GeoPlace place) => Duration(minutes: ((place.lon / 15) * 60).round() ~/ 30 * 30);

  static WeatherReport weather({required bool imperial, required GeoPlace place}) {
    double t(double c) => imperial ? c * 9 / 5 + 32 : c;
    final today = dateOnly(DateTime.now());
    const codes = [1, 2, 3, 61, 80, 2, 0, 1, 3, 63, 2, 1, 0, 2, 81, 1];
    final days = [
      for (var i = 0; i < codes.length; i++)
        DayForecast(
          date: addDays(today, i),
          code: codes[i],
          max: t(30.0 - (i % 4)),
          min: t(22.0 - (i % 3)),
          rainChance: isRainCode(codes[i]) ? 70 : 10 + (i * 7) % 25,
        ),
    ];
    return WeatherReport(
      temperature: t(27),
      code: 2,
      humidity: 64,
      windSpeed: imperial ? 7.5 : 12,
      rainChanceToday: days.first.rainChance,
      days: days,
      utcOffset: offset(place),
      timezone: 'Demo',
      imperial: imperial,
      fetchedAt: DateTime.now(),
      isDemo: true,
    );
  }

  static const _sampleUsd = {
    'USD': 1.0, 'INR': 83.0, 'EUR': 0.92, 'GBP': 0.79, 'AED': 3.67, 'SGD': 1.35, 'THB': 36.0,
    'JPY': 150.0, 'AUD': 1.52, 'CAD': 1.36, 'MYR': 4.7, 'LKR': 300.0, 'NPR': 133.0,
  };

  static RatesResult rates(String base) {
    final baseUsd = _sampleUsd[base] ?? 1.0;
    return RatesResult(
      base: base,
      rates: {for (final e in _sampleUsd.entries) e.key: e.value / baseUsd},
      updated: '',
      source: 'sample demo rates (not real)',
      fetchedAt: DateTime.now(),
      isDemo: true,
    );
  }
}
