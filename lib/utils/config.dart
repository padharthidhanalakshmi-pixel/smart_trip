/// Build-time configuration.
///
/// Values come from `--dart-define` or `--dart-define-from-file=.env`.
/// Never hard-code API keys in source files.
class AppConfig {
  AppConfig._();

  /// Optional key for exchangerate-api.com. When empty, the keyless
  /// open.er-api.com endpoint is used instead.
  static const exchangeRateApiKey = String.fromEnvironment('EXCHANGE_RATE_API_KEY');

  /// Contact email sent to OpenStreetMap services, as their usage policy asks.
  static const contactEmail = String.fromEnvironment('APP_CONTACT_EMAIL');

  static const weatherBase = 'https://api.open-meteo.com';
  static const geocodingBase = 'https://geocoding-api.open-meteo.com';
  static const nominatimBase = 'https://nominatim.openstreetmap.org';
  static const osrmBase = 'https://router.project-osrm.org';
  static const overpassEndpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];
  static const restCountriesBase = 'https://restcountries.com';
  static const openExchangeBase = 'https://open.er-api.com';
  static const exchangeRateApiBase = 'https://v6.exchangerate-api.com';

  static String get userAgent =>
      contactEmail.isEmpty ? 'SmartTripAssistant/1.0' : 'SmartTripAssistant/1.0 ($contactEmail)';
}
