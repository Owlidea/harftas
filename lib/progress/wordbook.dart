import 'calendar.dart';

class WordbookEntry {
  const WordbookEntry({required this.count, required this.first, required this.bestScore});

  factory WordbookEntry.fromJson(Map<String, dynamic> j) =>
      WordbookEntry(count: j['c'] as int, first: DayKey.parse(j['f'] as String), bestScore: j['s'] as int);

  final int count;
  final DayKey first;
  final int bestScore;

  Map<String, dynamic> toJson() => {'c': count, 'f': first.toString(), 's': bestScore};
}

/// Kelime Defteri (spec 8): every unique word ever built.
class Wordbook {
  Wordbook([Map<String, WordbookEntry>? entries]) : entries = entries ?? {};

  factory Wordbook.fromJson(Map<String, dynamic> j) => Wordbook({
    for (final e in (j['words'] as Map<String, dynamic>).entries)
      e.key: WordbookEntry.fromJson(e.value as Map<String, dynamic>),
  });

  final Map<String, WordbookEntry> entries;

  int get uniqueCount => entries.length;
  int get totalBuilt => entries.values.fold(0, (n, e) => n + e.count);

  /// Returns true if [word] is new.
  bool add(String word, int score, DayKey day) {
    final e = entries[word];
    entries[word] = WordbookEntry(
      count: (e?.count ?? 0) + 1,
      first: e?.first ?? day,
      bestScore: e == null || score > e.bestScore ? score : e.bestScore,
    );
    return e == null;
  }

  String? get longest {
    String? best;
    for (final w in entries.keys) {
      if (best == null || w.length > best.length || (w.length == best.length && w.compareTo(best) < 0)) {
        best = w;
      }
    }
    return best;
  }

  String? get highestScoring {
    String? best;
    var s = -1;
    for (final e in entries.entries) {
      if (e.value.bestScore > s) {
        s = e.value.bestScore;
        best = e.key;
      }
    }
    return best;
  }

  String? get mostBuilt {
    String? best;
    var c = 0;
    for (final e in entries.entries) {
      if (e.value.count > c) {
        c = e.value.count;
        best = e.key;
      }
    }
    return best;
  }

  /// Words grouped by length (3..8), alphabetical (Turkish order).
  Map<int, List<String>> byLength(int Function(String, String) compare) {
    final m = <int, List<String>>{};
    for (final w in entries.keys) {
      (m[w.length] ??= []).add(w);
    }
    for (final l in m.values) {
      l.sort(compare);
    }
    return m;
  }

  Map<String, dynamic> toJson() => {
    'v': 1,
    'words': {for (final e in entries.entries) e.key: e.value.toJson()},
  };
}
