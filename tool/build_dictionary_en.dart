// Builds the English game dictionaries (karar 29).
//
//   dart run tool/build_dictionary_en.dart [--size 60] [--common-classes 12]
//
// Inputs  (tool/dict/en/source/, see README.md there):
//   scowl-2020.12.07/{english,american,british}-words.{10..60}   valid words (SCOWL)
//   12dicts-6.0.2/2+2+3frq.txt                                    lemmas by frequency class
// Input   tool/dict/en/blocklist_en.txt
// Outputs assets/dict/words_en.bin, assets/dict/common_en.bin   (DictionaryCodec)
//         tool/dict/en/out/{words,common,blocked}.txt and report.md (for review)
//
// Valid words: SCOWL up to --size, American and British spellings, 3-8 letters a-z (names,
// abbreviations and contractions are in SCOWL files this does not read). Common words: lemmas of
// frequency classes 1..--common-classes, the irregular forms listed under them and their regular
// inflections (-s, -es, -ies, -ed, -ing, doubled consonant, -er, -est) that are valid words.
//
// Re-runnable: same inputs -> byte-identical outputs.
import 'dart:convert';
import 'dart:io';

import 'package:harfblok/core/core.dart';
import 'package:harfblok/data/dictionary/dictionary_codec.dart';

const minLen = 3;
const maxLen = 8;
const scowlLevels = [10, 20, 35, 40, 50, 55, 60, 70, 80, 95];
final _letters = RegExp(r'^[a-z]+$');
final _classHeader = RegExp(r'^-+\s*(\d+)\s*-+$');
final _markers = RegExp(r'[!$%&+^#=<]');

