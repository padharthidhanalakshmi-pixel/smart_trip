import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/trip_provider.dart';
import '../widgets/common.dart';
import 'tabs/places_view.dart';

/// Places around the most recently planned trip.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().latest;
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Explore')),
        body: const EmptyState(
          icon: Icons.explore_outlined,
          title: 'Nothing to explore yet',
          message: 'Plan a trip and nearby attractions, restaurants and more will show up here.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Explore ${trip.destination.name}')),
      body: PlacesView(key: ValueKey(trip.id), trip: trip),
    );
  }
}
