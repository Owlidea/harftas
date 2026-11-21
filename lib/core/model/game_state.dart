import 'game_action.dart';
import 'grid.dart';
import 'piece.dart';

enum GameMode { classic, daily }

enum PowerupType { refresh, joker, hammer }

enum GameStatus {
  /// At least one piece fits.
  playing,

  /// Nothing fits but powerups are available (classic): UI offers them.
  stuck,

  over,
}

enum GameOverReason { noFit, handLimit }

/// Immutable snapshot. The engine returns a new state for each action.
class GameState {
  const GameState({
    required this.mode,
    required this.seed,
    required this.grid,
    required this.hand,
    required this.score,
    required this.streak,
    required this.bestStreak,
    required this.powerups,
    required this.initialPowerups,
    required this.handCounter,
    required this.actions,
    required this.startedAt,
    required this.status,
    required this.overReason,
    required this.continueUsed,
    required this.wordCount,
    required this.longestWord,
    required this.bestWord,
    required this.bestWordScore,
  });

  static const int schemaVersion = 1;

  final GameMode mode;
  final int seed;

  /// Treat as read-only; the engine copies before mutating.
  final Grid grid;

  /// Slots of the current hand; null = already placed.
  final List<Piece?> hand;
  final int score;
  final int streak;
  final int bestStreak;
  final Map<PowerupType, int> powerups;
  final Map<PowerupType, int> initialPowerups;

  /// Number of hands dealt so far — the RNG state (each hand uses
  /// `Rng.stream(seed, index)`).
  final int handCounter;
  final List<GameAction> actions;
  final DateTime startedAt;
  final GameStatus status;
  final GameOverReason? overReason;
  final bool continueUsed;

  final int wordCount;
  final String longestWord;
  final String bestWord;
  final int bestWordScore;

  bool get isOver => status == GameStatus.over;
  int get remainingPieces => hand.where((p) => p != null).length;
  int powerup(PowerupType t) => powerups[t] ?? 0;
  bool get hasAnyPowerup => powerups.values.any((v) => v > 0);

  GameState copyWith({
    Grid? grid,
    List<Piece?>? hand,
    int? score,
    int? streak,
    int? bestStreak,
    Map<PowerupType, int>? powerups,
    int? handCounter,
    List<GameAction>? actions,
    GameStatus? status,
    GameOverReason? overReason,
    bool clearOverReason = false,
    bool? continueUsed,
    int? wordCount,
    String? longestWord,
    String? bestWord,
    int? bestWordScore,
  }) => GameState(
    mode: mode,
    seed: seed,
    grid: grid ?? this.grid,
    hand: hand ?? this.hand,
    score: score ?? this.score,
    streak: streak ?? this.streak,
    bestStreak: bestStreak ?? this.bestStreak,
    powerups: powerups ?? this.powerups,
    initialPowerups: initialPowerups,
    handCounter: handCounter ?? this.handCounter,
    actions: actions ?? this.actions,
    startedAt: startedAt,
    status: status ?? this.status,
    overReason: clearOverReason ? null : (overReason ?? this.overReason),
    continueUsed: continueUsed ?? this.continueUsed,
    wordCount: wordCount ?? this.wordCount,
    longestWord: longestWord ?? this.longestWord,
    bestWord: bestWord ?? this.bestWord,
    bestWordScore: bestWordScore ?? this.bestWordScore,
  );

  Map<String, dynamic> toJson() => {
    'v': schemaVersion,
    'mode': mode.name,
    'seed': seed,
    'grid': grid.toJson(),
    'hand': [for (final p in hand) p?.toJson()],
    'score': score,
    'streak': streak,
    'bestStreak': bestStreak,
    'powerups': {for (final e in powerups.entries) e.key.name: e.value},
    'initialPowerups': {for (final e in initialPowerups.entries) e.key.name: e.value},
    'handCounter': handCounter,
    'actions': [for (final a in actions) a.toJson()],
    'startedAt': startedAt.toUtc().toIso8601String(),
    'status': status.name,
    'overReason': overReason?.name,
    'continueUsed': continueUsed,
    'wordCount': wordCount,
    'longestWord': longestWord,
    'bestWord': bestWord,
    'bestWordScore': bestWordScore,
  };

  /// Throws [FormatException] on unknown versions or malformed data; the
  /// storage layer catches it and resets safely (spec 14).
  factory GameState.fromJson(Map<String, dynamic> j) {
    final v = j['v'];
    if (v != schemaVersion) throw FormatException('Unsupported game state version: $v');
    Map<PowerupType, int> pw(Object? o) => {
      for (final e in (o as Map).entries) PowerupType.values.byName(e.key as String): (e.value as num).toInt(),
    };
    final hand = [for (final p in j['hand'] as List) p == null ? null : Piece.fromJson(p as Map<String, dynamic>)];
    return GameState(
      mode: GameMode.values.byName(j['mode'] as String),
      seed: j['seed'] as int,
      grid: Grid.fromJson(j['grid'] as List),
      hand: List.unmodifiable(hand),
      score: j['score'] as int,
      streak: j['streak'] as int,
      bestStreak: j['bestStreak'] as int,
      powerups: Map.unmodifiable(pw(j['powerups'])),
      initialPowerups: Map.unmodifiable(pw(j['initialPowerups'])),
      handCounter: j['handCounter'] as int,
      actions: List.unmodifiable([
        for (final a in j['actions'] as List) GameAction.fromJson(a as Map<String, dynamic>),
      ]),
      startedAt: DateTime.parse(j['startedAt'] as String),
      status: GameStatus.values.byName(j['status'] as String),
      overReason: j['overReason'] == null ? null : GameOverReason.values.byName(j['overReason'] as String),
      continueUsed: j['continueUsed'] as bool,
      wordCount: j['wordCount'] as int,
      longestWord: j['longestWord'] as String,
      bestWord: j['bestWord'] as String,
      bestWordScore: j['bestWordScore'] as int,
    );
  }
}
