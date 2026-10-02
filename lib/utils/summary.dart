import '../models/trip.dart';
import '../services/currency_service.dart';
import '../services/emergency_service.dart';
import 'format.dart';

String buildTripSummary(Trip t, {required String currency}) {
  final r = t.request;
  final sym = currencySymbol(currency);
  final b = StringBuffer();
  b.writeln('TRIP PLAN: ${t.destination.label}');
  b.writeln('Dates: ${fmtRange(r.start, r.end)} (${t.days} ${t.days == 1 ? 'day' : 'days'})');
  if (t.origin != null) b.writeln('From: ${t.origin!.label}');
  b.writeln('Travelers: ${r.travelers} (${r.travelType.label})');
  b.writeln('Budget level: ${r.budget.label}');
  if (r.interests.isNotEmpty) b.writeln('Interests: ${r.interests.join(', ')}');
  if (t.weatherSummary != null) b.writeln('Weather: ${t.weatherSummary}');
  if (t.budgetTotal > 0) {
    final planned = t.budget.values.fold<double>(0, (s, v) => s + v);
    b.writeln('Budget: $sym${fmtNumber(t.budgetTotal, decimals: 0)} total, '
        '$sym${fmtNumber(planned, decimals: 0)} planned');
  }

  b
    ..writeln()
    ..writeln('ITINERARY');
  for (var d = 1; d <= t.days; d++) {
    final date = t.dateForDay(d);
    b.writeln('Day $d, ${fmtWeekday(date)} ${fmtShortDate(date)}');
    for (final item in t.itinerary.where((x) => x.day == d)) {
      b.writeln('  ${fmtMinutes(item.minutes)}  ${item.title}${item.done ? ' (done)' : ''}');
    }
  }

  b
    ..writeln()
    ..writeln('PACKING');
  for (final item in t.packing) {
    b.writeln('${item.checked ? '[x]' : '[ ]'} ${item.label}');
  }
  b
    ..writeln()
    ..writeln('DOCUMENTS');
  for (final item in t.documents) {
    b.writeln('${item.checked ? '[x]' : '[ ]'} ${item.label}');
  }

  final saved = t.places.where((p) => t.favorites.contains(p.id)).toList();
  if (saved.isNotEmpty) {
    b
      ..writeln()
      ..writeln('SAVED PLACES');
    for (final p in saved) {
      b.writeln('- ${p.name} (${p.category})');
    }
  }

  final e = EmergencyService.forCountry(t.destination.countryCode);
  b
    ..writeln()
    ..writeln('EMERGENCY NUMBERS (confirm locally)');
  for (final line in e.lines) {
    b.writeln(line);
  }

  if (t.notes.trim().isNotEmpty) {
    b
      ..writeln()
      ..writeln('NOTES')
      ..writeln(t.notes.trim());
  }
  if (t.placesDemo) {
    b
      ..writeln()
      ..writeln('Note: places in this plan are demo placeholders, not real venues.');
  }
  b
    ..writeln()
    ..write('Planned with Smart Trip Assistant');
  return b.toString();
}
