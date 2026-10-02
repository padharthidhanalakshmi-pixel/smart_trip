import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/trip.dart';
import '../providers/trip_provider.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'trip_dashboard.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  Future<bool> _confirmDelete(BuildContext context, Trip trip) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this trip?'),
        content: Text('Your plan for ${trip.destination.name}, including checklists, budget and notes, '
            'will be removed from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<TripProvider>().trips;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('My trips')),
      body: trips.isEmpty
          ? const EmptyState(
              icon: Icons.luggage_outlined,
              title: 'No trips yet',
              message: 'Trips you plan on the Home tab are saved here, on this device.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final t = trips[i];
                return Dismissible(
                  key: ValueKey(t.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmDelete(ctx, t),
                  onDismissed: (_) => ctx.read<TripProvider>().delete(t.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration:
                        BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(20)),
                    child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
                  ),
                  child: Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    color: scheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(Icons.flight_takeoff, color: scheme.onPrimaryContainer),
                      ),
                      title: Text(t.destination.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${fmtRange(t.request.start, t.request.end)}\n'
                          '${t.days} ${t.days == 1 ? 'day' : 'days'}, '
                          '${t.request.travelers} ${t.request.travelers == 1 ? 'traveler' : 'travelers'}'),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(ctx)
                          .push(MaterialPageRoute<void>(builder: (_) => TripDashboard(tripId: t.id))),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
