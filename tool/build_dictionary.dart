// Builds the packed game dictionaries from the Zemberek-NLP lexicon.
//
//   dart run tool/build_dictionary.dart
//
// Inputs  (tool/dict/source/, Apache-2.0, see ZEMBEREK_LICENSE.txt):
//   master-dictionary.dict  lemma list with POS tags
//   first-10K               10k most frequent corpus tokens
// Input   tool/dict/blocklist_tr.txt
// Outputs assets/dict/words.bin, assets/dict/common.bin   (DictionaryCodec)
//         tool/dict/out/words.txt, tool/dict/out/common.txt (for review)
//         tool/dict/out/report.md
//
// Re-runnable: same inputs -> byte-identical outputs.
import 'dart:io';

import 'package:harfblok/core/text/turkish_text.dart';
import 'package:harfblok/core/text/word_key.dart';
import 'package:harfblok/data/dictionary/dictionary_codec.dart';

const minLen = 3;
const maxLen = 8;

/// POS tags whose lines never produce a playable word.
const excludedPos = {'Punc', 'Dup', 'Ques', 'Abbrv'};

void main(List<String> args) {
  final root = Directory.current.path;
  final src = '$root/tool/dict/source';
  final out = Directory('$root/tool/dict/out')..createSync(recursive: true);
  Directory('$root/assets/dict').createSync(recursive: true);

  final stats = <String, int>{};
  void count(String reason) => stats[reason] = (stats[reason] ?? 0) + 1;

  final blocked = <String>{
    for (final line in File('$root/tool/dict/blocklist_tr.txt').readAsLinesSync())
      if (line.trim().isNotEmpty && !line.trim().startsWith('#')) TurkishText.normalize(line),
  };

  final words = <String>{};
  for (final rawLine in File('$src/master-dictionary.dict').readAsLinesSync()) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    count('lines');

    final bracket = line.indexOf('[');
    final lemma = (bracket < 0 ? line : line.substring(0, bracket)).trim();
    final attrs = bracket < 0 ? '' : line.substring(bracket);
    final pos = RegExp(r'P:([A-Za-z]+)').firstMatch(attrs)?.group(1);

    if (pos != null && excludedPos.contains(pos)) {
      count('skip: POS $pos');
      continue;
    }
    if (lemma.isEmpty) continue;
    final first = String.fromCharCode(lemma.runes.first);
    if (first != TurkishText.toLower(first)) {
      count('skip: proper noun');
      continue;
    }
    if (RegExp(r"[\s\-'’.0-9]").hasMatch(lemma)) {
      count('skip: multi-word / hyphen / apostrophe / digit');
      continue;
    }
    final w = TurkishText.normalize(lemma);
    if (!TurkishText.isAlphabetic(w)) {
      count('skip: non-Turkish letters');
      continue;
    }
    if (w.length < minLen || w.length > maxLen) {
      count('skip: length');
      continue;
    }
    if (blocked.contains(w)) {
      count('skip: blocklist');
      continue;
    }
    words.add(w);
  }

  final common = <String>{};
  for (final token in File('$src/first-10K').readAsLinesSync()) {
    // Capitalized corpus tokens are mostly proper-noun uses ("Samsun"); the
    // lowercase form must itself be frequent to count as common.
    if (token.isEmpty) continue;
    final first = String.fromCharCode(token.runes.first);
    if (first != TurkishText.toLower(first)) continue;
    final w = TurkishText.normalize(token);
    if (words.contains(w)) common.add(w);
  }

  final sortedWords = words.toList()..sort();
  final sortedCommon = common.toList()..sort();

  File('$root/assets/dict/words.bin')
      .writeAsBytesSync(DictionaryCodec.encode(sortedWords.map((w) => WordKey.fromWord(w)!)));
  File('$root/assets/dict/common.bin')
      .writeAsBytesSync(DictionaryCodec.encode(sortedCommon.map((w) => WordKey.fromWord(w)!)));
  File('${out.path}/words.txt').writeAsStringSync('${sortedWords.join('\n')}\n');
  File('${out.path}/common.txt').writeAsStringSync('${sortedCommon.join('\n')}\n');

  Map<int, int> byLength(Iterable<String> ws) {
    final m = <int, int>{for (var l = minLen; l <= maxLen; l++) l: 0};
    for (final w in ws) {
      m[w.length] = m[w.length]! + 1;
    }
    return m;
  }

  final wl = byLength(words), cl = byLength(common);
  final report = StringBuffer()
    ..writeln('# Sözlük raporu')
    ..writeln()
    ..writeln('Kaynak: Zemberek-NLP `master-dictionary.dict` + `first-10K` (Apache-2.0).')
    ..writeln()
    ..writeln('| Harf | Tüm kelimeler | Yaygın |')
    ..writeln('|---|---|---|');
  for (var l = minLen; l <= maxLen; l++) {
    report.writeln('| $l | ${wl[l]} | ${cl[l]} |');
  }
  report
    ..writeln('| **Toplam** | **${words.length}** | **${common.length}** |')
    ..writeln()
    ..writeln('## Elenenler')
    ..writeln();
  for (final e in (stats.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))) {
    report.writeln('- ${e.key}: ${e.value}');
  }
  File('${out.path}/report.md').writeAsStringSync(report.toString());
  stdout.write(report);
}
