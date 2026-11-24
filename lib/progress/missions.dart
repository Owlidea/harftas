import '../core/model/game_state.dart';
import '../core/rng/rng.dart';
import 'calendar.dart';
import 'summaries.dart';

enum MissionType {
  /// Build [target] words of at least [length] letters.
  wordsOfLength,

  /// Explode 2+ words in one move, [target] times.
  comboTwo,

  /// Build [target] words containing [letter].
  wordWithLetter,

  /// Score [target] points in one game.
  scoreInGame,

  /// Reach a move streak of [target].
  reachStreak,

  /// Empty the board [target] times.
  clearBoard,

  /// Score [target] in one game without powerups.
  scoreNoPowerups,

  /// Build [target] distinct words in one game.
  distinctWordsInGame,

  /// Score [target] points in total across games (weekly goals).
  scoreTotal,

  /// Finish [target] daily puzzles (weekly goals).
  dailyPuzzles,
}

enum MissionTier { easy, medium, hard }

class Mission {
  const Mission({
    required this.type,
    required this.tier,
    required this.target,
    this.length,
    this.letter,
    this.progress = 0,
  });

  factory Mission.fromJson(Map<String, dynamic> j) => Mission(
    type: MissionType.values.byName(j['type'] as String),
    tier: MissionTier.values.byName(j['tier'] as String),
    target: j['target'] as int,
    length: j['length'] as int?,
    letter: j['letter'] as String?,
    progress: j['progress'] as int? ?? 0,
  );

  final MissionType type;
  final MissionTier tier;
  final int target;
  final int? length;
  final String? letter;
  final int progress;

  bool get done => progress >= target;
  double get fraction => (progress / target).clamp(0, 1).toDouble();

  int get rewardXp => switch (tier) {
    MissionTier.easy => 40,
    MissionTier.medium => 80,
    MissionTier.hard => 150,
  };

  PowerupType get rewardPowerup => switch (tier) {
    MissionTier.easy => PowerupType.refresh,
    MissionTier.medium => PowerupType.joker,
    MissionTier.hard => PowerupType.hammer,
  };

  Mission withProgress(int p) => Mission(
    type: type,
    tier: tier,
    target: target,
    length: length,
    letter: letter,
    progress: p > target ? target : p,
  );

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'tier': tier.name,
    'target': target,
    'length': length,
    'letter': letter,
    'progress': progress,
  };
}

/// Three missions per Istanbul day: one easy, one medium, one hard,
/// deterministic from the date (everyone gets the same ones).
abstract final class MissionPool {
  static const _easyLetters = ['A', 'E', 'K', 'L', 'R', 'N', 'T'];
  static const _hardLetters = ['Ş', 'Ç', 'Ü', 'Ö', 'Y', 'Z', 'B'];

  static List<Mission> forDay(DayKey day) {
    final r = Rng.fromSeed(Rng.mix(0x4D495353, day.year * 10000 + day.month * 100 + day.day));
    Mission pick(List<Mission Function()> options) => options[r.nextInt(options.length)]();
    String letter(List<String> from) => from[r.nextInt(from.length)];

    final easy = pick([
      () => const Mission(type: MissionType.wordsOfLength, tier: MissionTier.easy, target: 10, length: 3),
      () => Mission(type: MissionType.wordWithLetter, tier: MissionTier.easy, target: 3, letter: letter(_easyLetters)),
      () => const Mission(type: MissionType.reachStreak, tier: MissionTier.easy, target: 3),
      () => const Mission(type: MissionType.scoreInGame, tier: MissionTier.easy, target: 250),
      () => const Mission(type: MissionType.comboTwo, tier: MissionTier.easy, target: 1),
    ]);
    final medium = pick([
      () => const Mission(type: MissionType.wordsOfLength, tier: MissionTier.medium, target: 5, length: 4),
      () => const Mission(type: MissionType.scoreInGame, tier: MissionTier.medium, target: 500),
      () => const Mission(type: MissionType.reachStreak, tier: MissionTier.medium, target: 5),
      () => const Mission(type: MissionType.distinctWordsInGame, tier: MissionTier.medium, target: 10),
      () => const Mission(type: MissionType.comboTwo, tier: MissionTier.medium, target: 3),
      () =>
          Mission(type: MissionType.wordWithLetter, tier: MissionTier.medium, target: 2, letter: letter(_hardLetters)),
    ]);
    final hard = pick([
      () => const Mission(type: MissionType.wordsOfLength, tier: MissionTier.hard, target: 2, length: 5),
      () => const Mission(type: MissionType.scoreInGame, tier: MissionTier.hard, target: 900),
      () => const Mission(type: MissionType.clearBoard, tier: MissionTier.hard, target: 1),
      () => const Mission(type: MissionType.scoreNoPowerups, tier: MissionTier.hard, target: 700),
      () => const Mission(type: MissionType.reachStreak, tier: MissionTier.hard, target: 8),
    ]);
    return [easy, medium, hard];
  }

