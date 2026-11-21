import '../model/game_state.dart';
import '../model/piece.dart';
import '../rules/scoring.dart';
import '../rules/word_detector.dart';

/// What happened during one action, in order. The UI animates these; the
/// engine itself never waits for animations.
sealed class GameEvent {
  const GameEvent();
}

class PiecePlaced extends GameEvent {
  const PiecePlaced(this.pieceIndex, this.cells);
  final int pieceIndex;
  final List<int> cells;
}

class JokerPlaced extends GameEvent {
  const JokerPlaced(this.cell, this.letter);
  final int cell;
  final String letter;
}

class WordsFound extends GameEvent {
  const WordsFound(this.hits);
  final List<WordHit> hits;
}

class CellsCleared extends GameEvent {
  const CellsCleared(this.cells);
  final List<int> cells;
}

class ScoreAwarded extends GameEvent {
  const ScoreAwarded(this.score, this.streakAfter, this.totalAfter);
  final MoveScore score;
  final int streakAfter;
  final int totalAfter;
}

class HandDealt extends GameEvent {
  const HandDealt(this.hand, this.handNumber);
  final List<Piece> hand;
  final int handNumber;
}

class PowerupUsed extends GameEvent {
  const PowerupUsed(this.type, this.remaining);
  final PowerupType type;
  final int remaining;
}

class ContinueApplied extends GameEvent {
  const ContinueApplied(this.rows);
  final List<int> rows;
}

class StatusChanged extends GameEvent {
  const StatusChanged(this.status, this.reason);
  final GameStatus status;
  final GameOverReason? reason;
}
