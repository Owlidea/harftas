// Writes the built-in balance config of a word language to its asset file.
//
//   dart run tool/export_balance.dart [--lang tr|en]   -> assets/config/balance_<lang>.json
import 'dart:convert';
import 'dart:io';

import 'package:harfblok/core/core.dart';

void main(List<String> args) {
  final i = args.indexOf('--lang');
  final code = i >= 0 && i + 1 < args.length ? args[i + 1] : 'tr';
  final language = WordLanguage.byCode(code) ?? (throw ArgumentError('unknown language: $code'));
  File('assets/config/balance_${language.code}.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(BalanceConfig.defaultsFor(language).toJson()));
}
