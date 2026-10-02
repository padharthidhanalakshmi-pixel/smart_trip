import 'package:flutter/material.dart';

/// WMO weather codes used by Open-Meteo.
String weatherLabel(int c) {
  if (c == 0) return 'Clear sky';
  if (c == 1) return 'Mainly clear';
  if (c == 2) return 'Partly cloudy';
  if (c == 3) return 'Overcast';
  if (c == 45 || c == 48) return 'Fog';
  if (c >= 51 && c <= 57) return 'Drizzle';
  if (c >= 61 && c <= 67) return 'Rain';
  if (c >= 71 && c <= 77) return 'Snow';
  if (c >= 80 && c <= 82) return 'Rain showers';
  if (c == 85 || c == 86) return 'Snow showers';
  if (c >= 95) return 'Thunderstorm';
  return 'Mixed conditions';
}

IconData weatherIcon(int c) {
  if (c <= 1) return Icons.wb_sunny_outlined;
  if (c == 2) return Icons.cloud_queue;
  if (c == 3 || c == 45 || c == 48) return Icons.cloud_outlined;
  if (isSnowCode(c)) return Icons.ac_unit;
  if (c >= 95) return Icons.flash_on;
  if (isRainCode(c)) return Icons.water_drop_outlined;
  return Icons.cloud_outlined;
}

bool isRainCode(int c) => (c >= 51 && c <= 67) || (c >= 80 && c <= 82) || c >= 95;

bool isSnowCode(int c) => (c >= 71 && c <= 77) || c == 85 || c == 86;
