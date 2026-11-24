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
      case 'grant':
        return GrantAction({
          for (final e in (j['pw'] as Map).entries) PowerupType.values.byName(e.key as String): e.value as int,
        });
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

/// Powerups added to a running classic game from outside play: mission,
/// level and weekly rewards, purchases, gifts. While a classic game is in
/// progress it owns the powerup counts, so every grant is recorded here;
/// otherwise the next save would overwrite the inventory with the game's
/// stale counts, and a replay could not explain the extra uses.
class GrantAction extends GameAction {
  const GrantAction(this.powerups);
  final Map<PowerupType, int> powerups;
  @override
  Map<String, dynamic> toJson() => {
    't': 'grant',
    'pw': {for (final e in powerups.entries) e.key.name: e.value},
  };
}
