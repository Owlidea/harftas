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
      _ => m,
    };
  }
}