  /// Applies one move. Per-game types are handled in [applyGame].
  static Mission applyMove(Mission m, MoveSummary move) {
    if (m.done) return m;
    switch (m.type) {
      case MissionType.wordsOfLength:
        return m.withProgress(m.progress + move.words.where((w) => w.length >= m.length!).length);
      case MissionType.comboTwo:
        return move.combo >= 2 ? m.withProgress(m.progress + 1) : m;
      case MissionType.wordWithLetter:
        return m.withProgress(m.progress + move.words.where((w) => w.word.contains(m.letter!)).length);
      case MissionType.reachStreak:
        return move.streakAfter > m.progress ? m.withProgress(move.streakAfter) : m;
      case MissionType.clearBoard:
        return move.clearedBoard ? m.withProgress(m.progress + 1) : m;
      case MissionType.scoreInGame:
      case MissionType.scoreNoPowerups:
      case MissionType.distinctWordsInGame:
      case MissionType.scoreTotal:
      case MissionType.dailyPuzzles:
        return m;
    }
  }

  static Mission applyGame(Mission m, GameSummary g) {
    if (m.done) return m;
    int best(int v) => v > m.progress ? v : m.progress;
    return switch (m.type) {
      MissionType.scoreInGame => m.withProgress(best(g.score)),
      MissionType.scoreNoPowerups => g.usedPowerups ? m : m.withProgress(best(g.score)),
      MissionType.distinctWordsInGame => m.withProgress(best(g.distinctWords)),
      MissionType.scoreTotal => m.withProgress(m.progress + g.score),
      MissionType.dailyPuzzles => g.mode == GameMode.daily ? m.withProgress(m.progress + 1) : m,
      _ => m,
    };
  }
}

/// One bigger goal per Istanbul week (Monday to Sunday), the same for
/// everyone, with its own reward. Gives a reason to come back that outlasts
/// the three daily missions.
class WeeklyGoal {
  const WeeklyGoal({required this.week, required this.mission});

  factory WeeklyGoal.fromJson(Map<String, dynamic> j) =>
      WeeklyGoal(week: j['week'] as int, mission: Mission.fromJson(j['mission'] as Map<String, dynamic>));

  /// The goal for the week [day] falls in.
  factory WeeklyGoal.forDay(DayKey day) {
    final w = weekOf(day);
    return WeeklyGoal(week: w, mission: _pool[w % _pool.length](w));
  }

  /// Weeks since Monday 2024-01-01.
  final int week;
  final Mission mission;

  static const int rewardXp = 300;

  /// Granted of every powerup type on completion.
  static const int rewardPowerups = 1;

  static const DayKey _epoch = DayKey(2024, 1, 1);
  // Letters common enough that a handful of games reaches the target.
  static const _letters = ['Ş', 'Ç', 'Ü', 'Y', 'Z'];

  static int weekOf(DayKey day) => _epoch.daysUntil(day) ~/ 7;

  /// Days left including [day]: 7 on Monday, 1 on Sunday.
  static int daysLeft(DayKey day) => 7 - _epoch.daysUntil(day) % 7;

  static final List<Mission Function(int week)> _pool = [
    (_) => const Mission(type: MissionType.scoreTotal, tier: MissionTier.hard, target: 4000),
    (_) => const Mission(type: MissionType.wordsOfLength, tier: MissionTier.hard, target: 40, length: 4),
    (_) => const Mission(type: MissionType.comboTwo, tier: MissionTier.hard, target: 15),
    (_) => const Mission(type: MissionType.dailyPuzzles, tier: MissionTier.hard, target: 5),
    (w) => Mission(
      type: MissionType.wordWithLetter,
      tier: MissionTier.hard,
      target: 10,
      letter: _letters[(w ~/ 7) % _letters.length],
    ),
    (_) => const Mission(type: MissionType.wordsOfLength, tier: MissionTier.hard, target: 8, length: 5),
    (_) => const Mission(type: MissionType.clearBoard, tier: MissionTier.hard, target: 2),
  ];

  Map<String, dynamic> toJson() => {'week': week, 'mission': mission.toJson()};
}
