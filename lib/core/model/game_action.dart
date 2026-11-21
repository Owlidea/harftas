import 'game_state.dart';

/// Every player input that changes the game. A game is fully reproducible
/// from (seed, mode, initial powerups) + the ordered action list.
sealed class GameAction {
  const GameAction();

  factory GameAction.fromJson(Map<String, dynamic> j) {
    switch (j['t']) {
      case 'place':
        return PlaceAction(j['p'] as int, j['x'] as int, j['y'] as int);
      case 'refresh':
        return const RefreshAction();
      case 'joker':
        return JokerAction(j['x'] as int, j['y'] as int, j['l'] as String);
      case 'hammer':
        return HammerAction(j['x'] as int, j['y'] as int);
      case 'continue':
        return const ContinueAction();
      case 'end':
        return const EndAction();
    }
    throw FormatException('Unknown action: ${j['t']}');
  }

  Map<String, dynamic> toJson();
}

/// Spec "Move {pieceIndex, x, y}". (x, y) is the shape's top-left.
class PlaceAction extends GameAction {
  const PlaceAction(this.pieceIndex, this.x, this.y);
  final int pieceIndex;
  final int x;
  final int y;
  @override
  Map<String, dynamic> toJson() => {'t': 'place', 'p': pieceIndex, 'x': x, 'y': y};
}

class RefreshAction extends GameAction {
  const RefreshAction();
  PowerupType get type => PowerupType.refresh;
  @override
  Map<String, dynamic> toJson() => {'t': 'refresh'};
}

class JokerAction extends GameAction {
  const JokerAction(this.x, this.y, this.letter);
  final int x;
  final int y;
  final String letter;
  @override
  Map<String, dynamic> toJson() => {'t': 'joker', 'x': x, 'y': y, 'l': letter};
}

class HammerAction extends GameAction {
  const HammerAction(this.x, this.y);
  final int x;
  final int y;
  @override
  Map<String, dynamic> toJson() => {'t': 'hammer', 'x': x, 'y': y};
}

/// Rewarded "Devam Et": clears the 2 fullest rows (classic, once per game).
class ContinueAction extends GameAction {
  const ContinueAction();
  @override
  Map<String, dynamic> toJson() => {'t': 'continue'};
}

/// Player declines the "Güçlendirici kullan?" offer while stuck.
class EndAction extends GameAction {
  const EndAction();
  @override
  Map<String, dynamic> toJson() => {'t': 'end'};
}
