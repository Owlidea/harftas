import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// Board surface textures (`assets/images/boards/board_<id>.webp`, greyscale,
/// produced by `tool/blender/render_boards.py`). The texture is multiplied
/// into the theme's board colour, so every theme keeps its own tint. The
/// 'plain' style and missing files fall back to the flat colour.
abstract final class BoardArt {
  static const String dir = 'assets/images/boards/';

  /// Every selectable style; the first is the flat default.
  static const List<String> styles = ['plain', 'felt', 'grain', 'marble'];

  static final Map<String, ui.Image> _images = {};

  static Future<void> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    for (final id in styles.skip(1)) {
      try {
        final data = await b.load('${dir}board_$id.webp');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        _images[id]?.dispose();
        _images[id] = frame.image;
      } catch (_) {
        // Optional art.
      }
    }
  }

  static bool has(String id) => _images.containsKey(id);

  /// Paints the textured surface clipped to [board]. Returns false when the
  /// style has no texture (the caller then fills the flat colour).
  static bool paint(Canvas canvas, RRect board, String styleId, Color color) {
    final img = _images[styleId];
    if (img == null) return false;
    canvas
      ..save()
      ..clipRRect(board)
      ..drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        board.outerRect,
        Paint()
          ..colorFilter = ColorFilter.mode(color, BlendMode.modulate)
          ..filterQuality = FilterQuality.medium,
      )
      ..restore();
    return true;
  }

  static void clear() {
    for (final i in _images.values) {
      i.dispose();
    }
    _images.clear();
  }
}
