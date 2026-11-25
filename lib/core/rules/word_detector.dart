import 'dart:typed_data';

import '../config/balance_config.dart';
import '../dictionary.dart';
import '../model/grid.dart';
import '../text/letters.dart';
import '../text/word_key.dart';

enum WordDirection { horizontal, vertical }

/// A word found after a placement.
class WordHit {
  WordHit({
    required this.word,
    required this.cells,
    required this.direction,
    required this.letterSum,
    required this.baseScoreX10,
  });

  final String word;

  /// Grid indices in reading order.
  final List<int> cells;
  final WordDirection direction;

  /// Sum of letter points (jokers count 0).
  final int letterSum;

  /// letterSum x length multiplier, in x10 scale (before combo / streak).
  final int baseScoreX10;

  int get length => cells.length;

  /// Word score before combo and streak (may be fractional, e.g. x1.5).
  double get baseScore => baseScoreX10 / 10;

  @override
  String toString() => 'WordHit($word ${direction.name} @${cells.first})';
}

/// Spec 2.5 detection. See docs/algoritma.md §1.
class WordDetector {
  WordDetector(this.config, this.dictionary)
    : _scores = List<int>.generate(Letters.count + 1, (code) => code == 0 ? 0 : config.scoreOf(_letterOf(code)));

  final BalanceConfig config;
  final WordDictionary dictionary;
  final List<int> _scores;

  // Reusable buffers: one line is at most 8 cells.
  final List<int> _segIdx = List<int>.filled(Grid.size, 0);
  final Uint8List _isNew = Uint8List(Grid.cellCount);
  final Uint8List _rows = Uint8List(Grid.size);
  final Uint8List _cols = Uint8List(Grid.size);
  final List<_Candidate> _cands = [];

  static String _letterOf(int code) => Letters.letterOf(code);

  int letterScore(Cell c) => c.isJoker ? 0 : _scores[c.code];

  /// [newCells]: grid indices filled by this move.
  List<WordHit> detect(Grid grid, List<int> newCells) {
    final hits = <WordHit>[];
    if (newCells.isEmpty) return hits;
    _isNew.fillRange(0, Grid.cellCount, 0);
    _rows.fillRange(0, Grid.size, 0);
    _cols.fillRange(0, Grid.size, 0);
    for (final i in newCells) {
      _isNew[i] = 1;
      _rows[Grid.yOf(i)] = 1;
      _cols[Grid.xOf(i)] = 1;
    }
    for (var y = 0; y < Grid.size; y++) {
      if (_rows[y] == 1) _scanLine(grid, WordDirection.horizontal, y, hits);
    }
    for (var x = 0; x < Grid.size; x++) {
      if (_cols[x] == 1) _scanLine(grid, WordDirection.vertical, x, hits);
    }
    return hits;
  }

  void _scanLine(Grid grid, WordDirection dir, int line, List<WordHit> hits) {
    int idx(int k) => dir == WordDirection.horizontal ? Grid.indexOf(k, line) : Grid.indexOf(line, k);
    var k = 0;
    while (k < Grid.size) {
      if (!grid.isFilled(idx(k))) {
        k++;
        continue;
      }
      var len = 0;
      while (k < Grid.size && grid.isFilled(idx(k))) {
        _segIdx[len++] = idx(k);
        k++;
      }
      _scanSegment(grid, dir, len, hits);
    }
  }

  void _scanSegment(Grid grid, WordDirection dir, int len, List<WordHit> hits) {
    final minLen = config.minWordLength;
    if (len < minLen) return;
    var anyNew = false;
    for (var i = 0; i < len; i++) {
      if (_isNew[_segIdx[i]] == 1) {
        anyNew = true;
        break;
      }
    }
    if (!anyNew) return;

    _cands.clear();
    final maxLen = config.maxWordLength < WordKey.maxLength ? config.maxWordLength : WordKey.maxLength;
    for (var s = 0; s <= len - minLen; s++) {
      var key = 0;
      var sum = 0;
      var hasNew = false;
      for (var e = s; e < len && e - s < maxLen; e++) {
        final gi = _segIdx[e];
        final cell = grid[gi]!;
        key = WordKey.append(key, e - s, cell.code);
        sum += letterScore(cell);
        if (_isNew[gi] == 1) hasNew = true;
        final l = e - s + 1;
        if (l >= minLen && hasNew && dictionary.containsKey(key)) {
          _cands.add(_Candidate(s, l, sum, key));
        }
      }
    }
    if (_cands.isEmpty) return;

    // Longest first; then higher letter sum; then leftmost / topmost.
    _cands.sort((a, b) {
      if (a.length != b.length) return b.length - a.length;
      if (a.letterSum != b.letterSum) return b.letterSum - a.letterSum;
      return a.start - b.start;
    });

    var taken = 0;
    for (final c in _cands) {
      final m = ((1 << c.length) - 1) << c.start;
      if (taken & m != 0) continue;
      taken |= m;
      final cells = List<int>.generate(c.length, (i) => _segIdx[c.start + i]);
      hits.add(
        WordHit(
          word: WordKey.decode(c.key),
          cells: cells,
          direction: dir,
          letterSum: c.letterSum,
          baseScoreX10: c.letterSum * (config.lengthMultiplierX10[c.length] ?? 10),
        ),
      );
    }
  }
}

class _Candidate {
  _Candidate(this.start, this.length, this.letterSum, this.key);
  final int start;
  final int length;
  final int letterSum;
  final int key;
}
