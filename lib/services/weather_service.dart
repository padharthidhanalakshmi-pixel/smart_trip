import '../models/weather.dart';
import '../utils/app_exception.dart';
import '../utils/config.dart';
import 'api_client.dart';

/// Weather from Open-Meteo (no API key needed). Forecasts reach 16 days ahead.
class WeatherService {
  Future<WeatherReport> fetch(double lat, double lon, {required bool imperial}) async {
    final uri = Uri.parse('${AppConfig.weatherBase}/v1/forecast').replace(queryParameters: {
      'latitude': '$lat',
      'longitude': '$lon',
      'current': 'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'timezone': 'auto',
      'forecast_days': '16',
      'temperature_unit': imperial ? 'fahrenheit' : 'celsius',
      'wind_speed_unit': imperial ? 'mph' : 'kmh',
    });
    final j = await ApiClient.instance.getJson(uri);
    if (j is! Map<String, dynamic>) throw const AppException('Weather data is not available right now.');
    final cur = j['current'];
    final daily = j['daily'];
    if (cur is! Map<String, dynamic> || daily is! Map<String, dynamic>) {
      throw const AppException('Weather data is not available for this location.');
    }
    final temp = cur['temperature_2m'];
    if (temp is! num) throw const AppException('Weather data is not available for this location.');

    final times = (daily['time'] as List?) ?? const [];
    final codes = (daily['weather_code'] as List?) ?? const [];
    final maxs = (daily['temperature_2m_max'] as List?) ?? const [];
    final mins = (daily['temperature_2m_min'] as List?) ?? const [];
    final rain = (daily['precipitation_probability_max'] as List?) ?? const [];

    final days = <DayForecast>[];
    for (var i = 0; i < times.length; i++) {
      final mx = _num(maxs, i);
      final mn = _num(mins, i);
      if (mx == null || mn == null) continue;
      days.add(DayForecast(
        date: DateTime.parse(times[i] as String),
        code: _num(codes, i)?.toInt() ?? 0,
        max: mx.toDouble(),
        min: mn.toDouble(),
        rainChance: _num(rain, i)?.toInt(),
      ));
    }

    return WeatherReport(
      temperature: temp.toDouble(),
      code: (cur['weather_code'] as num?)?.toInt() ?? 0,
      humidity: (cur['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      windSpeed: (cur['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      rainChanceToday: days.isEmpty ? null : days.first.rainChance,
      days: days,
      utcOffset: Duration(seconds: (j['utc_offset_seconds'] as num?)?.toInt() ?? 0),
      timezone: j['timezone'] as String? ?? '',
      imperial: imperial,
      fetchedAt: DateTime.now(),
    );
  }

  static num? _num(List list, int i) => i < list.length && list[i] is num ? list[i] as num : null;
}
