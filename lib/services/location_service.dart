import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../utils/app_exception.dart';

/// Requests location permission only when the user taps "Use my location".
class LocationService {
  LocationService._();

  static Future<Position> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const AppException('Location (GPS) is turned off. Turn it on, or type your starting city.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const AppException('Location permission was denied. You can type your starting city instead.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const AppException('Location permission is blocked. Allow it in app settings, or type your starting city.');
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 20)),
      );
    } on TimeoutException {
      throw const AppException('Couldn\'t get a GPS fix. Try again near a window, or type your starting city.');
    } catch (_) {
      throw const AppException('Your location isn\'t available right now. Type your starting city instead.');
    }
  }
}
