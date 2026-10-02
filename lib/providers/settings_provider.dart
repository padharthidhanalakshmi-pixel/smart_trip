import 'package:flutter/material.dart';

import '../storage/local_store.dart';

class SettingsProvider extends ChangeNotifier {
  final _store = LocalStore();

  ThemeMode themeMode = ThemeMode.system;
  bool imperial = false;
  String homeCurrency = 'INR';
  bool demoMode = false;

  Future<void> load() async {
    final s = await _store.loadSettings();
    themeMode = ThemeMode.values.firstWhere((m) => m.name == s['themeMode'], orElse: () => ThemeMode.system);
    imperial = s['imperial'] == true;
    homeCurrency = s['homeCurrency'] as String? ?? 'INR';
    demoMode = s['demoMode'] == true;
    notifyListeners();
  }

  void update({ThemeMode? themeMode, bool? imperial, String? homeCurrency, bool? demoMode}) {
    if (themeMode != null) this.themeMode = themeMode;
    if (imperial != null) this.imperial = imperial;
    if (homeCurrency != null) this.homeCurrency = homeCurrency;
    if (demoMode != null) this.demoMode = demoMode;
    notifyListeners();
    _store.saveSettings({
      'themeMode': this.themeMode.name,
      'imperial': this.imperial,
      'homeCurrency': this.homeCurrency,
      'demoMode': this.demoMode,
    });
  }
}
