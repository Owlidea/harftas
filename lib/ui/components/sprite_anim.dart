import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../game/fx_art.dart';
import '../theme/app_theme.dart';
import 'app_icon.dart';

/// Plays a pre-rendered sprite sheet once (`assets/anim/*.webp`, produced by
/// `tool/blender/render_anims.py`). The sheet is a grid of square frames whose
/// layout comes from [FxArt.gridOf]; the last frame is empty so nothing is left
/// on screen.
///
/// Shows nothing when the file is missing or "reduce motion" is on.
class SpriteAnim extends StatefulWidget {
  const SpriteAnim(this.asset, {super.key, this.size = 300, this.onDone});

  final String asset;
  final double size;
  final VoidCallback? onDone;

  static bool available(String asset) => AssetIndex.has(asset);

  @override
  State<SpriteAnim> createState() => _SpriteAnimState();
}

class _SpriteAnimState extends State<SpriteAnim> with SingleTickerProviderStateMixin {
  late final FxGrid _grid = FxArt.gridOf(widget.asset);
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _grid.durationMs.round()),
  );
  ui.Image? _sheet;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone?.call();
    });
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await rootBundle.load(widget.asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _sheet = frame.image);
      _c.forward();
    } catch (_) {
      // Optional art: stay invisible, but still report completion.
      if (mounted) widget.onDone?.call();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _sheet?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheet = _sheet;
    if (sheet == null || context.reduceMotion) return SizedBox.square(dimension: widget.size);
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(size: Size.square(widget.size), painter: _SheetPainter(sheet, _grid, _c)),
      ),
    );
  }
}

class _SheetPainter extends CustomPainter {
  _SheetPainter(this.sheet, this.grid, this.anim) : super(repaint: anim);
  final ui.Image sheet;
  final FxGrid grid;
  final Animation<double> anim;
  final Paint _paint = Paint()..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    final f = (anim.value * (grid.frames - 1)).round().clamp(0, grid.frames - 1);
    final cw = sheet.width / grid.cols;
    final ch = sheet.height / grid.rows;
    canvas.drawImageRect(
      sheet,
      Rect.fromLTWH((f % grid.cols) * cw, (f ~/ grid.cols) * ch, cw, ch),
      Offset.zero & size,
      _paint,
    );
  }

  @override
  bool shouldRepaint(_SheetPainter old) => old.sheet != sheet;
}
