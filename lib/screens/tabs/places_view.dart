import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/trip.dart';
import '../../providers/settings_provider.dart';
import '../../providers/trip_provider.dart';
import '../../utils/app_exception.dart';
import '../../utils/format.dart';
import '../../utils/interests.dart';
import '../../utils/launchers.dart';
import '../../widgets/common.dart';

class PlacesView extends StatefulWidget {
  const PlacesView({super.key, required this.trip});

  final Trip trip;

  @override
  State<PlacesView> createState() => _PlacesViewState();
}

class _PlacesViewState extends State<PlacesView> {
  String _category = 'All';
  String _query = '';
  bool _savedOnly = false;
  bool _refreshing = false;

  Future<void> _refresh() async {
    final provider = context.read<TripProvider>();
    setState(() => _refreshing = true);
    try {
      await provider.refreshPlaces(widget.trip);
      if (mounted) showSnack(context, 'Live places loaded');
    } on AppException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final theme = Theme.of(context);
    final imperial = context.watch<SettingsProvider>().imperial;
    final categories = <String>{for (final p in trip.places) p.category}.toList()..sort();
    if (_category != 'All' && !categories.contains(_category)) _category = 'All';
    final q = _query.trim().toLowerCase();
    final list = trip.places
        .where((p) =>
            (_category == 'All' || p.category == _category) &&
            (!_savedOnly || trip.favorites.contains(p.id)) &&
            (q.isEmpty || p.name.toLowerCase().contains(q)))
        .toList();

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (trip.placesDemo)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DemoBanner(
              text: 'Demo places: live place data wasn\'t available. These names and locations are placeholders.',
              action: _refreshing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(onPressed: _refresh, child: const Text('Try live')),
            ),
          ),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            hintText: 'Search places',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('Saved'),
                avatar: Icon(_savedOnly ? Icons.favorite : Icons.favorite_border, size: 18),
                selected: _savedOnly,
                showCheckmark: false,
                onSelected: (v) => setState(() => _savedOnly = v),
              ),
              const SizedBox(width: 8),
              for (final c in ['All', ...categories]) ...[
                ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = c)),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '${list.length} ${list.length == 1 ? 'place' : 'places'}'
                '${trip.placesDemo ? '' : '. Data © OpenStreetMap contributors'}',
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (!trip.placesDemo)
              IconButton(
                tooltip: 'Reload places',
                onPressed: _refreshing ? null : _refresh,
                icon: const Icon(Icons.refresh),
              ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.isEmpty ? 2 : list.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) return header;
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.search_off,
            title: 'No places match',
            message: 'Try another category or clear the search.',
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PlaceCard(place: list[i - 1], trip: trip, imperial: imperial),
        );
      },
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place, required this.trip, required this.imperial});

  final PlaceItem place;
  final Trip trip;
  final bool imperial;

  Future<void> _addToItinerary(BuildContext context) async {
    final provider = context.read<TripProvider>();
    final day = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Add "${place.name}" to…', style: Theme.of(ctx).textTheme.titleMedium),
            ),
            for (var d = 1; d <= trip.days; d++)
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text('Day $d'),
                subtitle: Text(fmtDate(trip.dateForDay(d))),
                onTap: () => Navigator.pop(ctx, d),
              ),
          ],
        ),
      ),
    );
    if (day == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 16, minute: 0),
      helpText: 'Choose a time',
    );
    if (time == null) return;
    await provider.addActivity(trip, day: day, minutes: time.hour * 60 + time.minute, title: place.name, place: place);
    if (context.mounted) showSnack(context, 'Added to day $day');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final saved = trip.favorites.contains(place.id);
    final small = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(categoryIcon(place.category), color: scheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text('${place.category}, ${fmtDistance(place.distanceKm, imperial)} from the centre', style: small),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: saved ? 'Remove from saved' : 'Save place',
                  icon: Icon(saved ? Icons.favorite : Icons.favorite_border, color: saved ? scheme.error : null),
                  onPressed: () => context.read<TripProvider>().toggleFavorite(trip, place.id),
                ),
              ],
            ),
            if (place.rating != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Rating: ${place.rating!.toStringAsFixed(1)}', style: small),
              ),
            if (place.openingHours != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Hours: ${place.openingHours} (check before visiting)', style: small),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await openMap(place.lat, place.lon, place.name);
                    if (!ok && context.mounted) showSnack(context, 'Couldn\'t open a maps app on this device.');
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Map'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _addToItinerary(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add to itinerary'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
