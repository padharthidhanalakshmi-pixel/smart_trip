import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/common.dart';
import '../widgets/currency_picker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final provider = context.read<TripProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all saved trips?'),
        content: const Text('Every trip, checklist, budget and note on this device will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete all')),
        ],
      ),
    );
    if (ok == true) {
      await provider.clearAll();
      if (context.mounted) showSnack(context, 'All trips deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Preferences',
            icon: Icons.tune,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, label: Text('System')),
                      ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                    ],
                    selected: {s.themeMode},
                    onSelectionChanged: (v) => s.update(themeMode: v.first),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Units', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Metric')),
                      ButtonSegment(value: true, label: Text('Imperial')),
                    ],
                    selected: {s.imperial},
                    onSelectionChanged: (v) => s.update(imperial: v.first),
                  ),
                ),
                const SizedBox(height: 4),
                Text(s.imperial ? '°F, mph and miles' : '°C, km/h and kilometres', style: small),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Home currency'),
                  subtitle: Text('${s.homeCurrency}, used for budgets and the converter'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final code = await pickCurrency(context, current: s.homeCurrency);
                    if (code != null) s.update(homeCurrency: code);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionCard(
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            child: Text('Smart Trip doesn\'t send notifications in this version, so it never asks for '
                'notification permission.'),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Testing',
            icon: Icons.science_outlined,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use demo data'),
              subtitle: const Text('Try the app without internet. Demo data is always labelled and is not real.'),
              value: s.demoMode,
              onChanged: (v) => s.update(demoMode: v),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'About',
            icon: Icons.info_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Smart Trip Assistant 1.0', style: theme.textTheme.titleSmall),
                const Text('Plan smarter. Travel better.'),
                const SizedBox(height: 12),
                Text('Data sources', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  'Weather, geocoding and time zones: Open-Meteo.com\n'
                  'Places and maps: © OpenStreetMap contributors (Overpass API, Nominatim)\n'
                  'Routing: OSRM\n'
                  'Exchange rates: ExchangeRate-API\n'
                  'Currency details: REST Countries',
                  style: small,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your trips, checklists, budget and notes are stored only on this device. '
                  'There is no account and no cloud database.',
                  style: small,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _confirmClear(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete all saved trips'),
                  style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
