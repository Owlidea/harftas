import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Draws letter tiles on a canvas. Text layouts are cached per (letter,
/// size) so painting a frame allocates nothing once warm (spec 14).
class TileRenderer {
  TileRenderer({required this.palette, required this.style, required this.scores});

  final Palette palette;
  final TileStyle style;

  /// Letter -> points.
  final Map<String, int> scores;

  final Map<int, TextPainter> _letters = {};
  final Map<int, TextPainter> _scores = {};
  final Paint _face = Paint();
  final Paint _edge = Paint();
  final Paint _stroke = Paint()..style = PaintingStyle.stroke;
  final Paint _bar = Paint();
  final Paint _layer = Paint();

  TextPainter _text(Map<int, TextPainter> cache, String s, double size, FontWeight w, Color c) {
    final key = s.codeUnitAt(0) * 4096 + size.round() * 2 + (s.length > 1 ? 1 : 0);
    return cache[key] ??= TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontFamily: appFontFamily, fontSize: size, fontWeight: w, color: c, height: 1),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
  }

  /// [opacity] < 1 draws through a layer (used for previews only).
  void draw(
    Canvas canvas,
    Rect r, {
    required String letter,
    bool joker = false,
    double opacity = 1,
    double scale = 1,
    Color? highlight,
  }) {
    if (opacity <= 0 || scale <= 0) return;
    canvas.save();
    if (scale != 1) {
      final c = r.center;
      canvas
        ..translate(c.dx, c.dy)
        ..scale(scale)
        ..translate(-c.dx, -c.dy);
    }
    if (opacity < 1) {
      _layer.color = Color.fromRGBO(0, 0, 0, opacity);
      canvas.saveLayer(r.inflate(r.width * 0.2), _layer);
    }
    final radius = Radius.circular(r.width * style.radiusFactor);
    final depth = style.bevel ? r.height * 0.07 : 0.0;
    final face = Rect.fromLTRB(r.left, r.top, r.right, r.bottom - depth);

    if (style.bevel) {
      _edge.color = palette.tileEdge;
      canvas.drawRRect(RRect.fromRectAndRadius(r, radius), _edge);
    } else {
      _edge.color = palette.shadow;
      canvas.drawRRect(RRect.fromRectAndRadius(r.shift(Offset(0, r.height * 0.04)), radius), _edge);
    }
    _face.color = joker ? palette.joker : palette.tile;
    canvas.drawRRect(RRect.fromRectAndRadius(face, radius), _face);
    if (style.border) {
      _stroke
        ..color = palette.tileEdge
        ..strokeWidth = r.width * 0.03;
      canvas.drawRRect(RRect.fromRectAndRadius(face.deflate(r.width * 0.015), radius), _stroke);
    }

    final lt = _text(_letters, letter, r.width * 0.54, FontWeight.w700, palette.tileInk);
    lt.paint(canvas, Offset(face.center.dx - lt.width / 2, face.center.dy - lt.height / 2 - r.height * 0.02));

    final pts = joker ? 0 : (scores[letter] ?? 0);
    final st = _text(_scores, '$pts', r.width * 0.2, FontWeight.w600, palette.tileScore);
    st.paint(canvas, Offset(face.right - st.width - r.width * 0.09, face.bottom - st.height - r.height * 0.07));

    if (joker) {
      // Joker marker: small corner triangle (shape, not just colour).
      final path = Path()
        ..moveTo(face.left + r.width * 0.08, face.top + r.width * 0.08)
        ..lineTo(face.left + r.width * 0.26, face.top + r.width * 0.08)
        ..lineTo(face.left + r.width * 0.08, face.top + r.width * 0.26)
        ..close();
      _bar.color = palette.tileScore;
      canvas.drawPath(path, _bar);
    }

    if (highlight != null) {
      // Outline + underline: information is not carried by colour alone.
      _stroke
        ..color = highlight
        ..strokeWidth = r.width * 0.07;
      canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(r.width * 0.02), radius), _stroke);
      _bar.color = highlight;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(face.left + r.width * 0.22, face.bottom - r.height * 0.12, r.width * 0.56, r.height * 0.06),
          Radius.circular(r.height * 0.03),
        ),
        _bar,
      );
    }

    if (opacity < 1) canvas.restore();
    canvas.restore();
  }
}

/// Fixed-size particle pool for word explosions (no per-frame allocation).
class ParticlePool {
  ParticlePool([this.capacity = 240])
    : _x = Float32List(capacity),
      _y = Float32List(capacity),
      _vx = Float32List(capacity),
      _vy = Float32List(capacity),
      _life = Float32List(capacity),
      _max = Float32List(capacity),
      _size = Float32List(capacity),
      _color = Int32List(capacity);

  final int capacity;
  final Float32List _x, _y, _vx, _vy, _life, _max, _size;
  final Int32List _color;
  int _next = 0;
  int _alive = 0;
  int _seed = 12345;
  final Paint _paint = Paint();

  bool get active => _alive > 0;

  double _rand() {
    _seed = (_seed * 1103515245 + 12345) & 0x7FFFFFFF;
    return _seed / 0x7FFFFFFF;
  }

  void spawn(Offset at, Color color, int count, double speed, double size) {
    for (var n = 0; n < count; n++) {
      final i = _next;
      _next = (_next + 1) % capacity;
      final a = _rand() * 6.2831853;
      final v = speed * (0.4 + _rand() * 0.8);
      _x[i] = at.dx;
      _y[i] = at.dy;
      _vx[i] = v * _cos(a);
      _vy[i] = v * _sin(a) - speed * 0.35;
      _max[i] = 0.45 + _rand() * 0.35;
      _life[i] = _max[i];
      _size[i] = size * (0.5 + _rand() * 0.7);
      _color[i] = color.toARGB32();
    }
    _recount();
  }

  static double _sin(double a) => _cos(a - 1.5707963);
  static double _cos(double a) {
    // Fast enough and allocation-free; precision is irrelevant for sparks.
    var x = a % 6.2831853;
    if (x > 3.1415927) x -= 6.2831853;
    final x2 = x * x;
    return 1 - x2 / 2 + x2 * x2 / 24 - x2 * x2 * x2 / 720;
  }

  void update(double dt) {
    if (_alive == 0) return;
    for (var i = 0; i < capacity; i++) {
      if (_life[i] <= 0) continue;
      _life[i] -= dt;
      _vy[i] += 900 * dt;
      _x[i] += _vx[i] * dt;
      _y[i] += _vy[i] * dt;
    }
    _recount();
  }

  void _recount() {
    var n = 0;
    for (var i = 0; i < capacity; i++) {
      if (_life[i] > 0) n++;
    }
    _alive = n;
  }

  void clear() {
    for (var i = 0; i < capacity; i++) {
      _life[i] = 0;
    }
    _alive = 0;
  }

  void paint(Canvas canvas) {
    if (_alive == 0) return;
    for (var i = 0; i < capacity; i++) {
      final l = _life[i];
      if (l <= 0) continue;
      final t = l / _max[i];
      _paint.color = Color(_color[i]).withValues(alpha: t.clamp(0, 1));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(_x[i], _y[i]), width: _size[i] * t, height: _size[i] * t),
          Radius.circular(_size[i] * 0.25),
        ),
        _paint,
      );
    }
  }
}
