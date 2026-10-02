import '../models/weather.dart';
import 'format.dart';
import 'weather_codes.dart';

/// Practical, non-medical suggestions based on the forecast.
List<String> weatherTips(WeatherReport r, List<DayForecast> tripDays) {
  final days = tripDays.isNotEmpty ? tripDays : r.days.take(1).toList();
  final hot = r.imperial ? 90.0 : 32.0;
  final cold = r.imperial ? 50.0 : 10.0;
  final tips = <String>[];
  if (days.any((d) => (d.rainChance ?? 0) >= 50 || isRainCode(d.code))) {
    tips.add('Rain expected — carry an umbrella or a light rain jacket.');
  }
  if (days.any((d) => d.max >= hot)) {
    tips.add('High temperature — carry water and sunscreen, and plan outdoor visits for mornings or evenings.');
  }
  if (days.any((d) => d.min <= cold)) tips.add('Cool temperatures — pack a warm layer.');
  if (days.any((d) => isSnowCode(d.code))) tips.add('Snow possible — pack warm, waterproof footwear.');
  if (days.any((d) => d.code >= 95)) tips.add('Thunderstorms possible — check local updates before outdoor plans.');
  if (r.windSpeed >= (r.imperial ? 25 : 40)) tips.add('Strong winds right now — take care at viewpoints and on the water.');
  if (tips.isEmpty) tips.add('Weather looks comfortable — no special preparation needed.');
  return tips;
}

/// One-line forecast summary stored with the trip for sharing.
String? summarizeForecast(List<DayForecast> days, WeatherReport r) {
  if (days.isEmpty) return null;
  var lo = days.first.min;
  var hi = days.first.max;
  for (final d in days) {
    if (d.min < lo) lo = d.min;
    if (d.max > hi) hi = d.max;
  }
  final rainy = days.where((d) => (d.rainChance ?? 0) >= 50 || isRainCode(d.code)).length;
  final rain = rainy == 0 ? 'little rain expected' : 'rain likely on $rainy of ${days.length} days';
  return '${lo.round()}–${hi.round()}${r.tempUnit}, $rain (forecast as of ${fmtDate(r.fetchedAt)})';
}
