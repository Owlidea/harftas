import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/core.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'board_art.dart';
import 'fx_art.dart';
import 'game_controller.dart';
import 'tile_renderer.dart';

/// The 8x8 board: tiles, previews, explosions, popups and particles.
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.controller,
    required this.renderer,
    required this.boardKey,
    this.boardStyle = 'plain',
  });

  final GameController controller;
  final TileRenderer renderer;
  final GlobalKey boardKey;

  /// Surface look (see [BoardArt]).
  final String boardStyle;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final s = controller.state;
    final picking = controller.phase == UiPhase.pickHammerCell || controller.phase == UiPhase.pickJokerCell;
    return Semantics(
      label: l.a11yBoard(s.grid.filledCount),
      container: true,
      child: GestureDetector(
        key: boardKey,
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) {
          final c = controller.geometry?.cellAt(d.globalPosition);
          if (c != null) controller.tapCell(c);
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _BoardPainter(controller, renderer, context.palette, picking, boardStyle),
                ),
              ),
            ),
            // Invisible semantic cells for screen readers.
            Positioned.fill(child: _SemanticCells(controller: controller)),
          ],
        ),
      ),
    );
  }
}

class _SemanticCells extends StatelessWidget {
  const _SemanticCells({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final g = controller.geometry;
    if (g == null) return const SizedBox.shrink();
    final l = L10n.of(context);
    return Stack(
      children: [
        for (var i = 0; i < 64; i++)
          Positioned.fromRect(
            rect: g.cellRectIndex(i),
            child: Semantics(
              button: true,
              label: controller.state.grid[i] == null
                  ? l.a11yEmptyCell(Grid.yOf(i) + 1, Grid.xOf(i) + 1)
                  : l.a11yCell(Grid.yOf(i) + 1, Grid.xOf(i) + 1, controller.state.grid[i]!.letter),
              onTap: () => controller.tapCell(i),
              child: const SizedBox.expand(),
            ),
          ),
      ],
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(this.c, this.r, this.p, this.picking, this.boardStyle) : super(repaint: c.frame);

  final GameController c;
  final TileRenderer r;
  final Palette p;
  final bool picking;
  final String boardStyle;
  final Paint _paint = Paint();
  final Paint _ring = Paint()..style = PaintingStyle.stroke;
  final Paint _layer = Paint();
  final Paint _fx = Paint()..filterQuality = FilterQuality.medium;

  @override
  void paint(Canvas canvas, Size size) {
    final g = c.geometry;
    if (g == null) return;
    final now = c.nowMs;

    // Screen shake (combo x3+), decays over 250 ms.
    final st = (now - c.shakeAt) / Motion.pop.inMilliseconds;
    if (st >= 0 && st < 1 && c.shakeAmp > 0) {
      final a = c.shakeAmp * (1 - st);
      canvas.translate(math.sin(st * 40) * a, math.cos(st * 33) * a * 0.6);
    }

    final surface = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width * 0.04));
    final textured = BoardArt.paint(canvas, surface, boardStyle, p.board);
    if (!textured) {
      _paint.color = p.board;
      canvas.drawRRect(surface, _paint);
    }

    final preview = c.dragPreview;
    final target = c.dragTarget;
    final dragShape = c.dragPiece == null ? null : c.state.hand[c.dragPiece!]?.shape;
    final previewHits = <int>{};
    if (preview != null) {
      for (final h in preview.hits) {
        previewHits.addAll(h.cells);
      }
    }

    final cellRadius = Radius.circular(g.cell * 0.16);
    for (var i = 0; i < 64; i++) {
      final rect = g.cellRectIndex(i);
      // On a textured surface the wells let the grain show through.
      _paint.color = textured ? p.cellEmpty.withValues(alpha: 0.7) : p.cellEmpty;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, cellRadius), _paint);
    }
    final grid = c.displayGrid;
    // Landing ring: a soft outline squeezed out from under a freshly placed tile.
    if (!c.reduceMotion) {
      for (var i = 0; i < 64; i++) {
        final t = (now - c.placedAt[i]) / Motion.landRing.inMilliseconds;
        if (t < 0 || t >= 1 || grid[i] == null) continue;
        final e = Curves.easeOutCubic.transform(t);
        _ring
          ..color = p.tileEdge.withValues(alpha: 0.55 * (1 - t))
          ..strokeWidth = g.cell * 0.07 * (1 - t) + 0.5;
        canvas.drawRRect(
          RRect.fromRectAndRadius(g.cellRectIndex(i).inflate(g.cell * 0.20 * e), Radius.circular(g.cell * (0.2 + 0.1 * e))),
          _ring,
        );
      }
    }
    for (var i = 0; i < 64; i++) {
      final cell = grid[i];
      if (cell == null) continue;
      final rect = g.cellRectIndex(i);
      var scale = 1.0;
      var opacity = 1.0;
      final placed = (now - c.placedAt[i]) / Motion.settle.inMilliseconds;
      if (placed >= 0 && placed < 1) scale = 0.86 + 0.14 * Curves.easeOutBack.transform(placed);
      final clearing = c.clearAt[i] > GameController.never;
      final cl = clearing ? (now - c.clearAt[i]) / Motion.pop.inMilliseconds : -1.0;
      if (cl >= 1) continue;
      if (cl >= 0) {
        if (c.reduceMotion) {
          opacity = 1 - cl;
        } else {
          scale = cl < 0.35 ? 1 + 0.25 * (cl / 0.35) : 1.25 * (1 - (cl - 0.35) / 0.65);
          opacity = 1 - Curves.easeIn.transform(cl);
        }
      }
      final hi = clearing && now >= c.highlightAt[i];
      final inPreview = previewHits.contains(i);
      r.draw(
        canvas,
        rect,
        letter: cell.letter,
        joker: cell.isJoker,
        scale: scale,
        opacity: opacity,
        highlight: hi || inPreview ? p.highlight : null,
      );
    }

