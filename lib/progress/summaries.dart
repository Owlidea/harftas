import '../core/core.dart';

/// What one action produced (fed to missions, wordbook, analytics).
class MoveSummary {
  const MoveSummary({
    required this.words,
    required this.placedCells,
    required this.streakAfter,
    required this.clearedBoard,
    this.powerup,
  });

  factory MoveSummary.fromEvents(GameAction action, List<GameEvent> events) {
    final hits = [for (final e in events.whereType<WordsFound>()) ...e.hits];
    final score = events.whereType<ScoreAwarded>().lastOrNull;
    final placed = events.whereType<PiecePlaced>().fold<int>(0, (n, e) => n + e.cells.length);
    final pu = switch (action) {
      RefreshAction() => PowerupType.refresh,
      JokerAction() => PowerupType.joker,
      HammerAction() => PowerupType.hammer,
      _ => null,
    };
    return MoveSummary(
      words: [for (final h in hits) WordResult(h.word, h.baseScoreX10 ~/ 10)],
      placedCells: placed,
      streakAfter: score?.streakAfter ?? 0,
      clearedBoard: (score?.score.clearBonus ?? 0) > 0,
      powerup: pu,
    );
  }

  final List<WordResult> words;
  final int placedCells;
  final int streakAfter;
  final bool clearedBoard;
  final PowerupType? powerup;

  int get combo => words.length;
}

class WordResult {
  const WordResult(this.word, this.score);
  final String word;
  final int score;
  int get length => word.length;
}

/// Totals of a finished game.
class GameSummary {
  const GameSummary({
    required this.mode,
    required this.score,
    required this.moves,
    required this.duration,
    required this.words,
    required this.usedPowerups,
    required this.bestStreak,
    required this.boardClears,
    required this.continued,
  });

  final GameMode mode;
  final int score;
  final int moves;
  final Duration duration;
  final List<WordResult> words;
  final bool usedPowerups;
  final int bestStreak;
  final int boardClears;
  final bool continued;

  int get wordCount => words.length;
  int get distinctWords => {for (final w in words) w.word}.length;
  int get longestLength => words.fold(0, (m, w) => w.length > m ? w.length : m);
  WordResult? get bestWord => words.isEmpty ? null : words.reduce((a, b) => b.score > a.score ? b : a);
}
