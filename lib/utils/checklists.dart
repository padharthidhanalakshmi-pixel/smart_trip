import '../models/trip.dart';
import '../models/weather.dart';
import 'ids.dart';
import 'weather_codes.dart';

List<CheckItem> buildPackingList({
  required TripRequest request,
  required List<DayForecast> forecast,
  required bool imperial,
  required bool international,
}) {
  final days = request.days;
  final labels = <String>[
    'Clothes for $days ${days == 1 ? 'day' : 'days'}',
    'Comfortable walking shoes',
    'ID proof',
    'Phone charger',
    'Power bank',
    'Personal medicines',
    'Toiletries',
    'Reusable water bottle',
    'Travel documents',
  ];
  final hot = imperial ? 86.0 : 30.0;
  final cold = imperial ? 54.0 : 12.0;
  if (forecast.isEmpty) {
    labels.add('Umbrella (forecast not available yet, check closer to the trip)');
  } else {
    if (forecast.any((d) => (d.rainChance ?? 0) >= 50 || isRainCode(d.code))) {
      labels.addAll(['Umbrella', 'Light rain jacket']);
    }
    if (forecast.any((d) => d.max >= hot)) labels.addAll(['Sunscreen', 'Sunglasses', 'Cap or hat']);
    if (forecast.any((d) => d.min <= cold)) labels.add('Warm jacket or sweater');
    if (forecast.any((d) => isSnowCode(d.code))) labels.addAll(['Gloves', 'Thermal wear']);
  }
  if (international) labels.addAll(['Passport', 'Travel adapter', 'Some local currency']);

  switch (request.travelType) {
    case TravelType.business:
      labels.addAll(['Formal wear', 'Laptop and charger', 'Business cards']);
    case TravelType.family:
      labels.addAll(['Snacks for the journey', 'Things to keep kids busy']);
    case TravelType.friends:
      labels.add('Card or travel games');
    case TravelType.couple:
      labels.add('An outfit for a nice dinner');
    case TravelType.solo:
      labels.add('Emergency contact card');
  }

  final i = request.interests;
  if (i.contains('Adventure')) labels.addAll(['Basic first-aid kit', 'Quick-dry clothing']);
  if (i.contains('Nature')) labels.add('Insect repellent');
  if (i.contains('Photography')) labels.addAll(['Camera and spare batteries', 'Extra memory cards']);
  if (i.contains('Nightlife')) labels.add('Evening outfit');
  if (i.contains('Shopping')) labels.add('Foldable shopping bag');
  if (days > 5) labels.add('Laundry bag');

  final seen = <String>{};
  return [for (final l in labels) if (seen.add(l)) CheckItem(id: newId(), label: l)];
}

List<CheckItem> buildDocumentList({required bool international, required TravelType travelType}) {
  final labels = international
      ? <String>[
          'Passport',
          'Visa or entry permit (if needed)',
          'Return or onward tickets',
          'Hotel booking confirmation',
          'Travel insurance',
          'Copies of passport and visa',
          'Government ID',
        ]
      : <String>[
          'Government photo ID',
          'Tickets',
          'Hotel booking confirmation',
          'Driving licence (if you plan to drive)',
          'Travel insurance (optional)',
        ];
  labels.add(travelType == TravelType.business ? 'Office ID' : 'College or office ID (if useful)');
  return [for (final l in labels) CheckItem(id: newId(), label: l)];
}

const documentsDisclaimer = 'These are suggestions, not legal requirements. Entry rules depend on your '
    'nationality and route, so confirm with official government, embassy or airline sources.';
