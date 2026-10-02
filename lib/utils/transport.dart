import 'package:flutter/material.dart';

import '../models/route_info.dart';
import 'format.dart';

class TransportOption {
  const TransportOption(this.mode, this.icon, this.estimate, {this.recommended = false});

  final String mode;
  final IconData icon;
  final String estimate;
  final bool recommended;
}

/// Suggested ways to travel. Only car time from OSRM is measured; the rest
/// are labelled rough estimates from typical average speeds.
List<TransportOption> transportOptions(RouteInfo r) {
  final d = r.distanceKm;
  String hours(double h) => fmtDuration((h * 60).round());
  final opts = <TransportOption>[];
  if (d <= 5) {
    opts.add(TransportOption('Walking', Icons.directions_walk, 'About ${hours(d / 4.5)}', recommended: d <= 2));
  }
  if (d <= 1500) {
    final drive = r.driveMinutes;
    final estimate =
        drive != null ? '${fmtDuration(drive)} by road' : 'About ${hours(d * 1.3 / 55)} (rough estimate)';
    opts.add(TransportOption('Car or taxi', Icons.directions_car, estimate, recommended: d > 2 && d <= 300));
  }
  if (d > 15 && d <= 900) {
    opts.add(TransportOption('Bus', Icons.directions_bus, 'About ${hours(d * 1.3 / 45)} (rough estimate)'));
  }
  if (d > 50 && d <= 2000) {
    opts.add(TransportOption('Train', Icons.train, 'About ${hours(d * 1.3 / 60)} (rough estimate)',
        recommended: d > 300 && d <= 700));
  }
  if (d >= 300) {
    opts.add(TransportOption('Flight', Icons.flight,
        'About ${hours(d / 750 + 2.5)} including airport time (rough estimate)', recommended: d > 700));
  }
  return opts;
}
