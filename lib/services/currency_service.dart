import '../utils/app_exception.dart';
import '../utils/config.dart';
import 'api_client.dart';

class CurrencyInfo {
  const CurrencyInfo(this.code, this.name, this.symbol);
  final String code;
  final String name;
  final String symbol;
}

class RatesResult {
  const RatesResult({
    required this.base,
    required this.rates,
    required this.updated,
    required this.source,
    required this.fetchedAt,
    this.isDemo = false,
  });

  final String base;
  final Map<String, double> rates;
  final String updated;
  final String source;
  final DateTime fetchedAt;
  final bool isDemo;
}

const kCurrencies = [
  'INR', 'USD', 'EUR', 'GBP', 'AED', 'AUD', 'BDT', 'BRL', 'CAD', 'CHF', 'CNY', 'EGP', 'HKD', 'IDR', 'JPY',
  'KRW', 'LKR', 'MVR', 'MXN', 'MYR', 'NPR', 'NZD', 'PHP', 'QAR', 'SAR', 'SGD', 'THB', 'TRY', 'VND', 'ZAR',
];

// Static facts used when the country API is unreachable.
const _countryCurrency = {
  'IN': 'INR', 'US': 'USD', 'GB': 'GBP', 'AE': 'AED', 'AU': 'AUD', 'BD': 'BDT', 'BR': 'BRL', 'CA': 'CAD',
  'CH': 'CHF', 'CN': 'CNY', 'EG': 'EGP', 'HK': 'HKD', 'ID': 'IDR', 'JP': 'JPY', 'KR': 'KRW', 'LK': 'LKR',
  'MV': 'MVR', 'MX': 'MXN', 'MY': 'MYR', 'NP': 'NPR', 'NZ': 'NZD', 'PH': 'PHP', 'QA': 'QAR', 'SA': 'SAR',
  'SG': 'SGD', 'TH': 'THB', 'TR': 'TRY', 'VN': 'VND', 'ZA': 'ZAR', 'DE': 'EUR', 'FR': 'EUR', 'IT': 'EUR',
  'ES': 'EUR', 'NL': 'EUR', 'BE': 'EUR', 'AT': 'EUR', 'PT': 'EUR', 'IE': 'EUR', 'GR': 'EUR', 'FI': 'EUR',
};

const _symbols = {
  'INR': '₹', 'USD': '\$', 'EUR': '€', 'GBP': '£', 'JPY': '¥', 'CNY': '¥', 'KRW': '₩', 'THB': '฿',
  'SGD': 'S\$', 'AUD': 'A\$', 'CAD': 'C\$', 'NZD': 'NZ\$', 'HKD': 'HK\$', 'PHP': '₱', 'VND': '₫', 'TRY': '₺',
};

/// Symbol for display, e.g. "₹". Falls back to "CODE ".
String currencySymbol(String code) => _symbols[code] ?? '$code ';

class CurrencyService {
  final Map<String, RatesResult> _cache = {};

  Future<CurrencyInfo?> forCountry(String countryCode) async {
    if (countryCode.isEmpty) return null;
    try {
      final j = await ApiClient.instance
          .getJson(Uri.parse('${AppConfig.restCountriesBase}/v3.1/alpha/$countryCode?fields=currencies'));
      final obj = j is List && j.isNotEmpty ? j.first : j;
      if (obj is Map<String, dynamic>) {
        final cur = obj['currencies'];
        if (cur is Map<String, dynamic> && cur.isNotEmpty) {
          final code = cur.keys.first;
          final v = cur[code];
          final name = v is Map ? (v['name'] as String? ?? code) : code;
          final symbol = v is Map ? (v['symbol'] as String? ?? code) : code;
          return CurrencyInfo(code, name, symbol);
        }
      }
    } on AppException {
      // Use the built-in table below.
    }
    final code = _countryCurrency[countryCode];
    return code == null ? null : CurrencyInfo(code, code, currencySymbol(code).trim());
  }

  Future<RatesResult> rates(String base) async {
    final cached = _cache[base];
    if (cached != null && DateTime.now().difference(cached.fetchedAt) < const Duration(hours: 1)) return cached;
    RatesResult result;
    if (AppConfig.exchangeRateApiKey.isNotEmpty) {
      try {
        result = await _keyed(base);
      } on AppException {
        result = await _open(base);
      }
    } else {
      result = await _open(base);
    }
    _cache[base] = result;
    return result;
  }

  Future<RatesResult> _open(String base) async {
    final j = await ApiClient.instance.getJson(Uri.parse('${AppConfig.openExchangeBase}/v6/latest/$base'));
    if (j is! Map<String, dynamic> || j['result'] != 'success' || j['rates'] is! Map) {
      throw AppException('Exchange rates for $base are not available right now.');
    }
    return RatesResult(
      base: base,
      rates: _toRates(j['rates'] as Map),
      updated: j['time_last_update_utc'] as String? ?? '',
      source: 'ExchangeRate-API (open access)',
      fetchedAt: DateTime.now(),
    );
  }

  Future<RatesResult> _keyed(String base) async {
    final j = await ApiClient.instance.getJson(
        Uri.parse('${AppConfig.exchangeRateApiBase}/v6/${AppConfig.exchangeRateApiKey}/latest/$base'));
    if (j is! Map<String, dynamic> || j['result'] != 'success' || j['conversion_rates'] is! Map) {
      throw const AppException('The exchange-rate API key is missing or invalid. Check EXCHANGE_RATE_API_KEY in .env.');
    }
    return RatesResult(
      base: base,
      rates: _toRates(j['conversion_rates'] as Map),
      updated: j['time_last_update_utc'] as String? ?? '',
      source: 'ExchangeRate-API',
      fetchedAt: DateTime.now(),
    );
  }

  static Map<String, double> _toRates(Map raw) {
    final out = <String, double>{};
    raw.forEach((k, v) {
      if (k is String && v is num) out[k] = v.toDouble();
    });
    return out;
  }
}
