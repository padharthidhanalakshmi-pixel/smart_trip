import 'currency_service.dart';
import 'maps_service.dart';
import 'places_service.dart';
import 'timezone_service.dart';
import 'weather_service.dart';

/// Single place to get service instances, so widgets never build HTTP calls.
class Services {
  Services._();

  static final maps = MapsService();
  static final places = PlacesService();
  static final weather = WeatherService();
  static final currency = CurrencyService();
  static final timeZone = TimeZoneService();
}
