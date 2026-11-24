import 'dart:math' as math;
import 'dart:typed_data';

import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';

import '../../config/asset_paths.dart';
import '../theme/app_theme.dart';
import 'app_icon.dart';
import 'sprite_anim.dart';

/// One-shot celebration for a new record (spec 10). Plays the delivered
/// Lottie (`assets/anim/new_record.json`) when present, otherwise a
/// code-drawn confetti burst. Nothing is shown when "reduce motion" is on.
class Celebration extends StatelessWidget {
  const Celebration({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return const SizedBox.shrink();
    if (AssetIndex.has(AssetPaths.animNewRecord)) {
      return IgnorePointer(child: Lottie.asset(AssetPaths.animNewRecord, repeat: false, fit: BoxFit.cover));
    }
    if (SpriteAnim.available(AssetPaths.fxNewRecord)) {
      // Rendered 3D crown burst over the code-drawn confetti rain.
      return const IgnorePointer(
        child: Stack(
          children: [
            Positioned.fill(child: Confetti()),
            Align(alignment: Alignment(0, -0.62), child: SpriteAnim(AssetPaths.fxNewRecord, size: 320)),
          ],
        ),
      );
    }
    return const IgnorePointer(child: Confetti());
  }
}

class Confetti extends StatefulWidget {
  const Confetti({super.key, this.count = 140, this.duration = const Duration(milliseconds: 2600)});
  final int count;
  final Duration duration;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration)..forward();
  late final _Pieces _pieces = _Pieces(widget.count, math.Random(7));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final colors = [p.accent, p.highlight, p.warning, p.success, p.tile, p.joker];
    return RepaintBoundary(
      child: CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_c, _pieces, colors)),
    );
  }
}

/// Pre-generated particle parameters (no allocation while animating).
class _Pieces {
  _Pieces(this.n, math.Random r)
    : x = Float32List(n),
      vx = Float32List(n),
      vy = Float32List(n),
      spin = Float32List(n),
      size = Float32List(n),
      sway = Float32List(n),
      delay = Float32List(n),
      color = Int32List(n),
      shape = Int32List(n) {
    for (var i = 0; i < n; i++) {
      // Two bursts from the upper left and right, plus a light rain.
      final side = i % 3;
      x[i] = side == 0 ? 0.15 : (side == 1 ? 0.85 : r.nextDouble());
      vx[i] = side == 2 ? (r.nextDouble() - 0.5) * 0.1 : (side == 0 ? 1 : -1) * (0.15 + r.nextDouble() * 0.45);
      vy[i] = side == 2 ? 0.05 : -(0.55 + r.nextDouble() * 0.6);
      spin[i] = (r.nextDouble() - 0.5) * 18;
      size[i] = 6 + r.nextDouble() * 7;
      sway[i] = r.nextDouble() * 6.28;
      delay[i] = side == 2 ? 0.15 + r.nextDouble() * 0.35 : r.nextDouble() * 0.08;
      color[i] = r.nextInt(6);
      shape[i] = r.nextInt(3);
    }
  }

  final int n;
  final Float32List x, vx, vy, spin, size, sway, delay;
  final Int32List color, shape;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.anim, this.p, this.colors) : super(repaint: anim);
  final Animation<double> anim;
  final _Pieces p;
  final List<Color> colors;
  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final secs = anim.value * 2.6;
    for (var i = 0; i < p.n; i++) {
      final t = secs - p.delay[i] * 2.6;
      if (t <= 0) continue;
      final burst = p.vy[i] < 0;
      final startY = burst ? size.height * 0.32 : -20.0;
      // Normalised ballistic motion with gravity and a gentle sway.
      final x = size.width * (p.x[i] + p.vx[i] * t * 0.6) + math.sin(p.sway[i] + t * 4) * 10;
      final y = startY + size.height * (p.vy[i] * t + 0.55 * t * t);
      if (y > size.height + 20) continue;
      final fade = anim.value > 0.8 ? (1 - anim.value) / 0.2 : 1.0;
      _paint.color = colors[p.color[i]].withValues(alpha: fade.clamp(0, 1));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin[i] * t);
      final s = p.size[i];
      switch (p.shape[i]) {
        case 0:
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.45), _paint);
        case 1:
          canvas.drawCircle(Offset.zero, s * 0.32, _paint);
        default:
          // Fluttering ribbon: width oscillates to fake 3D flip.
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: s * (0.3 + 0.7 * math.cos(t * 9 + i).abs()), height: s),
            _paint,
          );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
