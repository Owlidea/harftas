import '../model/grid.dart';
import '../model/piece.dart';
import '../model/shape.dart';

/// Placement / game-over checks.
abstract final class Placement {
  static bool canPlaceShape(Grid grid, Shape shape) {
    for (var y = 0; y <= Grid.size - shape.height; y++) {
      for (var x = 0; x <= Grid.size - shape.width; x++) {
        if (shape.fits(grid, x, y)) return true;
      }
    }
    return false;
  }

  /// Spec 2.6: false means none of the remaining pieces fits anywhere.
  static bool canPlaceAny(Grid grid, List<Piece?> hand) {
    for (final p in hand) {
      if (p != null && canPlaceShape(grid, p.shape)) return true;
    }
    return false;
  }

  /// All top-left positions where [shape] fits (for UI hints / bots).
  static List<({int x, int y})> positions(Grid grid, Shape shape) => [
    for (var y = 0; y <= Grid.size - shape.height; y++)
      for (var x = 0; x <= Grid.size - shape.width; x++)
        if (shape.fits(grid, x, y)) (x: x, y: y),
  ];
}
