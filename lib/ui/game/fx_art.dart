import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Grid of one sprite sheet (`assets/anim/anims.json`, written by
/// `tool/blender/render_anims.py`).
class FxGrid {
  const FxGrid(this.cols, this.rows, this.fps);
  final int cols;
  final int rows;

  /// Frames per second; 0 for a still atlas.
  final double fps;

  int get frames => cols * rows;
  double get durationMs => fps <= 0 ? 0 : frames * 1000 / fps;

  /// Celebration sheets rendered before the manifest existed.
  static const FxGrid legacy = FxGrid(6, 6, 30);
}

/// A decoded sheet, ready to be drawn frame by frame on a canvas.
class FxSheet {
  FxSheet(this.image, this.grid);
  final ui.Image image;
  final FxGrid grid;

  Rect src(int frame) {
    final w = image.width / grid.cols;
    final h = image.height / grid.rows;
    return Rect.fromLTWH((frame % grid.cols) * w, (frame ~/ grid.cols) * h, w, h);
  }

  /// Frame shown [elapsedMs] after the start, or -1 before / after the run.
  int frameAt(double elapsedMs) {
    if (elapsedMs < 0) return -1;
    final f = (elapsedMs * grid.fps / 1000).floor();
    return f < grid.frames ? f : -1;
  }
}

/// Pre-rendered effect sprite sheets (Blender). The small sheets that play
/// inside the board painter are decoded once at startup; the big one-shot
/// celebrations are decoded on demand by `SpriteAnim`, which only needs the
/// grid from here. Everything is optional: without the files the game falls
/// back to its code-drawn particles and text.
abstract final class FxArt {
  static const String dir = 'assets/anim/';

  // Sheets drawn on the board canvas (kept in memory).
  static const String tilePop = 'tile_pop';
  static const String dropPuff = 'drop_puff';
  static const String hammer = 'hammer';
  static const String joker = 'joker';
  static const String comboBurst = 'combo_burst';
  static const String comboNums = 'combo_nums';
  static const List<String> _eager = [tilePop, dropPuff, hammer, joker, comboBurst, comboNums];

  static Map<String, FxGrid> _grids = {};
  static final Map<String, FxSheet> _sheets = {};

  static String path(String name) => '$dir$name.webp';

  static Future<void> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    try {
      final meta = jsonDecode(await b.loadString('${dir}anims.json')) as Map<String, dynamic>;
      _grids = {
        for (final e in meta.entries)
          e.key: FxGrid(
            (e.value['cols'] as num).toInt(),
            (e.value['rows'] as num).toInt(),
            (e.value['fps'] as num).toDouble(),
          ),
      };
    } catch (_) {
      _grids = {};
    }
    for (final name in _eager) {
      final grid = _grids[name];
      if (grid == null) continue;
      try {
        final data = await b.load(path(name));
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        _sheets[name]?.image.dispose();
        _sheets[name] = FxSheet(frame.image, grid);
      } catch (_) {
        // Optional art.
      }
    }
  }

  /// A board-canvas sheet, or null when it was not delivered.
  static FxSheet? sheet(String name) => _sheets[name];

  /// Grid of a sheet given its asset path (`assets/anim/<name>.webp`).
  static FxGrid gridOf(String assetPath) {
    final file = assetPath.substring(assetPath.lastIndexOf('/') + 1);
    final name = file.endsWith('.webp') ? file.substring(0, file.length - 5) : file;
    return _grids[name] ?? FxGrid.legacy;
  }

  /// Drops decoded sheets (tests).
  static void clear() {
    for (final s in _sheets.values) {
      s.image.dispose();
    }
    _sheets.clear();
    _grids = {};
  }
}
