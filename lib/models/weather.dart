import '../utils/format.dart';

class DayForecast {
  const DayForecast({required this.date, required this.code, required this.max, required this.min, this.rainChance});

  final DateTime date;
  final int code;
  final double max;
  final double min;
  final int? rainChance;
}

class WeatherReport {
  const WeatherReport({
    required this.temperature,
    required this.code,
    required this.humidity,
    required this.windSpeed,
    required this.rainChanceToday,
    required this.days,
    required this.utcOffset,
    required this.timezone,
    required this.imperial,
    required this.fetchedAt,
    this.isDemo = false,
  });

  final double temperature;
  final int code;
  final int humidity;
  final double windSpeed;
  final int? rainChanceToday;
  final List<DayForecast> days;
  final Duration utcOffset;
  final String timezone;
  final bool imperial;
  final DateTime fetchedAt;
  final bool isDemo;

  String get tempUnit => imperial ? '°F' : '°C';
  String get windUnit => imperial ? 'mph' : 'km/h';

  List<DayForecast> forRange(DateTime start, DateTime end) {
    final s = dateOnly(start);
    final e = dateOnly(end);
    return days.where((d) => !d.date.isBefore(s) && !d.date.isAfter(e)).toList();
  }
}
