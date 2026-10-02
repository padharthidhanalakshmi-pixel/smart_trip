import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/trip_provider.dart';
import '../widgets/common.dart';
import 'tabs/budget_tab.dart';
import 'tabs/checklists_tab.dart';
import 'tabs/itinerary_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/places_view.dart';
import 'tabs/summary_tab.dart';
import 'tabs/tools_tab.dart';

class TripDashboard extends StatelessWidget {
  const TripDashboard({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().byId(tripId);
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.luggage_outlined, title: 'Trip not found', message: 'This trip was deleted.'),
      );
    }
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: Text(trip.destination.name),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Itinerary'),
              Tab(text: 'Places'),
              Tab(text: 'Checklists'),
              Tab(text: 'Budget'),
              Tab(text: 'Tools'),
              Tab(text: 'Summary'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OverviewTab(trip: trip),
            ItineraryTab(trip: trip),
            PlacesView(trip: trip),
            ChecklistsTab(trip: trip),
            BudgetTab(trip: trip),
            ToolsTab(trip: trip),
            SummaryTab(trip: trip),
          ],
        ),
      ),
    );
  }
}
