import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/route_info.dart';
import '../../models/trip.dart';
import '../../models/weather.dart';
import '../../providers/settings_provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/currency_service.dart';
import '../../services/demo_data.dart';
import '../../services/emergency_service.dart';
import '../../services/services.dart';
import '../../services/timezone_service.dart';
import '../../utils/app_exception.dart';
import '../../utils/format.dart';
import '../../utils/launchers.dart';
import '../../utils/transport.dart';
import '../../utils/weather_codes.dart';
import '../../utils/weather_tips.dart';
import '../../widgets/common.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key, required this.trip});

  final Trip trip;

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> with AutomaticKeepAliveClientMixin {
  late Future<WeatherReport> _weather;
  late Future<RouteInfo?> _route;
  late Future<CurrencyInfo?> _currency;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final settings = context.read<SettingsProvider>();
    final t = widget.trip;
    _weather = settings.demoMode
        ? Future.value(DemoData.weather(imperial: settings.imperial, place: t.destination))
        : Services.weather.fetch(t.destination.lat, t.destination.lon, imperial: settings.imperial);
    _weather.then(_rememberWeather, onError: (Object _) {});
    final origin = t.origin;
    _route = origin == null ? Future<RouteInfo?>.value() : Services.maps.route(origin, t.destination);
    _currency = Services.currency.forCountry(t.destination.countryCode);
  }

  /// Keeps a one-line forecast on the trip so the shared summary includes it.
  void _rememberWeather(WeatherReport r) {
    if (r.isDemo || !mounted) return;
    final t = widget.trip;
    final summary = summarizeForecast(r.forRange(t.request.start, t.request.end), r);
    if (summary != null && summary != t.weatherSummary) {
      t.weatherSummary = summary;
      context.read<TripProvider>().save(t);
    }
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([
      _weather.then((_) {}, onError: (Object _) {}),
      _route.then((_) {}, onError: (Object _) {}),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = widget.trip;
    final r = t.request;
    final imperial = context.watch<SettingsProvider>().imperial;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Hero(trip: t),
          const SizedBox(height: 16),
          TwoColumnGrid(children: [
            FutureBuilder<WeatherReport>(
              future: _weather,
              builder: (_, s) => InfoTile(
                icon: s.hasData ? weatherIcon(s.data!.code) : Icons.thermostat,
                label: 'Weather now',
                value: s.hasData ? '${s.data!.temperature.round()}${s.data!.tempUnit}' : (s.hasError ? 'Unavailable' : '…'),
                caption: s.hasData ? weatherLabel(s.data!.code) : null,
              ),
            ),
            InfoTile(
              icon: Icons.date_range,
              label: 'Duration',
              value: '${t.days} ${t.days == 1 ? 'day' : 'days'}',
              caption: '${t.days - 1} ${t.days - 1 == 1 ? 'night' : 'nights'}',
            ),
            FutureBuilder<RouteInfo?>(
              future: _route,
              builder: (_, s) {
                final route = s.data;
                return InfoTile(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: t.origin == null
                      ? 'Add a start'
                      : route != null
                          ? fmtDistance(route.distanceKm, imperial)
                          : (s.connectionState == ConnectionState.done ? 'Unavailable' : '…'),
                  caption: route == null ? null : (route.byRoad ? 'By road' : 'Straight line'),
                );
              },
            ),
            FutureBuilder<CurrencyInfo?>(
              future: _currency,
              builder: (_, s) => InfoTile(
                icon: Icons.payments_outlined,
                label: 'Local currency',
                value: s.data?.code ?? (s.connectionState == ConnectionState.done ? 'Unknown' : '…'),
                caption: s.data?.name,
              ),
            ),
            FutureBuilder<WeatherReport>(
              future: _weather,
              builder: (_, s) {
                final report = s.data;
                if (report == null) {
                  return InfoTile(icon: Icons.schedule, label: 'Local time', value: s.hasError ? 'Unavailable' : '…');
                }
                final info = TimeZoneService.compute(report.utcOffset);
                return InfoTile(
                  icon: Icons.schedule,
                  label: 'Local time',
                  value: fmtClock(info.destNow),
                  caption: report.isDemo ? 'Demo estimate' : fmtOffset(info.destOffset),
                );
              },
            ),
            InfoTile(
              icon: Icons.group_outlined,
              label: 'Travelers',
              value: '${r.travelers}',
              caption: r.travelType.label,
            ),
          ]),
          const SizedBox(height: 16),
          _WeatherSection(
            future: _weather,
            trip: t,
            onRetry: () => setState(_load),
          ),
          const SizedBox(height: 16),
          _RouteSection(future: _route, trip: t, imperial: imperial),
          const SizedBox(height: 16),
          _EmergencySection(trip: t),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = trip.request;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip.destination.name,
            style: theme.textTheme.headlineMedium?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w800),
          ),
          if (trip.destination.label != trip.destination.name)
            Text(trip.destination.label, style: TextStyle(color: scheme.onPrimary)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(icon: Icons.calendar_month, text: fmtRange(r.start, r.end)),
              _HeroChip(icon: Icons.account_balance_wallet_outlined, text: '${r.budget.label} budget'),
              if (trip.international) const _HeroChip(icon: Icons.public, text: 'International'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: scheme.onPrimary, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text(value, style: theme.textTheme.titleSmall),
          ],
        ),
      ],
    );
  }
}

