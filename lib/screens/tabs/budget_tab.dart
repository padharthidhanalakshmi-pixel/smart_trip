import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/trip.dart';
import '../../providers/settings_provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/currency_service.dart';
import '../../utils/format.dart';
import '../../widgets/budget_chart.dart';
import '../../widgets/common.dart';

class BudgetTab extends StatefulWidget {
  const BudgetTab({super.key, required this.trip});

  final Trip trip;

  @override
  State<BudgetTab> createState() => _BudgetTabState();
}

class _BudgetTabState extends State<BudgetTab> {
  late final TextEditingController _total;
  late final Map<String, TextEditingController> _ctrls;

  static const _icons = {
    'Transportation': Icons.directions_bus_outlined,
    'Accommodation': Icons.hotel_outlined,
    'Food': Icons.restaurant_outlined,
    'Activities': Icons.local_activity_outlined,
    'Shopping': Icons.shopping_bag_outlined,
    'Emergency': Icons.health_and_safety_outlined,
    'Other': Icons.more_horiz,
  };

  @override
  void initState() {
    super.initState();
    _total = TextEditingController(text: _fmt(widget.trip.budgetTotal));
    _ctrls = {for (final c in kBudgetCategories) c: TextEditingController(text: _fmt(widget.trip.budget[c] ?? 0))};
  }

  @override
  void dispose() {
    _total.dispose();
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmt(double v) => v == 0 ? '' : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2));

  double _parse(String s) {
    final v = double.tryParse(s.replaceAll(',', '').trim());
    return v == null || v < 0 ? 0 : v;
  }

  void _changed() {
    final t = widget.trip;
    t.budgetTotal = _parse(_total.text);
    _ctrls.forEach((k, c) => t.budget[k] = _parse(c.text));
    context.read<TripProvider>().save(t);
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final currency = context.watch<SettingsProvider>().homeCurrency;
    final sym = currencySymbol(currency);
    final allocated = kBudgetCategories.fold<double>(0, (s, c) => s + (trip.budget[c] ?? 0));
    final remaining = trip.budgetTotal - allocated;
    const money = TextInputType.numberWithOptions(decimal: true);

    Widget stat(String label, String value, Color color) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
            Text(value, style: theme.textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.w800)),
          ],
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Total budget',
          icon: Icons.account_balance_wallet_outlined,
          child: Column(
            children: [
              TextField(
                controller: _total,
                keyboardType: money,
                onChanged: (_) => _changed(),
                decoration: InputDecoration(
                  labelText: 'Estimated total ($currency)',
                  prefixText: sym,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: stat('Planned', '$sym${fmtNumber(allocated, decimals: 0)}', scheme.onSurface)),
                  Expanded(
                    child: stat(
                      remaining >= 0 ? 'Remaining' : 'Over budget',
                      '$sym${fmtNumber(remaining.abs(), decimals: 0)}',
                      remaining >= 0 ? scheme.primary : scheme.error,
                    ),
                  ),
                ],
              ),
              if (trip.budgetTotal > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (allocated / trip.budgetTotal).clamp(0.0, 1.0).toDouble(),
                    minHeight: 10,
                    color: remaining < 0 ? scheme.error : null,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Breakdown',
          icon: Icons.bar_chart,
          child: BudgetChart(values: {for (final c in kBudgetCategories) c: trip.budget[c] ?? 0}, symbol: sym),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'By category',
          icon: Icons.edit_note,
          child: Column(
            children: [
              for (final c in kBudgetCategories)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: _ctrls[c],
                    keyboardType: money,
                    onChanged: (_) => _changed(),
                    decoration: InputDecoration(
                      labelText: c,
                      prefixText: sym,
                      prefixIcon: Icon(_icons[c]),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('Budget details are stored only on this device.', style: theme.textTheme.bodySmall),
      ],
    );
  }
}
