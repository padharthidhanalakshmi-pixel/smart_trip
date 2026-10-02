import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/format.dart';

/// Stacked bar plus legend showing how the budget is split.
class BudgetChart extends StatelessWidget {
  const BudgetChart({super.key, required this.values, required this.symbol});

  final Map<String, double> values;
  final String symbol;

  static const _palette = [
    Color(0xFF0E7C86),
    Color(0xFFF08A4B),
    Color(0xFF6C63FF),
    Color(0xFF2E9E5B),
    Color(0xFFE0B100),
    Color(0xFFD94F70),
    Color(0xFF7A869A),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = values.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) {
      return Text(
        'Add amounts below to see how your budget is split.',
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 18,
            child: Row(
              children: [
                for (var i = 0; i < entries.length; i++)
                  Expanded(
                    flex: math.max(1, (entries[i].value / total * 1000).round()),
                    child: Container(color: _palette[i % _palette.length]),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: _palette[i % _palette.length], shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(entries[i].key)),
                Text('$symbol${fmtNumber(entries[i].value, decimals: 0)}'),
                SizedBox(
                  width: 48,
                  child: Text('${(entries[i].value / total * 100).round()}%', textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
