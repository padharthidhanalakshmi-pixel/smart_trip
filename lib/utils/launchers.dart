import 'package:url_launcher/url_launcher.dart';

import '../models/geo_place.dart';

/// Opens a location in the user's maps app (Android shows an app chooser).
Future<bool> openMap(double lat, double lon, String label) async {
  final geo = Uri.parse('geo:$lat,$lon?q=$lat,$lon(${Uri.encodeComponent(label)})');
  try {
    if (await launchUrl(geo, mode: LaunchMode.externalApplication)) return true;
  } catch (_) {
    // Not supported (e.g. iOS); fall back to a web link below.
  }
  final web = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': '$lat,$lon'});
  try {
    return await launchUrl(web, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Opens turn-by-turn directions in the installed maps app or browser.
Future<bool> navigateTo({GeoPlace? from, required double lat, required double lon}) async {
  final params = <String, String>{
    'api': '1',
    'destination': '$lat,$lon',
    if (from != null) 'origin': '${from.lat},${from.lon}',
  };
  try {
    return await launchUrl(Uri.https('www.google.com', '/maps/dir/', params), mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Opens the phone dialer with the number filled in. It does not place the call.
Future<bool> callNumber(String number) async {
  try {
    return await launchUrl(Uri(scheme: 'tel', path: number));
  } catch (_) {
    return false;
  }
}
