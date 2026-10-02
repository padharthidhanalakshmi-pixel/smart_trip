class RouteInfo {
  const RouteInfo({required this.straightKm, this.roadKm, this.driveMinutes});

  final double straightKm;
  final double? roadKm;
  final int? driveMinutes;

  bool get byRoad => roadKm != null;
  double get distanceKm => roadKm ?? straightKm;
}
