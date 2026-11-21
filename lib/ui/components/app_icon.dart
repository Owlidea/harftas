import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../config/asset_paths.dart';

/// Which bundled asset files exist (loaded once at startup). Lets widgets
/// prefer a delivered file and fall back to a code-drawn placeholder.
abstract final class AssetIndex {
  static Set<String> _files = {};
  static Future<void> load() async {
    final m = await AssetManifest.loadFromAssetBundle(rootBundle);
    _files = m.listAssets().toSet();
  }

  static bool has(String path) => _files.contains(path);

  /// For tests.
  static set files(Set<String> f) => _files = f;
}

/// Single-colour icon: the delivered SVG (tinted) or a placeholder line icon.
class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, this.size = 24, this.color, this.semanticLabel});

  final AppIconName name;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? DefaultTextStyle.of(context).style.color!;
    final path = AssetPaths.icon(name);
    final Widget icon = AssetIndex.has(path)
        ? SvgPicture.asset(path, width: size, height: size, colorFilter: ColorFilter.mode(c, BlendMode.srcIn))
        : CustomPaint(size: Size.square(size), painter: _GlyphPainter(name, c));
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel == null,
      child: SizedBox.square(dimension: size, child: icon),
    );
  }
}

/// Placeholder line icons on a 24-unit grid, 2-unit stroke (spec 13).
class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.name, this.color);
  final AppIconName name;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    void line(double x1, double y1, double x2, double y2) => canvas.drawLine(Offset(x1, y1), Offset(x2, y2), p);
    RRect rr(double l, double t, double r, double b, double rad) => RRect.fromLTRBR(l, t, r, b, Radius.circular(rad));

    switch (name) {
      case AppIconName.pause:
        line(9, 6, 9, 18);
        line(15, 6, 15, 18);
      case AppIconName.settings:
        canvas.drawCircle(const Offset(12, 12), 3, p);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          line(12 + 6 * math.cos(a), 12 + 6 * math.sin(a), 12 + 8.5 * math.cos(a), 12 + 8.5 * math.sin(a));
        }
        canvas.drawCircle(const Offset(12, 12), 6, p);
      case AppIconName.book:
        canvas.drawRRect(rr(5, 4, 19, 20, 2), p);
        line(9, 4, 9, 20);
        line(12, 9, 16, 9);
      case AppIconName.missions:
        canvas.drawRRect(rr(5, 4, 19, 20, 2), p);
        canvas.drawPath(
          Path()
            ..moveTo(8, 12)
            ..lineTo(10.5, 14.5)
            ..lineTo(16, 9),
          p,
        );
      case AppIconName.calendar:
        canvas.drawRRect(rr(4, 6, 20, 20, 2), p);
        line(4, 10, 20, 10);
        line(8, 4, 8, 7);
        line(16, 4, 16, 7);
      case AppIconName.stats:
        line(6, 19, 6, 12);
        line(12, 19, 12, 6);
        line(18, 19, 18, 10);
      case AppIconName.share:
        line(12, 4, 12, 15);
        canvas.drawPath(
          Path()
            ..moveTo(8, 8)
            ..lineTo(12, 4)
            ..lineTo(16, 8),
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(6, 12)
            ..lineTo(6, 20)
            ..lineTo(18, 20)
            ..lineTo(18, 12),
          p,
        );
      case AppIconName.sound:
        canvas.drawPath(
          Path()
            ..moveTo(4, 10)
            ..lineTo(8, 10)
            ..lineTo(12, 6)
            ..lineTo(12, 18)
            ..lineTo(8, 14)
            ..lineTo(4, 14)
            ..close(),
          p,
        );
        canvas.drawArc(const Rect.fromLTRB(11, 8, 19, 16), -math.pi / 3, 2 * math.pi / 3, false, p);
      case AppIconName.music:
        canvas.drawCircle(const Offset(8, 17), 2.5, p);
        canvas.drawCircle(const Offset(17, 15), 2.5, p);
        canvas.drawPath(
          Path()
            ..moveTo(10.5, 17)
            ..lineTo(10.5, 6)
            ..lineTo(19.5, 4)
            ..lineTo(19.5, 15),
          p,
        );
      case AppIconName.haptic:
        canvas.drawRRect(rr(9, 5, 15, 19, 1.5), p);
        line(5, 9, 5, 15);
        line(19, 9, 19, 15);
      case AppIconName.home:
        // House: roof, walls, door.
        canvas.drawPath(
          Path()
            ..moveTo(4, 11)
            ..lineTo(12, 4)
            ..lineTo(20, 11),
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(6, 9.5)
            ..lineTo(6, 20)
            ..lineTo(18, 20)
            ..lineTo(18, 9.5),
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(10, 20)
            ..lineTo(10, 15)
            ..lineTo(14, 15)
            ..lineTo(14, 20),
          p,
        );
      case AppIconName.back:
        canvas.drawPath(
          Path()
            ..moveTo(15, 5)
            ..lineTo(8, 12)
            ..lineTo(15, 19),
          p,
        );
      case AppIconName.close:
        line(6, 6, 18, 18);
        line(18, 6, 6, 18);
      case AppIconName.lock:
        canvas.drawRRect(rr(6, 11, 18, 20, 2), p);
        canvas.drawArc(const Rect.fromLTRB(8, 4, 16, 14), math.pi, math.pi, false, p);
      case AppIconName.check:
        canvas.drawPath(
          Path()
            ..moveTo(5, 12.5)
            ..lineTo(10, 17.5)
            ..lineTo(19, 7),
          p,
        );
      case AppIconName.store:
        canvas.drawRRect(rr(5, 8, 19, 20, 2), p);
        canvas.drawArc(const Rect.fromLTRB(9, 4, 15, 11), math.pi, math.pi, false, p);
      case AppIconName.info:
        canvas.drawCircle(const Offset(12, 12), 8, p);
        line(12, 11, 12, 16);
        canvas.drawCircle(const Offset(12, 8), 1.1, fill);
      case AppIconName.powerupRefresh:
        // Two-tone circular arrows with solid heads.
        p.strokeWidth = 2.2;
        const box = Rect.fromLTRB(6, 6, 18, 18);
        canvas.drawArc(box, math.pi * 1.08, math.pi * 0.78, false, p);
        canvas.drawArc(box, math.pi * 0.08, math.pi * 0.78, false, p);
        Path head(double angle) {
          final tip = Offset(12 + 6 * math.cos(angle), 12 + 6 * math.sin(angle));
          final dir = angle + math.pi / 2;
          final back = tip - Offset(math.cos(dir), math.sin(dir)) * 3.6;
          final side = Offset(math.cos(angle), math.sin(angle)) * 2.4;
          return Path()
            ..moveTo(tip.dx + math.cos(dir) * 1.2, tip.dy + math.sin(dir) * 1.2)
            ..lineTo((back + side).dx, (back + side).dy)
            ..lineTo((back - side).dx, (back - side).dy)
            ..close();
        }
        canvas.drawPath(head(math.pi * 1.86), fill);
        canvas.drawPath(head(math.pi * 0.86), fill);
      case AppIconName.powerupJoker:
        // A letter tile with a sparkle: "any letter you want".
        final tile = rr(4.5, 4.5, 19.5, 19.5, 4);
        p.strokeWidth = 2;
        canvas.drawRRect(tile, p);
        final spark = Path()
          ..moveTo(12, 7)
          ..quadraticBezierTo(12.6, 11.4, 17, 12)
          ..quadraticBezierTo(12.6, 12.6, 12, 17)
          ..quadraticBezierTo(11.4, 12.6, 7, 12)
          ..quadraticBezierTo(11.4, 11.4, 12, 7)
          ..close();
        canvas.drawPath(spark, fill);
      case AppIconName.powerupHammer:
        // Solid head, rounded handle, angled.
        canvas.save();
        canvas.translate(12, 12);
        canvas.rotate(-math.pi / 4);
        canvas.drawRRect(
          RRect.fromLTRBR(-1.4, -2, 1.4, 10.5, const Radius.circular(1.4)),
          Paint()..color = color.withValues(alpha: 0.55),
        );
        canvas.drawRRect(RRect.fromLTRBR(-7, -8, 7, -2.2, const Radius.circular(1.8)), fill);
        canvas.restore();
      case AppIconName.streak:
        canvas.drawPath(
          Path()
            ..moveTo(12, 3)
            ..cubicTo(15, 8, 18, 10, 18, 14)
            ..cubicTo(18, 18, 15, 21, 12, 21)
            ..cubicTo(9, 21, 6, 18, 6, 14.5)
            ..cubicTo(6, 12, 8, 10, 9, 9)
            ..cubicTo(9.5, 11, 10.5, 12, 11.5, 12)
            ..cubicTo(11, 9, 11, 6, 12, 3),
          p,
        );
      case AppIconName.crown:
        // Solid crown: premium / no ads.
        canvas.drawPath(
          Path()
            ..moveTo(4, 8.5)
            ..lineTo(8.5, 12.5)
            ..lineTo(12, 6)
            ..lineTo(15.5, 12.5)
            ..lineTo(20, 8.5)
            ..lineTo(18.4, 17)
            ..lineTo(5.6, 17)
            ..close(),
          fill,
        );
        canvas.drawRRect(rr(5.6, 18.3, 18.4, 20.3, 1), fill);
        canvas.drawCircle(const Offset(4, 7.6), 1.5, fill);
        canvas.drawCircle(const Offset(12, 4.8), 1.5, fill);
        canvas.drawCircle(const Offset(20, 7.6), 1.5, fill);
      case AppIconName.gift:
        canvas.drawRRect(rr(5, 11, 19, 20, 1.5), p);
        canvas.drawRRect(rr(4, 8, 20, 11, 1), p);
        line(12, 8, 12, 20);
        canvas.drawPath(
          Path()
            ..moveTo(12, 8)
            ..cubicTo(10, 4, 6.5, 4.5, 7.5, 6.8)
            ..cubicTo(8.2, 8, 10.5, 8, 12, 8)
            ..cubicTo(13.5, 8, 15.8, 8, 16.5, 6.8)
            ..cubicTo(17.5, 4.5, 14, 4, 12, 8),
          p,
        );
      case AppIconName.star:
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final a = -math.pi / 2 + i * math.pi / 5;
          final r = i.isEven ? 8.5 : 3.8;
          final o = Offset(12 + r * math.cos(a), 12.6 + r * math.sin(a));
          i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
        }
        canvas.drawPath(path..close(), fill);
      case AppIconName.palette:
        canvas.drawPath(
          Path()
            ..moveTo(12, 4)
            ..cubicTo(6.5, 4, 4, 8, 4, 12)
            ..cubicTo(4, 16.5, 7.5, 20, 12, 20)
            ..cubicTo(13.5, 20, 14, 19, 13.4, 17.8)
            ..cubicTo(12.8, 16.5, 13.6, 15.2, 15, 15.2)
            ..lineTo(16.5, 15.2)
            ..cubicTo(18.5, 15.2, 20, 13.8, 20, 11.6)
            ..cubicTo(20, 7.2, 16.4, 4, 12, 4),
          p,
        );
        canvas.drawCircle(const Offset(8.5, 11), 1.3, fill);
        canvas.drawCircle(const Offset(11, 7.8), 1.3, fill);
        canvas.drawCircle(const Offset(15, 8.4), 1.3, fill);
      case AppIconName.tiles:
        canvas.drawRRect(rr(4, 4, 11, 11, 2), p);
        canvas.drawRRect(rr(13, 4, 20, 11, 2), fill);
        canvas.drawRRect(rr(4, 13, 11, 20, 2), fill);
        canvas.drawRRect(rr(13, 13, 20, 20, 2), p);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.name != name || old.color != color;
}
