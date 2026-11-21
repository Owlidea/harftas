import 'grid.dart';

typedef CellOffset = ({int dx, int dy});

enum ShapeFamily { mono, i2, i3, l3, o4, i4, t4, l4, sz4 }

/// An immutable piece shape (fixed orientation; pieces cannot rotate).
class Shape {
  Shape._(this.id, this.family, this.cells)
    : width = cells.map((c) => c.dx).reduce((a, b) => a > b ? a : b) + 1,
      height = cells.map((c) => c.dy).reduce((a, b) => a > b ? a : b) + 1;

  final String id;
  final ShapeFamily family;

  /// Cells in reading order (top-to-bottom, then left-to-right).
  final List<CellOffset> cells;
  final int width;
  final int height;

  int get size => cells.length;

  bool inBounds(int x, int y) => x >= 0 && y >= 0 && x + width <= Grid.size && y + height <= Grid.size;

  /// True if the shape's top-left can go at (x, y) on [grid].
  bool fits(Grid grid, int x, int y) {
    if (!inBounds(x, y)) return false;
    for (final c in cells) {
      if (grid.isFilled(Grid.indexOf(x + c.dx, y + c.dy))) return false;
    }
    return true;
  }

  /// Grid indices covered when placed at (x, y), in reading order.
  List<int> indicesAt(int x, int y) => [for (final c in cells) Grid.indexOf(x + c.dx, y + c.dy)];

  /// Ğ rule (karar 9): a cell may hold Ğ only if this same shape has a cell
  /// directly to its left AND directly above it.
  bool canHoldSoftG(int cellIndex) {
    final c = cells[cellIndex];
    bool has(int dx, int dy) => cells.any((o) => o.dx == dx && o.dy == dy);
    return has(c.dx - 1, c.dy) && has(c.dx, c.dy - 1);
  }

  @override
  String toString() => 'Shape($id)';
}

abstract final class ShapeCatalog {
  static final List<Shape> all = _build();

  static final Map<String, Shape> _byId = {for (final s in all) s.id: s};

  static Shape byId(String id) {
    final s = _byId[id];
    if (s == null) throw ArgumentError('Unknown shape id: $id');
    return s;
  }

  static List<Shape> ofFamily(ShapeFamily f) => all.where((s) => s.family == f).toList(growable: false);

  /// Families grouped by cell count (karar 16: size -> family -> orientation).
  static const Map<int, List<ShapeFamily>> familiesBySize = {
    1: [ShapeFamily.mono],
    2: [ShapeFamily.i2],
    3: [ShapeFamily.i3, ShapeFamily.l3],
    4: [ShapeFamily.o4, ShapeFamily.i4, ShapeFamily.t4, ShapeFamily.l4, ShapeFamily.sz4],
  };

  static final Map<ShapeFamily, List<Shape>> byFamily = {for (final f in ShapeFamily.values) f: ofFamily(f)};

  static List<Shape> _build() {
    final defs = <ShapeFamily, List<List<CellOffset>>>{
      ShapeFamily.mono: [
        [(dx: 0, dy: 0)],
      ],
      ShapeFamily.i2: [
        [(dx: 0, dy: 0), (dx: 1, dy: 0)],
      ],
      ShapeFamily.i3: [
        [(dx: 0, dy: 0), (dx: 1, dy: 0), (dx: 2, dy: 0)],
      ],
      ShapeFamily.l3: [
        [(dx: 0, dy: 0), (dx: 0, dy: 1), (dx: 1, dy: 1)],
      ],
      ShapeFamily.o4: [
        [(dx: 0, dy: 0), (dx: 1, dy: 0), (dx: 0, dy: 1), (dx: 1, dy: 1)],
      ],
      ShapeFamily.i4: [
        [(dx: 0, dy: 0), (dx: 1, dy: 0), (dx: 2, dy: 0), (dx: 3, dy: 0)],
      ],
      ShapeFamily.t4: [
        [(dx: 0, dy: 0), (dx: 1, dy: 0), (dx: 2, dy: 0), (dx: 1, dy: 1)],
      ],
      ShapeFamily.l4: [
        [(dx: 0, dy: 0), (dx: 0, dy: 1), (dx: 0, dy: 2), (dx: 1, dy: 2)],
        [(dx: 1, dy: 0), (dx: 1, dy: 1), (dx: 1, dy: 2), (dx: 0, dy: 2)],
      ],
      ShapeFamily.sz4: [
        [(dx: 1, dy: 0), (dx: 2, dy: 0), (dx: 0, dy: 1), (dx: 1, dy: 1)],
        [(dx: 0, dy: 0), (dx: 1, dy: 0), (dx: 1, dy: 1), (dx: 2, dy: 1)],
      ],
    };

    final result = <Shape>[];
    for (final family in ShapeFamily.values) {
      final seen = <String>{};
      var n = 0;
      for (final base in defs[family]!) {
        var cur = base;
        for (var r = 0; r < 4; r++) {
          final norm = _normalize(cur);
          final key = norm.map((c) => '${c.dx},${c.dy}').join(';');
          if (seen.add(key)) {
            result.add(Shape._('${family.name}_$n', family, norm));
            n++;
          }
          cur = [for (final c in cur) (dx: -c.dy, dy: c.dx)];
        }
      }
    }
    return List.unmodifiable(result);
  }

  static List<CellOffset> _normalize(List<CellOffset> cells) {
    final minX = cells.map((c) => c.dx).reduce((a, b) => a < b ? a : b);
    final minY = cells.map((c) => c.dy).reduce((a, b) => a < b ? a : b);
    final out = [for (final c in cells) (dx: c.dx - minX, dy: c.dy - minY)]
      ..sort((a, b) => a.dy != b.dy ? a.dy - b.dy : a.dx - b.dx);
    return List.unmodifiable(out);
  }
}
