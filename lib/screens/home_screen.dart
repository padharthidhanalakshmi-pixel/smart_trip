import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/geo_place.dart';
import '../models/trip.dart';
import '../providers/trip_provider.dart';
import '../services/location_service.dart';
import '../services/services.dart';
import '../utils/app_exception.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'trip_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _originCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  DateTimeRange? _range;
  int _travelers = 1;
  TravelType _type = TravelType.solo;
  BudgetLevel _budget = BudgetLevel.medium;
  final Set<String> _interests = {};
  GeoPlace? _originGeo;
  bool _locating = false;
  bool _planning = false;
  String? _destError;
  String? _dateError;

  @override
  void dispose() {
    _originCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final today = dateOnly(DateTime.now());
    final current = _range;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: addDays(today, 730),
      initialDateRange: current != null && !current.start.isBefore(today) ? current : null,
      helpText: 'Select travel dates',
      saveText: 'Done',
    );
    if (picked != null) {
      setState(() {
        _range = picked;
        _dateError = null;
      });
    }
  }

  Future<void> _useMyLocation() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.my_location),
        title: const Text('Use your current location?'),
        content: const Text(
            'Smart Trip uses your location once to fill in your starting point. It is not stored or shared.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _locating = true);
    try {
      final pos = await LocationService.current();
      final place = await Services.maps.reverse(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _originGeo = place;
        _originCtrl.text = place.label;
      });
    } on AppException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _plan() async {
    FocusScope.of(context).unfocus();
    final dest = _destCtrl.text.trim();
    final range = _range;
    String? dateError;
    if (range == null) {
      dateError = 'Choose your travel dates';
    } else if (daysBetween(range.start, range.end) + 1 > 30) {
      dateError = 'Trips can be up to 30 days long';
    }
    setState(() {
      _destError = dest.isEmpty ? 'Enter where you\'re going' : null;
      _dateError = dateError;
    });
    if (dest.isEmpty || dateError != null || range == null || _planning) return;

    final request = TripRequest(
      origin: _originCtrl.text.trim(),
      destination: dest,
      start: dateOnly(range.start),
      end: dateOnly(range.end),
      travelers: _travelers,
      travelType: _type,
      budget: _budget,
      interests: _interests.toList(),
    );
    final provider = context.read<TripProvider>();
    final navigator = Navigator.of(context);
    final step = ValueNotifier<String>('Getting started…');

    setState(() => _planning = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(width: 20),
              Expanded(
                child: ValueListenableBuilder<String>(valueListenable: step, builder: (_, s, __) => Text(s)),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final trip = await provider.plan(request, originOverride: _originGeo, onStep: (s) => step.value = s);
      navigator.pop();
      navigator.push(MaterialPageRoute<void>(builder: (_) => TripDashboard(tripId: trip.id)));
    } on NotFoundException catch (e) {
      navigator.pop();
      if (mounted) setState(() => _destError = e.message);
    } on AppException catch (e) {
      navigator.pop();
      if (mounted) showSnack(context, e.message);
    } catch (_) {
      navigator.pop();
      if (mounted) showSnack(context, 'Something went wrong while planning. Please try again.');
    } finally {
      if (mounted) setState(() => _planning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final range = _range;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text('Smart Trip Assistant',
                style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Where are you going?',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            SectionCard(
              title: 'Route',
              icon: Icons.alt_route,
              child: Column(
                children: [
                  TextField(
                    controller: _originCtrl,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => _originGeo = null,
                    decoration: InputDecoration(
                      labelText: 'Starting location',
                      hintText: 'e.g. Vijayawada',
                      prefixIcon: const Icon(Icons.trip_origin),
                      border: const OutlineInputBorder(),
                      suffixIcon: _locating
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : IconButton(
                              tooltip: 'Use my location',
                              icon: const Icon(Icons.my_location),
                              onPressed: _useMyLocation,
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _destCtrl,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) {
                      if (_destError != null) setState(() => _destError = null);
                    },
                    decoration: InputDecoration(
                      labelText: 'Destination',
                      hintText: 'e.g. Goa, or Paris, France',
                      prefixIcon: const Icon(Icons.place_outlined),
                      border: const OutlineInputBorder(),
                      errorText: _destError,
                      errorMaxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Trip details',
              icon: Icons.event_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _pickDates,
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Travel dates',
                        prefixIcon: const Icon(Icons.date_range),
                        border: const OutlineInputBorder(),
                        errorText: _dateError,
                      ),
                      child: Text(range == null
                          ? 'Choose dates'
                          : '${fmtRange(range.start, range.end)} (${daysBetween(range.start, range.end) + 1} days)'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Text('Travelers', style: theme.textTheme.titleSmall)),
                      IconButton.outlined(
                        tooltip: 'Fewer travelers',
                        onPressed: _travelers > 1 ? () => setState(() => _travelers--) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text('$_travelers', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
                      ),
                      IconButton.outlined(
                        tooltip: 'More travelers',
                        onPressed: _travelers < 20 ? () => setState(() => _travelers++) : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Travel type', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in TravelType.values)
                        ChoiceChip(
                          label: Text(t.label),
                          selected: _type == t,
                          onSelected: (_) => setState(() => _type = t),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Budget', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<BudgetLevel>(
                      segments: [
                        for (final b in BudgetLevel.values) ButtonSegment<BudgetLevel>(value: b, label: Text(b.label)),
                      ],
                      selected: {_budget},
                      onSelectionChanged: (s) => setState(() => _budget = s.first),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Interests',
              icon: Icons.favorite_border,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final i in kInterests)
                    FilterChip(
                      label: Text(i),
                      selected: _interests.contains(i),
                      onSelected: (v) => setState(() {
                        if (v) {
                          _interests.add(i);
                        } else {
                          _interests.remove(i);
                        }
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _planning ? null : _plan,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Plan My Trip'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
