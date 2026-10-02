const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool sameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Whole days from [a] to [b], immune to daylight-saving shifts.
int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

String two(int n) => n.toString().padLeft(2, '0');

String fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String fmtShortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

String fmtWeekday(DateTime d) => _weekdays[d.weekday - 1];

String fmtRange(DateTime a, DateTime b) =>
    a.year == b.year ? '${fmtShortDate(a)} – ${fmtDate(b)}' : '${fmtDate(a)} – ${fmtDate(b)}';

String fmtMinutes(int m) => '${two(m ~/ 60)}:${two(m % 60)}';

String fmtClock(DateTime t) => '${two(t.hour)}:${two(t.minute)}';

String isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';

String fmtDuration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h >= 24) {
    final d = h ~/ 24;
    final rh = h % 24;
    return rh == 0 ? '$d d' : '$d d $rh h';
  }
  return m == 0 ? '$h h' : '$h h $m min';
}

String fmtOffset(Duration d) {
  final total = d.inMinutes;
  final sign = total < 0 ? '-' : '+';
  final a = total.abs();
  final h = a ~/ 60;
  final m = a % 60;
  return m == 0 ? 'UTC$sign$h' : 'UTC$sign$h:${two(m)}';
}

/// 1234567.891 -> "1,234,567.89"
String fmtNumber(double v, {int decimals = 2}) {
  final fixed = v.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  final dec = parts.length > 1 && decimals > 0 ? '.${parts[1]}' : '';
  return '${v < 0 ? '-' : ''}$buf$dec';
}

String fmtDistance(double km, bool imperial) {
  if (imperial) {
    final mi = km * 0.621371;
    return mi < 10 ? '${mi.toStringAsFixed(1)} mi' : '${fmtNumber(mi, decimals: 0)} mi';
  }
  if (km < 1) return '${(km * 1000).round()} m';
  return km < 10 ? '${km.toStringAsFixed(1)} km' : '${fmtNumber(km, decimals: 0)} km';
}
