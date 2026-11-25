import '../text/letters.dart';

/// One letter tile on the board.
class Cell {
  Cell(this.letter, {this.isJoker = false}) : code = Letters.codeOf(letter) {
    if (code == 0) throw ArgumentError('Not a board letter: $letter');
  }

  /// Serialized as the letter, prefixed with '*' for jokers.
  factory Cell.fromJson(String s) => s.startsWith('*') ? Cell(s.substring(1), isJoker: true) : Cell(s);

  final String letter;
  final bool isJoker;

  /// [Letters] code (cached for allocation-free word keys).
  final int code;

  String toJson() => isJoker ? '*$letter' : letter;

  @override
  bool operator ==(Object other) => other is Cell && other.letter == letter && other.isJoker == isJoker;

  @override
  int get hashCode => Object.hash(letter, isJoker);

  @override
  String toString() => toJson();
}

/// 8x8 board. Index = y * 8 + x.
///
/// No 64-bit masks: the game also runs on the web, where bitwise ops are
/// 32-bit. Occupancy is simply "cell != null"; pieces have at most 4 cells,
/// so per-cell checks are as fast as masks in practice.
class Grid {
  Grid.empty() : _cells = List<Cell?>.filled(cellCount, null), _count = 0;

  Grid._(this._cells, this._count);

  factory Grid.fromJson(List<dynamic> j) {
    if (j.length != cellCount) throw const FormatException('grid size');
    final g = Grid.empty();
    for (var i = 0; i < cellCount; i++) {
      final v = j[i];
      if (v != null) g.set(i, Cell.fromJson(v as String));
    }
    return g;
  }

  /// Test helper: 8 strings, '.' = empty.
  factory Grid.fromRows(List<String> rows) {
    assert(rows.length == size);
    final g = Grid.empty();
    for (var y = 0; y < size; y++) {
      final letters = rows[y].split('');
      assert(letters.length == size, 'row $y must have 8 chars');
      for (var x = 0; x < size; x++) {
        if (letters[x] != '.') g.set(indexOf(x, y), Cell(letters[x]));
      }
    }
    return g;
  }

  static const int size = 8;
  static const int cellCount = size * size;

  static int indexOf(int x, int y) => y * size + x;
  static int xOf(int index) => index % size;
  static int yOf(int index) => index ~/ size;

  final List<Cell?> _cells;
  int _count;

  bool get isEmpty => _count == 0;
  int get filledCount => _count;

  Cell? at(int x, int y) => _cells[indexOf(x, y)];
  Cell? operator [](int index) => _cells[index];
  bool isFilled(int index) => _cells[index] != null;

  void set(int index, Cell? cell) {
    final had = _cells[index] != null;
    _cells[index] = cell;
    if (had && cell == null) _count--;
    if (!had && cell != null) _count++;
  }

  Grid copy() => Grid._(List<Cell?>.of(_cells), _count);

  int rowCount(int y) {
    var n = 0;
    for (var x = 0; x < size; x++) {
      if (isFilled(indexOf(x, y))) n++;
    }
    return n;
  }

  List<String?> toJson() => [for (final c in _cells) c?.toJson()];

  /// Debug rendering with '.' for empty cells.
  List<String> toRows() => [
    for (var y = 0; y < size; y++) [for (var x = 0; x < size; x++) at(x, y)?.letter ?? '.'].join(),
  ];
}
