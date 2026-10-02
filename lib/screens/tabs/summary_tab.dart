import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/trip.dart';
import '../../providers/settings_provider.dart';
import '../../utils/summary.dart';

class SummaryTab extends StatelessWidget {
  const SummaryTab({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<SettingsProvider>().homeCurrency;
    final text = buildTripSummary(trip, currency: currency);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton.icon(
          onPressed: () => Share.share(text, subject: 'Trip plan: ${trip.destination.name}'),
          icon: const Icon(Icons.share),
          label: const Text('Share Trip Plan'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: theme.colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          ),
        ),
      ],
    );
  }
}
