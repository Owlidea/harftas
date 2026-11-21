import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/app_model.dart';
import '../../config/asset_paths.dart';
import '../../core/config/balance_config.dart';
import '../../l10n/app_localizations.dart';
import '../components/app_icon.dart';
import '../components/widgets.dart';
import '../game/tile_renderer.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'tutorial_screen.dart';

/// "Nasıl oynanır" pages. Shown once on first launch ([firstRun]) and
/// reachable any time from the home "?" button and Settings.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, this.firstRun = false});
  final bool firstRun;

  static Route<void> route({bool firstRun = false}) =>
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => IntroScreen(firstRun: firstRun));

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pages = PageController();
  int _page = 0;
  static const _count = 4;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _markSeen() {
    final app = AppScope.read(context);
    if (!app.profile.introSeen) {
      app.profile.introSeen = true;
      unawaited(app.saveProfile());
    }
  }

  void _next() {
    if (_page < _count - 1) {
      _pages.nextPage(duration: context.reduceMotion ? Duration.zero : Motion.screen, curve: Curves.easeOutCubic);
      return;
    }
    _markSeen();
    final app = AppScope.read(context);
    if (widget.firstRun && !app.profile.tutorialDone && app.ready) {
      Navigator.of(context).pushReplacement(TutorialScreen.route(thenPlay: true));
    } else {
      Navigator.of(context).pop();
    }
  }

  void _skip() {
    _markSeen();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final p = context.palette;
    final last = _page == _count - 1;
    final pages = [
      _Page(title: l.intro1Title, body: l.intro1Body, visual: const _GoalVisual()),
      _Page(title: l.intro2Title, body: l.intro2Body, visual: const _ReadingVisual()),
      _Page(title: l.intro3Title, body: l.intro3Body, visual: const _ScoreVisual()),
      _Page(title: l.intro4Title, body: l.intro4Body, visual: const _EndVisual()),
    ];

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.s4, Space.s2, Space.s2, 0),
                  child: Row(
                    children: [
                      Text(l.introHelp, style: context.text.labelLarge!.copyWith(color: p.inkMuted)),
                      const Spacer(),
                      if (widget.firstRun)
                        TextButton(onPressed: _skip, child: Text(l.introSkip))
                      else
                        IconBtn(icon: AppIconName.close, label: l.close, onPressed: _skip),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(controller: _pages, onPageChanged: (i) => setState(() => _page = i), children: pages),
                ),
                Semantics(
                  label: l.introPage(_page + 1, _count),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _count; i++)
                        AnimatedContainer(
                          duration: Motion.pick,
                          margin: const EdgeInsets.symmetric(horizontal: Space.s1),
                          width: i == _page ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page ? p.accent : p.divider,
                            borderRadius: BorderRadius.circular(Radii.pill),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.s6, Space.s5, Space.s6, Space.s4),
                  child: PrimaryButton(
                    label: !last ? l.introNext : (widget.firstRun ? l.introStart : l.introGotIt),
                    onPressed: _next,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.title, required this.body, required this.visual});
  final String title;
  final String body;
  final Widget visual;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.s6, Space.s6, Space.s6, Space.s4),
      child: Column(
        children: [
          ExcludeSemantics(
            child: SizedBox(height: 220, child: Center(child: visual)),
          ),
          const SizedBox(height: Space.s8),
          Text(title, textAlign: TextAlign.center, style: context.text.titleLarge),
          const SizedBox(height: Space.s3),
          Text(
            body,
            textAlign: TextAlign.center,
            style: context.text.bodyLarge!.copyWith(color: context.palette.inkMuted),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- visuals

/// Small code-drawn board: rows of letters ('.' = empty), [lit] = highlighted
/// cell indices (row * cols + col).
class MiniBoard extends StatelessWidget {
  const MiniBoard({super.key, required this.rows, this.lit = const {}, this.cell = 40});
  final List<String> rows;
  final Set<int> lit;
  final double cell;

  @override
  Widget build(BuildContext context) {
    final cols = rows.first.length;
    final gap = cell * 0.1;
    final pad = cell * 0.18;
    final w = cols * cell + (cols - 1) * gap + 2 * pad;
    final h = rows.length * cell + (rows.length - 1) * gap + 2 * pad;
    return CustomPaint(
      size: Size(w, h),
      painter: _MiniPainter(
        rows: rows,
        lit: lit,
        cell: cell,
        gap: gap,
        pad: pad,
        palette: context.palette,
        renderer: TileRenderer(
          palette: context.palette,
          style: context.appTheme.tileStyle,
          scores: BalanceConfig.defaults.letterScores,
        ),
      ),
    );
  }
}

class _MiniPainter extends CustomPainter {
  _MiniPainter({
    required this.rows,
    required this.lit,
    required this.cell,
    required this.gap,
    required this.pad,
    required this.palette,
    required this.renderer,
  });
  final List<String> rows;
  final Set<int> lit;
  final double cell, gap, pad;
  final Palette palette;
  final TileRenderer renderer;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = palette.board;
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(cell * 0.3)), paint);
    final cols = rows.first.length;
    for (var y = 0; y < rows.length; y++) {
      final letters = rows[y].split('');
      for (var x = 0; x < cols; x++) {
        final r = Rect.fromLTWH(pad + x * (cell + gap), pad + y * (cell + gap), cell, cell);
        paint.color = palette.cellEmpty;
        canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(cell * 0.16)), paint);
        if (letters[x] != '.') {
          renderer.draw(
            canvas,
            r,
            letter: letters[x],
            highlight: lit.contains(y * cols + x) ? palette.highlight : null,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_MiniPainter old) => old.palette != palette || old.rows != rows;
}

class _GoalVisual extends StatelessWidget {
  const _GoalVisual();
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MiniBoard(rows: ['.....', '.KAR.', '.....'], lit: {6, 7, 8}),
        const SizedBox(height: Space.s3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIconName.check, color: p.success, size: 20),
            const SizedBox(width: Space.s2),
            Text('KAR  +3', style: context.text.headlineSmall!.copyWith(color: p.ink)),
          ],
        ),
      ],
    );
  }
}