    if (picking) {
      final wantFilled = c.phase == UiPhase.pickHammerCell;
      _ring
        ..color = p.accent
        ..strokeWidth = g.cell * 0.05;
      for (var i = 0; i < 64; i++) {
        if (c.state.grid.isFilled(i) == wantFilled) {
          canvas.drawRRect(RRect.fromRectAndRadius(g.cellRectIndex(i).inflate(g.gap * 0.3), cellRadius), _ring);
        }
      }
    }

    // Ghost of the dragged piece at the snapped target.
    if (dragShape != null && target != null) {
      final piece = c.state.hand[c.dragPiece!]!;
      for (var k = 0; k < piece.size; k++) {
        final o = dragShape.cells[k];
        final idx = Grid.indexOf(target.x + o.dx, target.y + o.dy);
        r.draw(
          canvas,
          g.cellRectIndex(idx),
          letter: piece.letters[k],
          opacity: 0.55,
          highlight: previewHits.contains(idx) ? p.highlight : null,
        );
      }
      // Score label for what would explode.
      final tp = c.previewLabel;
      if (tp != null) {
        final first = g.cellRect(target.x, target.y);
        final bubble = Rect.fromCenter(
          center: Offset(first.center.dx, math.max(first.top - g.cell * 0.32, tp.height / 2 + 4)),
          width: tp.width + g.cell * 0.36,
          height: tp.height + g.cell * 0.16,
        );
        _paint.color = p.highlight;
        canvas.drawRRect(RRect.fromRectAndRadius(bubble, Radius.circular(bubble.height / 2)), _paint);
        tp.paint(canvas, bubble.center - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // Rendered sprite effects: dust puffs, shards, hammer, joker.
    for (final f in c.boardFx) {
      final frame = f.sheet.frameAt(now - f.startMs);
      if (frame < 0) continue;
      canvas.drawImageRect(
        f.sheet.image,
        f.sheet.src(frame),
        Rect.fromCenter(center: f.center, width: f.size, height: f.size),
        _fx,
      );
    }

    c.particles.paint(canvas);

    final combo = c.comboFx;
    final burst = FxArt.sheet(FxArt.comboBurst);
    final nums = FxArt.sheet(FxArt.comboNums);
    if (combo != null && burst != null && nums != null) {
      final ms = now - combo.startMs;
      if (ms >= 0 && ms < ComboFx.durationMs) {
        final t = ms / ComboFx.durationMs;
        // Bigger with every extra word.
        final size = g.cell * (3.0 + 0.55 * math.min(combo.count - 2, 3));
        final frame = burst.frameAt(ms);
        if (frame >= 0) {
          canvas.drawImageRect(
            burst.image,
            burst.src(frame),
            Rect.fromCenter(center: combo.center, width: size * 1.25, height: size * 1.25),
            _fx,
          );
        }
        final grow = Curves.easeOutBack.transform((t / 0.3).clamp(0, 1).toDouble());
        final fade = t < 0.72 ? 1.0 : 1 - (t - 0.72) / 0.28;
        final n = size * 0.72 * grow * (1 + 0.04 * math.sin(t * 22));
        _fx.color = Color.fromRGBO(255, 255, 255, fade.clamp(0, 1).toDouble());
        canvas.drawImageRect(
          nums.image,
          nums.src(math.min(combo.count, nums.grid.cols + 1) - 2),
          Rect.fromCenter(center: combo.center, width: n, height: n),
          _fx,
        );
        _fx.color = const Color(0xFFFFFFFF);
      }
    }

    for (final pop in c.popups) {
      final t = (now - pop.startMs) / Motion.scoreFloat.inMilliseconds;
      if (t < 0 || t > 1) continue;
      final rise = (c.reduceMotion ? 0.3 : 1.0) * g.cell * 0.9 * Curves.easeOut.transform(t);
      final alpha = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;
      final pos = pop.at - Offset(pop.painter.width / 2, pop.painter.height / 2 + rise);
      _layer.color = Color.fromRGBO(0, 0, 0, alpha);
      canvas.saveLayer(pos & pop.painter.size, _layer);
      pop.painter.paint(canvas, pos);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.p != p || old.r != r || old.picking != picking || old.boardStyle != boardStyle;
}

/// One hand slot: the piece at reduced scale; hidden while dragged.
class HandSlot extends StatelessWidget {
  const HandSlot({super.key, required this.controller, required this.index, required this.renderer});

  final GameController controller;
  final int index;
  final TileRenderer renderer;

  @override
  Widget build(BuildContext context) {
    final piece = controller.state.hand[index];
    final l = L10n.of(context);
    final selected = controller.selectedPiece == index;
    return LayoutBuilder(
      builder: (context, box) {
        return Semantics(
          button: true,
          selected: selected,
          label: piece == null ? l.a11yPlaced : l.a11yPiece(piece.size, piece.letters.join(' ')),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => controller.tapPiece(index),
            onPanStart: (d) => controller.startDrag(index, d.globalPosition),
            onPanUpdate: (d) => controller.updateDrag(d.globalPosition),
            onPanEnd: (_) => controller.endDrag(),
            onPanCancel: controller.cancelDrag,
            child: CustomPaint(
              size: Size(box.maxWidth, box.maxHeight),
              painter: _SlotPainter(controller, index, renderer, context.palette, selected),
            ),
          ),
        );
      },
    );
  }
}

class _SlotPainter extends CustomPainter {
  _SlotPainter(this.c, this.i, this.r, this.p, this.selected) : super(repaint: c.frame);
  final GameController c;
  final int i;
  final TileRenderer r;
  final Palette p;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final piece = c.state.hand[i];
    final g = c.geometry;
    if (piece == null || g == null) return;
    if (c.dragPiece == i || c.returningPiece == i) return;
    final now = c.nowMs;
    final appear = (now - c.handDealtAt - i * Motion.handStagger.inMilliseconds) / Motion.handIn.inMilliseconds;
    if (appear < 0) return;
    final t = Curves.easeOutBack.transform(appear.clamp(0, 1).toDouble());

    // Show the piece as large as its slot allows (thumb-sized letters), up to
    // full board scale; long pieces shrink just enough to fit.
    const gapF = 0.08;
    final fitW = size.width * 0.9 / (piece.shape.width + (piece.shape.width - 1) * gapF);
    final fitH = size.height * 0.8 / (piece.shape.height + (piece.shape.height - 1) * gapF);
    final cell = math.min(g.cell, math.min(fitW, fitH));
    final gap = cell * gapF;
    final w = piece.shape.width * cell + (piece.shape.width - 1) * gap;
    final h = piece.shape.height * cell + (piece.shape.height - 1) * gap;
    final origin = Offset((size.width - w) / 2, (size.height - h) / 2 + (1 - t) * cell * 0.8);

    if (selected) {
      final ring = Paint()
        ..color = p.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius((origin & Size(w, h)).inflate(cell * 0.25), Radius.circular(cell * 0.3)),
        ring,
      );
    }
    final locked = !c.engine.canPlaceAnywhere(c.state, i);
    for (var k = 0; k < piece.size; k++) {
      final o = piece.shape.cells[k];
      r.draw(
        canvas,
        Rect.fromLTWH(origin.dx + o.dx * (cell + gap), origin.dy + o.dy * (cell + gap), cell, cell),
        letter: piece.letters[k],
        opacity: (locked ? 0.4 : 1) * t.clamp(0, 1),
      );
    }
  }

  @override
  bool shouldRepaint(_SlotPainter old) => old.p != p || old.selected != selected || old.r != r;
}

/// Full-screen overlay painting the dragged / returning piece.
class DragOverlay extends StatelessWidget {
  const DragOverlay({super.key, required this.controller, required this.renderer});
  final GameController controller;
  final TileRenderer renderer;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(size: Size.infinite, painter: _DragPainter(controller, renderer, context.palette)),
    );
  }
}

