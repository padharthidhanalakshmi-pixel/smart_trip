import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/trip.dart';
import '../../providers/trip_provider.dart';
import '../../utils/checklists.dart';
import '../../utils/ids.dart';
import '../../widgets/common.dart';

class ChecklistsTab extends StatelessWidget {
  const ChecklistsTab({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final scope = trip.origin == null
        ? 'Add a starting location when planning to tailor these suggestions to domestic or international travel. '
        : (trip.international ? 'Suggestions for international travel. ' : 'Suggestions for domestic travel. ');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ChecklistSection(
          trip: trip,
          items: trip.packing,
          title: 'Packing checklist',
          icon: Icons.backpack_outlined,
          doneWord: 'packed',
          note: 'Built from your trip length, forecast, travel type and interests.',
        ),
        const SizedBox(height: 16),
        _ChecklistSection(
          trip: trip,
          items: trip.documents,
          title: 'Travel documents',
          icon: Icons.badge_outlined,
          doneWord: 'ready',
          note: '$scope$documentsDisclaimer',
        ),
        const SizedBox(height: 8),
        Text(
          'Checklists are saved on this device and work offline.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ChecklistSection extends StatefulWidget {
  const _ChecklistSection({
    required this.trip,
    required this.items,
    required this.title,
    required this.icon,
    required this.doneWord,
    this.note,
  });

  final Trip trip;
  final List<CheckItem> items;
  final String title;
  final IconData icon;
  final String doneWord;
  final String? note;

  @override
  State<_ChecklistSection> createState() => _ChecklistSectionState();
}

class _ChecklistSectionState extends State<_ChecklistSection> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.items.add(CheckItem(id: newId(), label: text, custom: true));
    _ctrl.clear();
    context.read<TripProvider>().save(widget.trip);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TripProvider>();
    final theme = Theme.of(context);
    final items = widget.items;
    final done = items.where((i) => i.checked).length;
    return SectionCard(
      title: widget.title,
      icon: widget.icon,
      trailing: Text('$done/${items.length} ${widget.doneWord}', style: theme.textTheme.labelLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.note != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                widget.note!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: items.isEmpty ? 0 : done / items.length, minHeight: 6),
          ),
          const SizedBox(height: 4),
          for (final item in items)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: item.checked,
              title: Text(item.label),
              onChanged: (_) {
                item.checked = !item.checked;
                provider.save(widget.trip);
              },
              secondary: item.custom
                  ? IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        items.remove(item);
                        provider.save(widget.trip);
                      },
                    )
                  : null,
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(hintText: 'Add your own item', isDense: true),
                  onSubmitted: (_) => _add(),
                ),
              ),
              IconButton(tooltip: 'Add item', icon: const Icon(Icons.add_circle_outline), onPressed: _add),
            ],
          ),
        ],
      ),
    );
  }
}
