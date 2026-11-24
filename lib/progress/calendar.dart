/// A calendar day in Europe/Istanbul (spec 7.2: daily resets at Istanbul
/// midnight).
///
/// VARSAYIM: Türkiye has used fixed UTC+3 with no DST since 2016, so the
/// Istanbul date is computed as UTC + 3h without a tz database.
class DayKey implements Comparable<DayKey> {
  const DayKey(this.year, this.month, this.day);

  factory DayKey.istanbul(DateTime instant) {
    final t = instant.toUtc().add(istanbulOffset);
    return DayKey(t.year, t.month, t.day);
  }

  factory DayKey.parse(String s) {
    final p = s.split('-');
    if (p.length != 3) throw FormatException('DayKey: $s');
    return DayKey(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  static const Duration istanbulOffset = Duration(hours: 3);

  final int year;
  final int month;
  final int day;

  DateTime get _utcNoon => DateTime.utc(year, month, day, 12);

  DayKey addDays(int n) {
    final d = _utcNoon.add(Duration(days: n));
    return DayKey(d.year, d.month, d.day);
  }

  int daysUntil(DayKey other) => other._utcNoon.difference(_utcNoon).inDays;

  /// Monday = 1 ... Sunday = 7.
  int get weekday => _utcNoon.weekday;

  /// Whole weeks since Monday 2024-01-01 (weeks run Monday to Sunday).
  int get weekIndex => const DayKey(2024, 1, 1).daysUntil(this) ~/ 7;

  /// Whole days since 2024-01-01 (for daily rotations).
  int get dayIndex => const DayKey(2024, 1, 1).daysUntil(this);

  String get monthKey => '$year-${month.toString().padLeft(2, '0')}';

  /// Next Istanbul midnight as a UTC instant.
  DateTime get nextMidnightUtc => DateTime.utc(year, month, day).add(const Duration(days: 1)).subtract(istanbulOffset);

  static int daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

  @override
  int compareTo(DayKey other) => toString().compareTo(other.toString());

  @override
  bool operator ==(Object other) => other is DayKey && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}