class _DragPainter extends CustomPainter {
  _DragPainter(this.c, this.r, this.p) : super(repaint: c.frame);
  final GameController c;
  final TileRenderer r;
  final Palette p;

  @override
  void paint(Canvas canvas, Size size) {
    final g = c.geometry;
    if (g == null) return;
    final box = Offset.zero; // overlay is full-screen at global origin
    final dragging = c.dragPiece;
    if (dragging != null) {
      final piece = c.state.hand[dragging]!;
      final tl = c.dragTopLeft(piece.shape) - box;
      _drawPiece(canvas, piece, tl, g.cell * Motion.dragScale, g.gap * Motion.dragScale, shadow: true);
    }
    final ret = c.returningPiece;
    if (ret != null && c.state.hand[ret] != null) {
      final piece = c.state.hand[ret]!;
      final t = ((c.nowMs - c.returnAt) / Motion.returnToHand.inMilliseconds).clamp(0, 1).toDouble();
      final k = Curves.easeOutBack.transform(t);
      final to = c.slotCenters[ret] ?? c.returnFrom;
      final center = Offset.lerp(c.returnFrom - const Offset(0, Motion.dragLift), to, k)!;
      final scale = 1 - 0.38 * k;
      final cell = g.cell * scale;
      final gap = g.gap * scale;
      final w = piece.shape.width * cell + (piece.shape.width - 1) * gap;
      final h = piece.shape.height * cell + (piece.shape.height - 1) * gap;
      _drawPiece(canvas, piece, center - Offset(w / 2, h / 2), cell, gap, shadow: false);
    }
  }

  void _drawPiece(Canvas canvas, Piece piece, Offset tl, double cell, double gap, {required bool shadow}) {
    if (shadow) {
      final w = piece.shape.width * cell + (piece.shape.width - 1) * gap;
      final h = piece.shape.height * cell + (piece.shape.height - 1) * gap;
      canvas.drawRRect(
        RRect.fromRectAndRadius((tl + Offset(0, cell * 0.18)) & Size(w, h), Radius.circular(cell * 0.2)),
        Paint()
          ..color = p.shadow
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.18),
      );
    }
    for (var k = 0; k < piece.size; k++) {
      final o = piece.shape.cells[k];
      r.draw(
        canvas,
        Rect.fromLTWH(tl.dx + o.dx * (cell + gap), tl.dy + o.dy * (cell + gap), cell, cell),
        letter: piece.letters[k],
      );
    }
  }

  @override
  bool shouldRepaint(_DragPainter old) => old.p != p || old.r != r;
}