class _WeatherSection extends StatelessWidget {
  const _WeatherSection({required this.future, required this.trip, required this.onRetry});

  final Future<WeatherReport> future;
  final Trip trip;
  final VoidCallback onRetry;

  String _noForecastMessage(WeatherReport r) {
    final today = dateOnly(DateTime.now());
    if (trip.request.end.isBefore(today)) return 'This trip\'s dates have passed.';
    final last = r.days.isEmpty ? today : r.days.last.date;
    return 'Forecasts reach about 16 days ahead (currently up to ${fmtDate(last)}). '
        'Check back closer to ${fmtDate(trip.request.start)}.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final small = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return FutureBuilder<WeatherReport>(
      future: future,
      builder: (context, snap) {
        final r = snap.data;
        Widget body;
        if (snap.hasError) {
          body = ErrorPanel(message: friendlyError(snap.error), onRetry: onRetry);
        } else if (r == null) {
          body = const LoadingPanel(label: 'Checking the weather…');
        } else {
          final tripDays = r.forRange(trip.request.start, trip.request.end);
          final tips = weatherTips(r, tripDays);
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(weatherIcon(r.code), size: 40, color: scheme.primary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${r.temperature.round()}${r.tempUnit}',
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                      Text(weatherLabel(r.code)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 20,
                runSpacing: 10,
                children: [
                  _Metric(icon: Icons.water_drop_outlined, label: 'Humidity', value: '${r.humidity}%'),
                  _Metric(icon: Icons.air, label: 'Wind', value: '${r.windSpeed.round()} ${r.windUnit}'),
                  _Metric(
                    icon: Icons.umbrella,
                    label: 'Rain chance today',
                    value: r.rainChanceToday == null ? 'n/a' : '${r.rainChanceToday}%',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Forecast for your trip', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              if (tripDays.isEmpty)
                Text(_noForecastMessage(r), style: small)
              else
                SizedBox(
                  height: 128,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: tripDays.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final d = tripDays[i];
                      return Container(
                        width: 86,
                        padding: const EdgeInsets.all(10),
                        decoration:
                            BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          children: [
                            Text(fmtWeekday(d.date), style: theme.textTheme.labelMedium),
                            Text(fmtShortDate(d.date), style: theme.textTheme.labelSmall),
                            const SizedBox(height: 4),
                            Icon(weatherIcon(d.code), color: scheme.primary),
                            const SizedBox(height: 4),
                            Text('${d.max.round()}° / ${d.min.round()}°', style: theme.textTheme.labelMedium),
                            if (d.rainChance != null) Text('${d.rainChance}% rain', style: theme.textTheme.labelSmall),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              if (tripDays.isNotEmpty && tripDays.length < trip.days)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Forecast covers ${tripDays.length} of ${trip.days} days so far. '
                    'Later days appear as your trip gets closer.',
                    style: small,
                  ),
                ),
              const SizedBox(height: 16),
              for (final tip in tips)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.tips_and_updates_outlined, size: 18, color: scheme.tertiary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Text(r.isDemo ? 'Demo weather, not a real forecast.' : 'Weather data by Open-Meteo.com', style: small),
            ],
          );
        }
        return SectionCard(
          title: 'Weather',
          icon: Icons.wb_sunny_outlined,
          trailing: r != null && r.isDemo ? const SmallTag('Demo') : null,
          child: body,
        );
      },
    );
  }
}

class _RouteSection extends StatelessWidget {
  const _RouteSection({required this.future, required this.trip, required this.imperial});

  final Future<RouteInfo?> future;
  final Trip trip;
  final bool imperial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    if (trip.origin == null) {
      return const SectionCard(
        title: 'Route & travel',
        icon: Icons.alt_route,
        child: Text('Add a starting location when you plan a trip to see distance, travel time and '
            'transport options.'),
      );
    }
    return SectionCard(
      title: 'Route & travel',
      icon: Icons.alt_route,
      child: FutureBuilder<RouteInfo?>(
        future: future,
        builder: (context, snap) {
          final route = snap.data;
          if (snap.hasError) return ErrorPanel(message: friendlyError(snap.error));
          if (route == null) return const LoadingPanel(label: 'Working out the route…');
          final options = transportOptions(route);
          final drive = route.driveMinutes;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('From ${trip.origin!.label}', style: small),
              const SizedBox(height: 10),
              Wrap(
                spacing: 20,
                runSpacing: 10,
                children: [
                  _Metric(
                    icon: Icons.straighten,
                    label: route.byRoad ? 'Road distance' : 'Straight-line distance',
                    value: fmtDistance(route.distanceKm, imperial),
                  ),
                  if (drive != null) _Metric(icon: Icons.directions_car, label: 'Drive time', value: fmtDuration(drive)),
                ],
              ),
              const SizedBox(height: 8),
              for (final o in options)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(o.icon),
                  title: Text(o.mode),
                  subtitle: Text(o.estimate),
                  trailing: o.recommended ? const SmallTag('Suggested') : null,
                ),
              if (!route.byRoad)
                Text('Road routing wasn\'t available, so times are rough estimates from straight-line distance.',
                    style: small),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  final ok = await navigateTo(from: trip.origin, lat: trip.destination.lat, lon: trip.destination.lon);
                  if (!ok && context.mounted) showSnack(context, 'Couldn\'t open a maps app on this device.');
                },
                icon: const Icon(Icons.navigation_outlined),
                label: const Text('Navigate'),
              ),
              const SizedBox(height: 6),
              Text('Routing by OSRM. Map data © OpenStreetMap contributors.', style: small),
            ],
          );
        },
      ),
    );
  }
}

