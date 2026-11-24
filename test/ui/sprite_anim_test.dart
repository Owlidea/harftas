import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:harfblok/config/asset_paths.dart';
import 'package:harfblok/ui/game/fx_art.dart';

/// Canvas size from a WebP extended-format (VP8X) header.
(int, int) _webpSize(List<int> b) {
  expect(String.fromCharCodes(b.sublist(0, 4)), 'RIFF');
  expect(String.fromCharCodes(b.sublist(8, 16)), 'WEBPVP8X', reason: 'expected lossy+alpha WebP from cwebp');
  int u24(int o) => b[o] | (b[o + 1] << 8) | (b[o + 2] << 16);
  return (u24(24) + 1, u24(27) + 1);
}

void main() {
  final meta = jsonDecode(File('${FxArt.dir}anims.json').readAsStringSync()) as Map<String, dynamic>;

  test('every sheet in anims.json exists and matches its grid', () {
    expect(meta, isNotEmpty);
    for (final e in meta.entries) {
      final file = File(FxArt.path(e.key));
      expect(file.existsSync(), isTrue, reason: '${file.path} missing: run tool/blender/build.sh');
      final (w, h) = _webpSize(file.readAsBytesSync());
      final cols = e.value['cols'] as int;
      final rows = e.value['rows'] as int;
      expect(w % cols, 0, reason: e.key);
      expect(h % rows, 0, reason: e.key);
      expect(w ~/ cols, h ~/ rows, reason: '${e.key} frames must be square');
    }
  });

  test('sheets the code refers to are in the manifest', () {
    for (final name in [
      FxArt.tilePop,
      FxArt.dropPuff,
      FxArt.hammer,
      FxArt.joker,
      FxArt.comboBurst,
      FxArt.comboNums,
    ]) {
      expect(meta.containsKey(name), isTrue, reason: name);
    }
    for (final path in [AssetPaths.fxNewRecord, AssetPaths.fxBoardClear, AssetPaths.fxLevelUp, AssetPaths.fxRefresh]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('grid lookup falls back to the legacy 6x6 layout', () {
    FxArt.clear();
    final g = FxArt.gridOf('assets/anim/unknown.webp');
    expect((g.cols, g.rows, g.fps), (6, 6, 30));
    expect(g.durationMs, 1200);
  });
}
