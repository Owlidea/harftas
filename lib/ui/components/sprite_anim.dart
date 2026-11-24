import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'app_icon.dart';

/// Plays a pre-rendered sprite sheet once (`assets/anim/*.webp`, produced by
/// `tool/blender/render_anims.py`). The sheet is a [cols] x [rows] grid of
/// square frames; first and last frame are empty so nothing pops in or out.
///
/// Shows nothing when the file is missing or "reduce motion" is on.
class SpriteAnim extends StatefulWidget {
  const SpriteAnim(this.asset, {super.key, this.size = 300, this.onDone});

  final String asset;
  final double size;
  final VoidCallback? onDone;

  // Mirrors tool/blender/render_anims.py.
  static const int cols = 6;
  static const int rows = 6;
  static const int fps = 30;
  static const int frames = cols * rows;

  static bool available(String asset) => AssetIndex.has(asset);

  @override
  State<SpriteAnim> createState() => _SpriteAnimState();
}

class _SpriteAnimState extends State<SpriteAnim> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: SpriteAnim.frames * 1000 ~/ SpriteAnim.fps),
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
        child: CustomPaint(size: Size.square(widget.size), painter: _SheetPainter(sheet, _c)),
      ),
    );
  }
}

class _SheetPainter extends CustomPainter {
  _SheetPainter(this.sheet, this.anim) : super(repaint: anim);
  final ui.Image sheet;
  final Animation<double> anim;
  final Paint _paint = Paint()..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    final f = (anim.value * (SpriteAnim.frames - 1)).round().clamp(0, SpriteAnim.frames - 1);
    final cw = sheet.width / SpriteAnim.cols;
    final ch = sheet.height / SpriteAnim.rows;
    canvas.drawImageRect(
      sheet,
      Rect.fromLTWH((f % SpriteAnim.cols) * cw, (f ~/ SpriteAnim.cols) * ch, cw, ch),
      Offset.zero & size,
      _paint,
    );
  }

  @override
  bool shouldRepaint(_SheetPainter old) => old.sheet != sheet;
}
