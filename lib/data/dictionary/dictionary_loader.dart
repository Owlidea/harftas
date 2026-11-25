import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../config/asset_paths.dart';
import '../../core/core.dart';
import 'dictionary_codec.dart';

class LoadedData {
  const LoadedData(this.words, this.common, this.config);
  final WordDictionary words;
  final WordDictionary common;
  final BalanceConfig config;

  WordLanguage get language => config.language;
}

/// Loads the packed dictionaries off the UI isolate (spec 3: must not delay
/// startup by more than 300 ms — decoding runs in a background isolate while
/// the home screen is already visible).
abstract final class DataLoader {
  /// Dictionaries and balance config of one word language.
  static Future<LoadedData> load(AssetBundle bundle, [WordLanguage language = WordLanguage.turkish]) async {
    final words = await bundle.load(AssetPaths.dictionary(language.code));
    final common = await bundle.load(AssetPaths.commonWords(language.code));
    final sets = await compute(_decode, [
      words.buffer.asUint8List(words.offsetInBytes, words.lengthInBytes),
      common.buffer.asUint8List(common.offsetInBytes, common.lengthInBytes),
    ]);
    BalanceConfig config;
    try {
      config = BalanceConfig.fromJson(
        jsonDecode(await bundle.loadString(AssetPaths.balanceConfig(language.code))) as Map<String, dynamic>,
      );
    } on Object {
      config = BalanceConfig.defaultsFor(language);
    }
    if (config.language != language) config = BalanceConfig.defaultsFor(language);
    return LoadedData(SetWordDictionary(sets[0]), SetWordDictionary(sets[1]), config);
  }

  static List<Set<int>> _decode(List<Uint8List> blobs) => [for (final b in blobs) DictionaryCodec.decode(b)];
}
