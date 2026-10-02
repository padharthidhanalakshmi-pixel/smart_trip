import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/trip.dart';
import '../../providers/trip_provider.dart';
import '../../utils/format.dart';
import '../../utils/launchers.dart';
import '../../widgets/common.dart';

class ItineraryTab extends StatefulWidget {
  const ItineraryTab({super.key, required this.trip});

  final Trip trip;

  @override
  State<ItineraryTab> createState() => _ItineraryTabState();
}

class _ItineraryTabState extends State<ItineraryTab> {
  int _day = 1;

  Future<void> _addActivity() async {
    final provider = context.read<TripProvider>();
    final ctrl = TextEditingController();
    var time = const TimeOfDay(hour: 12, minute: 0);
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Add to day $_day'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: 'Activity', hintText: 'e.g. Boat ride', errorText: error),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: time);
                  if (picked != null) setLocal(() => time = picked);
                },
                icon: const Icon(Icons.schedule),
                label: Text('Time: ${time.format(ctx)}'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (ctrl.text.trim().isEmpty) {
                  setLocal(() => error = 'Enter an activity name');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await provider.addActivity(widget.trip, day: _day, minutes: time.hour * 60 + time.minute, title: ctrl.text.trim());
    }
  }

  Future<void> _regenerate() async {
    final provider = context.read<TripProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rebuild the itinerary?'),
        content: const Text('This replaces every day\'s plan, including activities you added or edited.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rebuild')),
        ],
      ),
    );
    if (ok == true) await provider.regenerateItinerary(widget.trip);
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    if (_day > trip.days) _day = 1;
    final provider = context.read<TripProvider>();
    final items = provider.dayItems(trip, _day);
    final theme = Theme.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addActivity,
        icon: const Icon(Icons.add),
        label: const Text('Add activity'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: trip.days,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final d = i + 1;
                return ChoiceChip(
                  label: Text('Day $d, ${fmtShortDate(trip.dateForDay(d))}'),
                  selected: d == _day,
                  onSelected: (_) => setState(() => _day = d),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Drag to reorder. Tap a time to change it.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                TextButton.icon(onPressed: _regenerate, icon: const Icon(Icons.autorenew, size: 18), label: const Text('Rebuild')),
              ],
            ),
          ),
          if (trip.placesDemo)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: DemoBanner(text: 'This plan uses demo places, not real venues.'),
            ),
          Expanded(
            child: items.isEmpty
                ? const EmptyState(
                    icon: Icons.event_note_outlined,
                    title: 'Nothing planned for this day',
                    message: 'Add an activity, or add places from the Places tab.',
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    buildDefaultDragHandles: false,
                    itemCount: items.length,
                    onReorder: (oldIndex, newIndex) => provider.reorder(trip, _day, oldIndex, newIndex),
                    itemBuilder: (_, i) => _ActivityTile(
                      key: ValueKey(items[i].id),
                      item: items[i],
                      index: i,
                      trip: trip,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({super.key, required this.item, required this.index, required this.trip});

  final ItineraryItem item;
  final int index;
  final Trip trip;

  Future<void> _editTime(BuildContext context) async {
    final provider = context.read<TripProvider>();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: item.minutes ~/ 60, minute: item.minutes % 60),
    );
    if (picked != null) await provider.setTime(trip, item, picked.hour * 60 + picked.minute);
  }

  Future<void> _remove(BuildContext context) async {
    final provider = context.read<TripProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await provider.removeActivity(trip, item);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Removed "${item.title}"'),
        action: SnackBarAction(label: 'Undo', onPressed: () => provider.insertActivity(trip, item)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final provider = context.read<TripProvider>();
    final lat = item.lat;
    final lon = item.lon;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Checkbox(value: item.done, onChanged: (_) => provider.toggleDone(trip, item)),
              InkWell(
                onTap: () => _editTime(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Text(
                    fmtMinutes(item.minutes),
                    style: theme.textTheme.titleSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: item.done ? TextDecoration.lineThrough : null,
                        color: item.done ? scheme.outline : null,
                      ),
                    ),
                    if (item.note != null)
                      Text(item.note!, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'More options',
                onSelected: (v) async {
                  if (v == 'time') await _editTime(context);
                  if (v == 'map' && lat != null && lon != null) await openMap(lat, lon, item.title);
                  if (v == 'remove' && context.mounted) await _remove(context);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'time', child: Text('Edit time')),
                  if (item.hasLocation) const PopupMenuItem(value: 'map', child: Text('Open in maps')),
                  const PopupMenuItem(value: 'remove', child: Text('Remove')),
                ],
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.drag_handle)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
