import 'package:harfblok/core/core.dart';

/// Builds a grid from 8 rows. Uppercase = existing cell, lowercase = cell
/// placed this move (Turkish-aware: 'i' -> İ, 'ı' -> I), '.' = empty.
({Grid grid, List<int> newCells}) board(List<String> rows) {
  final padded = [...rows, for (var i = rows.length; i < 8; i++) '........'];
  final g = Grid.empty();
  final cells = <int>[];
  for (var y = 0; y < 8; y++) {
    final chars = padded[y].split('');
    assert(chars.length == 8, 'row $y must have 8 chars: ${padded[y]}');
    for (var x = 0; x < 8; x++) {
      final ch = chars[x];
      if (ch == '.') continue;
      final upper = TurkishText.toUpper(ch);
      final idx = Grid.indexOf(x, y);
      g.set(idx, Cell(upper));
      if (ch != upper) cells.add(idx);
    }
  }
  return (grid: g, newCells: cells);
}

/// Small fixed dictionary for deterministic tests.
final testDictionary = SetWordDictionary.fromWords(const [
  'KAR', 'KARE', 'KALEM', 'ELMA', 'ARA', 'ARABA', 'KARALAMA',
  'ALE', 'LEM', 'LEA', // synthetic tie-break fixtures
  'KAL', 'KAN', 'KAT', 'KAZ', 'KAS', 'KAY', 'KEL', 'KİN', 'KİR', 'KIR', 'KUM',
  'KUL', 'KUR', 'KÖR', 'KÜL', 'ADA', 'ANA', 'ATA', 'AYI', 'ARI', 'ALT', 'ANT',
  'İNEK', 'İNCE', 'İLK', 'İRİ', 'EKİN', 'EKMEK', 'ERİK', 'EMİN', 'ETEK',
  'KALE', 'NAR', 'TAŞ', 'DAĞ', 'SU', 'EL', 'DERE', 'TEPE', 'MASA', 'LALE',
  'NANE', 'RENK', 'YER', 'YOL', 'SES', 'SIR', 'DAR', 'DİL', 'DİN', 'TEN',
]);
