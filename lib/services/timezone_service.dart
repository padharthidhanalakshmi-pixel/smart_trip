import '../models/geo_place.dart';
import '../utils/app_exception.dart';
import '../utils/config.dart';
import '../utils/format.dart';
import 'api_client.dart';

class TimeInfo {
  const TimeInfo({required this.destNow, required this.homeNow, required this.destOffset, required this.homeOffset});

  final DateTime destNow;
  final DateTime homeNow;
  final Duration destOffset;
  final Duration homeOffset;

  Duration get difference => destOffset - homeOffset;

  String describe() {
    final d = difference;
    if (d == Duration.zero) return 'Same time as home.';
    final amount = fmtDuration(d.inMinutes.abs());
    return d.isNegative ? 'Destination is $amount behind home.' : 'Destination is $amount ahead of home.';
  }
}

class TimeZoneService {
  /// Current UTC offset at a place, via Open-Meteo's automatic time zone.
  Future<Duration> offsetFor(GeoPlace place) async {
    final uri = Uri.parse('${AppConfig.weatherBase}/v1/forecast').replace(queryParameters: {
      'latitude': '${place.lat}',
      'longitude': '${place.lon}',
      'timezone': 'auto',
      'forecast_days': '1',
      'daily': 'weather_code',
    });
    final j = await ApiClient.instance.getJson(uri);
    if (j is Map<String, dynamic> && j['utc_offset_seconds'] is num) {
      return Duration(seconds: (j['utc_offset_seconds'] as num).toInt());
    }
    throw const AppException('Time zone information is not available.');
  }

  static TimeInfo compute(Duration destOffset) {
    final now = DateTime.now();
    return TimeInfo(
      destNow: now.toUtc().add(destOffset),
      homeNow: now,
      destOffset: destOffset,
      homeOffset: now.timeZoneOffset,
    );
  }
}
