import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Pre-rendered 3D tile bodies (`assets/images/tiles/`, produced by
/// `tool/blender/render_tiles.py`).
///
/// Each style ships one greyscale atlas of four layers
/// (shadow | edge | face | gloss). The layers are tinted with the palette and
/// flattened once into a sprite per colour set, so a frame costs one image
/// draw per tile and every theme reuses the same art. Letters and scores are
/// still drawn by [TileRenderer]. When the files are missing (or in unit
/// tests) [sprite] returns null and tiles fall back to the code-drawn look.
abstract final class TileArt {
  static const String dir = 'assets/images/tiles/';

  static final Map<String, _Atlas> _atlases = {};
  static final Map<int, TileSprite> _sprites = {};

  static bool get loaded => _atlases.isNotEmpty;

  static Future<void> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    try {
      final meta = jsonDecode(await b.loadString('${dir}tiles.json')) as Map<String, dynamic>;
      final cell = (meta['cell'] as num).toDouble();
      final styles = meta['styles'] as Map<String, dynamic>;
      final loadedNow = <String, _Atlas>{};
      for (final e in styles.entries) {
        final data = await b.load('${dir}tile_${e.key}.png');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        final m = e.value as Map<String, dynamic>;
        final box = (m['box'] as List).map((v) => (v as num).toDouble() * cell).toList();
        loadedNow[e.key] = _Atlas(
          image: frame.image,
          cell: cell,
          box: Rect.fromLTRB(box[0], box[1], box[2], box[3]),
          depth: (m['depth'] as num).toDouble(),
        );
      }
      clear();
      _atlases.addAll(loadedNow);
    } catch (_) {
      // Optional art: the code-drawn tiles remain.
    }
  }

  /// Drops all art (tests, hot reload of assets).
  static void clear() {
    for (final s in _sprites.values) {
      s.image.dispose();
    }
    _sprites.clear();
    for (final a in _atlases.values) {
      a.image.dispose();
    }
    _atlases.clear();
  }

  /// Tinted tile body for [styleId], or null when no art is loaded.
  static TileSprite? sprite(String styleId, {required Color tile, required Color edge, required Color shadow}) {
    final atlas = _atlases[styleId];
    if (atlas == null) return null;
    final key = Object.hash(styleId, tile.toARGB32(), edge.toARGB32(), shadow.toARGB32());
    final hit = _sprites[key];
    if (hit != null) return hit;
    if (_sprites.length >= 48) {
      // Palettes in use at once are few; a full cache means a theme change.
      for (final s in _sprites.values) {
        s.image.dispose();
      }
      _sprites.clear();
    }
    return _sprites[key] = atlas.compose(tile: tile, edge: edge, shadow: shadow);
  }
}

/// One flattened, tinted tile body.
class TileSprite {
  TileSprite(this.image, this._cell, this._box, this.depth);

  final ui.Image image;
  final double _cell;

  /// The tile silhouette inside the sprite (the rest is shadow padding).
  final Rect _box;

  /// Visible side height as a fraction of the tile height.
  final double depth;

  static final Paint _paint = Paint()..filterQuality = FilterQuality.medium;

  /// Paints the body so that its silhouette fills [r] (shadow spills outside).
  void paint(Canvas canvas, Rect r) {
    final sx = r.width / _box.width;
    final sy = r.height / _box.height;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, _cell, _cell),
      Rect.fromLTWH(r.left - _box.left * sx, r.top - _box.top * sy, _cell * sx, _cell * sy),
      _paint,
    );
  }
}

class _Atlas {
  _Atlas({required this.image, required this.cell, required this.box, required this.depth});

  final ui.Image image;
  final double cell;
  final Rect box;
  final double depth;

  TileSprite compose({required Color tile, required Color edge, required Color shadow}) {
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    final dst = Rect.fromLTWH(0, 0, cell, cell);
    Rect src(int i) => Rect.fromLTWH(cell * i, 0, cell, cell);
    // Palette shadows are tuned for small code-drawn offsets; the rendered
    // contact shadow is softer and needs more weight to read.
    final strength = (shadow.a * 2).clamp(0.28, 0.6);
    canvas
      ..drawImageRect(
        image,
        src(0),
        dst,
        Paint()
          ..color = Color.fromRGBO(0, 0, 0, strength)
          ..colorFilter = ColorFilter.mode(shadow.withValues(alpha: 1), BlendMode.srcIn),
      )
      ..drawImageRect(image, src(1), dst, Paint()..colorFilter = ColorFilter.mode(edge, BlendMode.modulate))
      ..drawImageRect(image, src(2), dst, Paint()..colorFilter = ColorFilter.mode(tile, BlendMode.modulate))
      ..drawImageRect(image, src(3), dst, Paint());
    final picture = rec.endRecording();
    final out = picture.toImageSync(cell.round(), cell.round());
    picture.dispose();
    return TileSprite(out, cell, box, depth);
  }
}
