import 'shape.dart';

class PieceCell {
  const PieceCell(this.dx, this.dy, this.letter);
  final int dx;
  final int dy;
  final String letter;
}

/// A shape with one letter per cell (letters in the shape's reading order).
class Piece {
  Piece(this.shape, List<String> letters) : letters = List.unmodifiable(letters) {
    if (letters.length != shape.size) {
      throw ArgumentError('Piece ${shape.id} needs ${shape.size} letters');
    }
  }

  factory Piece.fromJson(Map<String, dynamic> j) =>
      Piece(ShapeCatalog.byId(j['s'] as String), (j['l'] as String).split(''));

  final Shape shape;
  final List<String> letters;

  String get shapeId => shape.id;
  int get size => shape.size;

  List<PieceCell> get cells => [
    for (var i = 0; i < shape.size; i++) PieceCell(shape.cells[i].dx, shape.cells[i].dy, letters[i]),
  ];

  Map<String, dynamic> toJson() => {'s': shape.id, 'l': letters.join()};

  @override
  String toString() => '${shape.id}:${letters.join()}';
}