class _ReadingVisual extends StatelessWidget {
  const _ReadingVisual();
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    TextStyle s = context.text.labelLarge!.copyWith(color: p.ink);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MiniBoard(rows: ['..K..', '..A..', 'NAR..', '.....'], lit: {2, 7, 10, 11, 12}, cell: 34),
        const SizedBox(width: Space.s4),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('→  NAR', style: s),
              const SizedBox(height: Space.s2),
              Text('↓  KAR', style: s),
              const SizedBox(height: Space.s3),
              InfoChip(icon: AppIconName.streak, text: L10n.of(context).comboLabel(2), highlight: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreVisual extends StatelessWidget {
  const _ScoreVisual();
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MiniBoard(rows: ['KALEM'], lit: {0, 1, 2, 3, 4}, cell: 46),
        const SizedBox(height: Space.s4),
        Text('1 + 1 + 1 + 1 + 2 = 6', style: context.text.bodyLarge!.copyWith(color: p.inkMuted)),
        const SizedBox(height: Space.s1),
        Text('6 × 2 = 12', style: context.text.titleLarge!.copyWith(color: p.accent)),
      ],
    );
  }
}

class _EndVisual extends StatelessWidget {
  const _EndVisual();
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget pu(AppIconName i) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.s2),
      child: AppIcon(i, size: 26, color: p.accent),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MiniBoard(rows: ['ZTB.Y', 'ÇUPSH', 'L.ŞGD', 'MFNÖJ'], cell: 34),
        const SizedBox(height: Space.s4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [pu(AppIconName.powerupRefresh), pu(AppIconName.powerupJoker), pu(AppIconName.powerupHammer)],
        ),
      ],
    );
  }
}