class _EmergencySection extends StatelessWidget {
  const _EmergencySection({required this.trip});

  final Trip trip;

  IconData _icon(String label) {
    switch (label) {
      case 'Police':
        return Icons.local_police_outlined;
      case 'Ambulance':
        return Icons.medical_services_outlined;
      case 'Fire':
        return Icons.local_fire_department_outlined;
      default:
        return Icons.warning_amber_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final info = EmergencyService.forCountry(trip.destination.countryCode);
    final country = trip.destination.country.isEmpty ? 'this country' : trip.destination.country;
    return SectionCard(
      title: 'Emergency numbers',
      icon: Icons.health_and_safety_outlined,
      trailing: info.known ? null : const SmallTag('Unverified'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!info.known)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'The app has no verified numbers for $country yet. 112 works in many countries, '
                'but confirm it locally.',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          for (final (label, number) in info.entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_icon(label)),
              title: Text(label),
              subtitle: Text(number, style: theme.textTheme.titleMedium),
              trailing: IconButton.filledTonal(
                tooltip: 'Call $number',
                icon: const Icon(Icons.call),
                onPressed: () async {
                  final ok = await callNumber(number);
                  if (!ok && context.mounted) showSnack(context, 'Calling isn\'t supported on this device.');
                },
              ),
            ),
          if (info.extra != null) Text(info.extra!),
          const SizedBox(height: 6),
          Text(EmergencyService.sourceNote, style: small),
        ],
      ),
    );
  }
}