void main(List<String> args) {
  String? opt(String name) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final size = int.parse(opt('size') ?? '60');
  final commonClasses = int.parse(opt('common-classes') ?? '12');
  final root = Directory.current.path;
  final src = '$root/tool/dict/en/source';
  final out = Directory('$root/tool/dict/en/out')..createSync(recursive: true);

  final stats = <String, int>{};
  void count(String reason) => stats[reason] = (stats[reason] ?? 0) + 1;
  List<String> lines(String path) => const LineSplitter().convert(latin1.decode(File(path).readAsBytesSync()));

  // ------------------------------------------------------------ blocklist
  final entries = [
    for (final l in lines('$root/tool/dict/en/blocklist_en.txt'))
      if (l.trim().isNotEmpty && !l.trim().startsWith('#')) l.trim().toLowerCase(),
  ];
  final blockBase = {for (final e in entries) if (!e.startsWith('!')) e};
  final neverBlocked = {for (final e in entries) if (e.startsWith('!')) e.substring(1)};
  bool isBlocked(String w) {
    if (neverBlocked.contains(w)) return false;
    if (blockBase.contains(w)) return true;
    String? base(String suffix) => w.endsWith(suffix) ? w.substring(0, w.length - suffix.length) : null;
    for (final suffix in const ['s', 'ed', 'ing']) {
      if (blockBase.contains(base(suffix))) return true;
    }
    final es = base('es'); // plural -es only after a sibilant (not crap -> crapes)
    return es != null && RegExp(r'(s|x|z|ch|sh)$').hasMatch(es) && blockBase.contains(es);
  }

  // --------------------------------------------------------- valid words
  final words = <String>{};
  final blocked = <String>{};
  for (final kind in const ['english', 'american', 'british']) {
    for (final level in scowlLevels.where((l) => l <= size)) {
      final file = File('$src/scowl-2020.12.07/$kind-words.$level');
      if (!file.existsSync()) continue;
      for (final raw in lines(file.path)) {
        final t = raw.trim();
        if (t.isEmpty) continue;
        if (t != t.toLowerCase()) {
          count('skip: capitalised');
          continue;
        }
        final w = LatinText.fold(t);
        if (!_letters.hasMatch(w)) {
          count('skip: apostrophe / hyphen / digit');
          continue;
        }
        if (w.length < minLen || w.length > maxLen) {
          count('skip: length');
          continue;
        }
        if (isBlocked(w)) {
          blocked.add(w);
          continue;
        }
        words.add(w);
      }
    }
  }

  // -------------------------------------------------------- common words
  Iterable<String> regularForms(String l) sync* {
    yield* ['${l}s', '${l}es', '${l}d', '${l}ed', '${l}ing', '${l}r', '${l}er', '${l}st', '${l}est'];
    final last = l[l.length - 1];
    if (last == 'e') yield '${l.substring(0, l.length - 1)}ing';
    if (last == 'y' && l.length > 1 && !'aeiou'.contains(l[l.length - 2])) {
      final stem = l.substring(0, l.length - 1);
      yield* ['${stem}ies', '${stem}ied', '${stem}ier', '${stem}iest'];
    }
    if (!'aeiouwxy'.contains(last)) yield* ['$l${last}ed', '$l${last}ing', '$l${last}er', '$l${last}est'];
  }

  String? clean(String raw) {
    final t = raw.trim().replaceAll(_markers, '');
    return _letters.hasMatch(t) ? t : null; // multi-word, hyphenated or capitalised entries drop out
  }

  final common = <String>{};
  var lemmas = 0;
  void addCommon(String? w) {
    if (w != null && words.contains(w)) common.add(w);
  }

  var cls = 0;
  for (final raw in lines('$src/12dicts-6.0.2/2+2+3frq.txt')) {
    final header = _classHeader.firstMatch(raw.trim());
    if (header != null) {
      cls = int.parse(header.group(1)!);
      continue;
    }
    if (cls == 0 || cls > commonClasses || raw.trim().isEmpty) continue;
    if (raw.startsWith(' ') || raw.startsWith('\t')) {
      raw.split(',').map(clean).forEach(addCommon); // irregular forms of the lemma above
      continue;
    }
    final lemma = clean(raw);
    if (lemma == null) continue;
    lemmas++;
    addCommon(lemma);
    regularForms(lemma).forEach(addCommon);
  }

  // -------------------------------------------------------------- output
  final sortedWords = words.toList()..sort();
  final sortedCommon = common.toList()..sort();
  final sortedBlocked = blocked.toList()..sort();
  int key(String w) => WordKey.fromWord(w, WordLanguage.english)!;
  File('$root/assets/dict/words_en.bin').writeAsBytesSync(DictionaryCodec.encode(sortedWords.map(key)));
  File('$root/assets/dict/common_en.bin').writeAsBytesSync(DictionaryCodec.encode(sortedCommon.map(key)));
  String upper(List<String> ws) => '${ws.map((w) => w.toUpperCase()).join('\n')}\n';
  File('${out.path}/words.txt').writeAsStringSync(upper(sortedWords));
  File('${out.path}/common.txt').writeAsStringSync(upper(sortedCommon));
  File('${out.path}/blocked.txt').writeAsStringSync(upper(sortedBlocked));

  Map<int, int> byLength(Iterable<String> ws) {
    final m = <int, int>{for (var l = minLen; l <= maxLen; l++) l: 0};
    for (final w in ws) {
      m[w.length] = m[w.length]! + 1;
    }
    return m;
  }

  final wl = byLength(words), cl = byLength(common);
  final report = StringBuffer()
    ..writeln('# English dictionary report')
    ..writeln()
    ..writeln('Sources: SCOWL 2020.12.07 sizes <= $size (English + American + British spellings); '
        'common words from 12dicts 6.0.2 `2+2+3frq` classes 1-$commonClasses ($lemmas lemmas) with their forms.')
    ..writeln()
    ..writeln('| Letters | All words | Common |')
    ..writeln('|---|---|---|');
  for (var l = minLen; l <= maxLen; l++) {
    report.writeln('| $l | ${wl[l]} | ${cl[l]} |');
  }
  report
    ..writeln('| **Total** | **${words.length}** | **${common.length}** |')
    ..writeln()
    ..writeln('## Left out')
    ..writeln()
    ..writeln('- blocklist (see blocked.txt): ${blocked.length}');
  for (final e in (stats.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))) {
    report.writeln('- ${e.key}: ${e.value}');
  }
  File('${out.path}/report.md').writeAsStringSync(report.toString());
  stdout.write(report);
}
