import 'calendar.dart';

/// Daily-puzzle streak (spec 8). One "seri koruma" per calendar month covers
/// a single missed day automatically.
class DailyStreak {
  const DailyStreak({this.current = 0, this.best = 0, this.lastPlayed, this.shieldMonthUsed});

  factory DailyStreak.fromJson(Map<String, dynamic> j) => DailyStreak(
    current: j['current'] as int? ?? 0,
    best: j['best'] as int? ?? 0,
    lastPlayed: j['last'] == null ? null : DayKey.parse(j['last'] as String),
    shieldMonthUsed: j['shieldMonth'] as String?,
  );

  static const List<int> milestones = [7, 30, 100];

  final int current;
  final int best;
  final DayKey? lastPlayed;

  /// Month key ("2026-11") in which the shield was used, if any.
  final String? shieldMonthUsed;

  bool shieldAvailable(DayKey today) => shieldMonthUsed != today.monthKey;

  /// Streak value as shown today (0 if it is already broken).
  int displayed(DayKey today) {
    final last = lastPlayed;
    if (last == null) return 0;
    final gap = last.daysUntil(today);
    if (gap <= 1) return current;
    if (gap == 2 && shieldAvailable(today)) return current;
    return 0;
  }

  /// True when today's puzzle is the last chance to keep the streak.
  bool atRisk(DayKey today) {
    final last = lastPlayed;
    return last != null && current > 0 && last != today && displayed(today) > 0;
  }

  /// Records a completed daily puzzle on [day]. Returns the new streak and
  /// whether the shield was consumed.
  ({DailyStreak streak, bool shieldUsed, List<int> reached}) complete(DayKey day) {
    final last = lastPlayed;
    var shieldUsed = false;
    int next;
    if (last == null) {
      next = 1;
    } else {
      final gap = last.daysUntil(day);
      if (gap <= 0) {
        return (streak: this, shieldUsed: false, reached: const []);
      } else if (gap == 1) {
        next = current + 1;
      } else if (gap == 2 && shieldAvailable(day)) {
        next = current + 1;
        shieldUsed = true;
      } else {
        next = 1;
      }
    }
    final reached = [
      for (final m in milestones)
        if (current < m && next >= m) m,
    ];
    return (
      streak: DailyStreak(
        current: next,
        best: next > best ? next : best,
        lastPlayed: day,
        shieldMonthUsed: shieldUsed ? day.monthKey : shieldMonthUsed,
      ),
      shieldUsed: shieldUsed,
      reached: reached,
    );
  }

  Map<String, dynamic> toJson() => {
    'current': current,
    'best': best,
    'last': lastPlayed?.toString(),
    'shieldMonth': shieldMonthUsed,
  };
}
