// Headless balance simulator (spec 17). Greedy bot: for every move it tries
// every (piece, position) and keeps the highest immediate score; ties go to
// the placement that leaves the most free cells, then the first found.
//
//   dart run tool/simulate.dart [--lang tr|en] [--games 1000] [--min 3] [--seed 1] [--mode classic|daily]
//                               [--bot common] [--tiers ...] [--mult 4:20]
//
// Powerups and "continue" are not used, so results measure the raw rules.
import 'dart:io';

import 'package:harfblok/core/core.dart';
import 'package:harfblok/data/dictionary/dictionary_codec.dart';

/// VARSAYIM: average human time per placement (drag + think).
const secondsPerMove = 4.0;

void main(List<String> args) {
  String? opt(String name) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final games = int.parse(opt('games') ?? '1000');
  final minLen = int.parse(opt('min') ?? '3');
  final seed0 = int.parse(opt('seed') ?? '1');
  final mode = GameMode.values.byName(opt('mode') ?? 'classic');
  final maxMoves = int.parse(opt('max-moves') ?? '600');

  final lang = opt('lang') ?? 'tr';
  final language = WordLanguage.byCode(lang) ?? (throw ArgumentError('unknown language: $lang'));
  final words = SetWordDictionary(DictionaryCodec.decode(File('assets/dict/words_$lang.bin').readAsBytesSync()));
  final common = SetWordDictionary(DictionaryCodec.decode(File('assets/dict/common_$lang.bin').readAsBytesSync()));
  var cfg = BalanceConfig.defaultsFor(language).copyWith(minWordLength: minLen);
  final tiers = opt('tiers'); // e.g. "0:10,30,40,20;300:8,27,40,25"
  if (tiers != null) {
    cfg = cfg.copyWith(
      sizeTiers: [
        for (final t in tiers.split(';'))
          SizeTier(
            minScore: int.parse(t.split(':')[0]),
            weights: [for (final w in t.split(':')[1].split(',')) int.parse(w)],
          ),
      ],
    );
  }
  final mult = opt('mult'); // e.g. "4:20" (x10 scale): overrides word-length multipliers
  if (mult != null) {
    cfg = cfg.copyWith(
      lengthMultiplierX10: {
        ...cfg.lengthMultiplierX10,
        for (final m in mult.split(',')) int.parse(m.split(':')[0]): int.parse(m.split(':')[1]),
      },
    );
  }
  final engine = GameEngine(config: cfg, dictionary: words, common: common);
  final none = {for (final t in PowerupType.values) t: 0};
  // --bot common: the bot only "knows" common words (human proxy); the
  // real engine still explodes every dictionary word.
  final bot = (opt('bot') ?? 'full') == 'common' ? GameEngine(config: cfg, dictionary: common, common: common) : engine;

  var totalMoves = 0, totalScore = 0, wordlessMoves = 0, totalWords = 0, capped = 0;
  final lengths = <int, int>{};
  final reasons = <String, int>{};
  final moveCounts = <int>[];
  final scores = <int>[];
  final sw = Stopwatch()..start();

  for (var g = 0; g < games; g++) {
    var s = engine.newGame(seed: Rng.mix(seed0, g), mode: mode, startedAt: DateTime.utc(2026), powerups: none);
    var moves = 0;
    while (!s.isOver && moves < maxMoves) {
      PlaceAction? best;
      var bestScore = -1, bestFree = -1;
      for (var p = 0; p < s.hand.length; p++) {
        final piece = s.hand[p];
        if (piece == null) continue;
        for (final pos in Placement.positions(s.grid, piece.shape)) {
          final pv = bot.preview(s, p, pos.x, pos.y)!;
          final cleared = {for (final h in pv.hits) ...h.cells}.length;
          final free = 64 - s.grid.filledCount - piece.size + cleared;
          if (pv.score.total > bestScore || (pv.score.total == bestScore && free > bestFree)) {
            bestScore = pv.score.total;
            bestFree = free;
            best = PlaceAction(p, pos.x, pos.y);
          }
        }
      }
      final r = engine.apply(s, best!);
      final found = r.events.whereType<WordsFound>().expand((e) => e.hits).toList();
      if (found.isEmpty) wordlessMoves++;
      for (final h in found) {
        lengths[h.length] = (lengths[h.length] ?? 0) + 1;
      }
      totalWords += found.length;
      s = r.state;
      moves++;
    }
    if (!s.isOver) capped++;
    reasons[s.overReason?.name ?? 'move cap'] = (reasons[s.overReason?.name ?? 'move cap'] ?? 0) + 1;
    totalMoves += moves;
    totalScore += s.score;
    moveCounts.add(moves);
    scores.add(s.score);
  }
  sw.stop();

  moveCounts.sort();
  scores.sort();
  int pct(List<int> l, double q) => l[((l.length - 1) * q).round()];
  final avgMoves = totalMoves / games;
  final b = StringBuffer()
    ..writeln(
      '## MIN_WORD_LEN = $minLen${lang == 'tr' ? '' : ' · $lang'} · ${mode.name} · bot=${opt('bot') ?? 'full'}${tiers == null ? '' : ' · tiers=$tiers'}${mult == null ? '' : ' · mult=$mult'} · $games oyun',
    )
    ..writeln()
    ..writeln('| Ölçüt | Değer |')
    ..writeln('|---|---|')
    ..writeln(
      '| Ortalama hamle | ${avgMoves.toStringAsFixed(1)} (medyan ${pct(moveCounts, .5)}, %10 ${pct(moveCounts, .1)}, %90 ${pct(moveCounts, .9)}) |',
    )
    ..writeln(
      '| Tahmini süre (${secondsPerMove.toStringAsFixed(0)} sn/hamle) | ${(avgMoves * secondsPerMove / 60).toStringAsFixed(1)} dk |',
    )
    ..writeln('| Ortalama skor | ${(totalScore / games).toStringAsFixed(0)} (medyan ${pct(scores, .5)}) |')
    ..writeln('| Hamle başına kelime | ${(totalWords / totalMoves).toStringAsFixed(2)} |')
    ..writeln('| Kelimesiz hamle oranı | %${(100 * wordlessMoves / totalMoves).toStringAsFixed(1)} |')
    ..writeln('| Kelime uzunluğu dağılımı | ${[for (var l = 3; l <= 8; l++) '$l:${lengths[l] ?? 0}'].join(' · ')} |')
    ..writeln('| Oyun sonu nedenleri | ${reasons.entries.map((e) => '${e.key}: ${e.value}').join(', ')} |')
    ..writeln('| Hamle sınırına takılan | $capped |')
    ..writeln('| Simülasyon süresi | ${(sw.elapsedMilliseconds / 1000).toStringAsFixed(1)} sn |');
  stdout.write(b);
}
