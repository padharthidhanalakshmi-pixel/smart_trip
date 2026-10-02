class EmergencyInfo {
  const EmergencyInfo({this.police, this.ambulance, this.fire, this.general, this.extra, required this.known});

  final String? police;
  final String? ambulance;
  final String? fire;
  final String? general;
  final String? extra;

  /// False when the country isn't in the built-in list.
  final bool known;

  List<(String, String)> get entries => [
        if (general != null) ('General emergency', general!),
        if (police != null) ('Police', police!),
        if (ambulance != null) ('Ambulance', ambulance!),
        if (fire != null) ('Fire', fire!),
      ];

  List<String> get lines => [
        for (final (label, number) in entries) '$label: $number',
        if (extra != null) extra!,
      ];
}

/// Built-in reference list of emergency numbers. Every screen showing these
/// also shows [sourceNote], asking the traveller to confirm locally.
class EmergencyService {
  EmergencyService._();

  static const sourceNote =
      'From the app\'s built-in reference list. Confirm with your hotel or local authorities when you arrive.';

  static const _eu112 = {
    'AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'GR', 'HU', 'IE', 'LV', 'LT', 'LU', 'MT', 'NL', 'PL',
    'PT', 'RO', 'SK', 'SI', 'ES', 'SE', 'NO', 'IS', 'TR', 'RU',
  };

  static const _table = <String, EmergencyInfo>{
    'IN': EmergencyInfo(general: '112', police: '100', ambulance: '108', fire: '101', known: true),
    'US': EmergencyInfo(general: '911', known: true),
    'CA': EmergencyInfo(general: '911', known: true),
    'MX': EmergencyInfo(general: '911', known: true),
    'PH': EmergencyInfo(general: '911', known: true),
    'GB': EmergencyInfo(general: '999', extra: '112 also works in the UK.', known: true),
    'AU': EmergencyInfo(general: '000', extra: '112 also works from mobile phones.', known: true),
    'NZ': EmergencyInfo(general: '111', known: true),
    'JP': EmergencyInfo(police: '110', ambulance: '119', fire: '119', known: true),
    'CN': EmergencyInfo(police: '110', ambulance: '120', fire: '119', known: true),
    'KR': EmergencyInfo(police: '112', ambulance: '119', fire: '119', known: true),
    'SG': EmergencyInfo(police: '999', ambulance: '995', fire: '995', known: true),
    'MY': EmergencyInfo(general: '999', fire: '994', known: true),
    'TH': EmergencyInfo(police: '191', ambulance: '1669', fire: '199', extra: 'Tourist police: 1155', known: true),
    'AE': EmergencyInfo(police: '999', ambulance: '998', fire: '997', known: true),
    'LK': EmergencyInfo(police: '119', ambulance: '1990', fire: '110', known: true),
    'NP': EmergencyInfo(police: '100', ambulance: '102', fire: '101', known: true),
    'BD': EmergencyInfo(general: '999', known: true),
    'ID': EmergencyInfo(general: '112', police: '110', ambulance: '118', fire: '113', known: true),
    'DE': EmergencyInfo(general: '112', police: '110', known: true),
    'FR': EmergencyInfo(general: '112', police: '17', ambulance: '15', fire: '18', known: true),
    'IT': EmergencyInfo(general: '112', police: '113', ambulance: '118', fire: '115', known: true),
    'CH': EmergencyInfo(general: '112', police: '117', ambulance: '144', fire: '118', known: true),
    'ZA': EmergencyInfo(police: '10111', ambulance: '10177', extra: '112 works from mobile phones.', known: true),
    'BR': EmergencyInfo(police: '190', ambulance: '192', fire: '193', known: true),
  };

  static EmergencyInfo forCountry(String countryCode) {
    final hit = _table[countryCode];
    if (hit != null) return hit;
    if (_eu112.contains(countryCode)) return const EmergencyInfo(general: '112', known: true);
    return const EmergencyInfo(general: '112', known: false);
  }
}
