import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:harfblok/config/asset_paths.dart';
import 'package:harfblok/ui/components/sprite_anim.dart';

/// Canvas size from a WebP extended-format (VP8X) header.
(int, int) _webpSize(List<int> b) {
  expect(String.fromCharCodes(b.sublist(0, 4)), 'RIFF');
  expect(String.fromCharCodes(b.sublist(8, 16)), 'WEBPVP8X', reason: 'expected lossy+alpha WebP from cwebp');
  int u24(int o) => b[o] | (b[o + 1] << 8) | (b[o + 2] << 16);
  return (u24(24) + 1, u24(27) + 1);
}

void main() {
  test('celebration sheets match the grid SpriteAnim expects', () {
    for (final path in [AssetPaths.fxNewRecord, AssetPaths.fxBoardClear, AssetPaths.fxLevelUp]) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path missing: run tool/blender/build.sh');
      final (w, h) = _webpSize(file.readAsBytesSync());
      expect(w % SpriteAnim.cols, 0, reason: path);
      expect(h % SpriteAnim.rows, 0, reason: path);
      expect(w ~/ SpriteAnim.cols, h ~/ SpriteAnim.rows, reason: '$path frames must be square');
    }
  });
}
