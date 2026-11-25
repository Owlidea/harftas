import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/app_model.dart';
import '../../config/asset_paths.dart';
import '../../core/config/balance_config.dart';
import '../../core/text/word_language.dart';
import '../../l10n/app_localizations.dart';
import '../components/app_icon.dart';
import '../components/widgets.dart';
import '../components/segmented.dart';
import '../game/language_examples.dart';
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

  /// First start adds a page that picks the word language (karar 29).
  int get _count => widget.firstRun ? 5 : 4;

  @override
  void initState() {
    super.initState();
    if (widget.firstRun) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final app = AppScope.read(context);
        // Pre-select from the device region; the player can change it here.
        if (app.settings.wordLanguage == null) {
          unawaited(app.setWordLanguage(AppModel.suggestedLanguage(WidgetsBinding.instance.platformDispatcher.locale)));
        }
      });
    }
  }

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
    final app = AppScope.of(context);
    final language = app.wordLanguage;
    final ex = LanguageExamples.of(language);
    final config = app.data?.config ?? BalanceConfig.defaultsFor(language);
    final dictNote = switch (language) {
      TurkishLanguage() => l.dictNoteTr,
      EnglishLanguage() => l.dictNoteEn,
    };
    final pages = [
      if (widget.firstRun) _LanguagePage(current: language, onChanged: (w) => unawaited(app.setWordLanguage(w))),
      _Page(title: l.intro1Title, body: l.intro1Body, visual: _GoalVisual(ex, config)),
      _Page(title: l.intro2Title, body: '${l.intro2Body} $dictNote', visual: _ReadingVisual(ex, config)),
      _Page(title: l.intro3Title, body: l.intro3Body, visual: _ScoreVisual(ex, config)),
      _Page(title: l.intro4Title, body: l.intro4Body, visual: _EndVisual(ex, config)),
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

/// First start only: which language the board is played in.
class _LanguagePage extends StatelessWidget {
  const _LanguagePage({required this.current, required this.onChanged});
  final WordLanguage current;
  final ValueChanged<WordLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final ex = LanguageExamples.of(current);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.s6, Space.s6, Space.s6, Space.s4),
      child: Column(
        children: [
          ExcludeSemantics(
            child: SizedBox(
              height: 220,
              child: Center(
                child: MiniBoard(
                  rows: ['.....', '.${ex.goal}.', '.....'],
                  lit: const {6, 7, 8},
                  scores: BalanceConfig.defaultsFor(current).letterScores,
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.s8),
          Text(l.introLanguage, textAlign: TextAlign.center, style: context.text.titleLarge),
          const SizedBox(height: Space.s4),
          Segmented<WordLanguage>(
            values: WordLanguage.values,
            current: current,
            label: (w) => w.nativeName,
            onChanged: onChanged,
          ),
          const SizedBox(height: Space.s4),
          Text(
            l.wordLanguageDesc,
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
  const MiniBoard({super.key, required this.rows, this.lit = const {}, this.cell = 40, this.scores});
  final List<String> rows;
  final Set<int> lit;
  final double cell;

  /// Letter scores shown on the tiles (Turkish when null).
  final Map<String, int>? scores;

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
          scores: scores ?? BalanceConfig.defaults.letterScores,
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
  const _GoalVisual(this.ex, this.config);
  final LanguageExamples ex;
  final BalanceConfig config;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MiniBoard(rows: ['.....', '.${ex.goal}.', '.....'], lit: const {6, 7, 8}, scores: config.letterScores),
        const SizedBox(height: Space.s3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIconName.check, color: p.success, size: 20),
            const SizedBox(width: Space.s2),
            Text(
              '${ex.goal}  +${wordPoints(ex.goal, config)}',
              style: context.text.headlineSmall!.copyWith(color: p.ink),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReadingVisual extends StatelessWidget {
  const _ReadingVisual(this.ex, this.config);
  final LanguageExamples ex;
  final BalanceConfig config;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    TextStyle s = context.text.labelLarge!.copyWith(color: p.ink);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MiniBoard(rows: ex.readingRows, lit: const {2, 7, 10, 11, 12}, cell: 34, scores: config.letterScores),
        const SizedBox(width: Space.s4),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('→  ${ex.across}', style: s),
              const SizedBox(height: Space.s2),
              Text('↓  ${ex.down}', style: s),
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
  const _ScoreVisual(this.ex, this.config);
  final LanguageExamples ex;
  final BalanceConfig config;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lines = scoreLines(ex.scoreWord, config);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MiniBoard(rows: [ex.scoreWord], lit: const {0, 1, 2, 3, 4}, cell: 46, scores: config.letterScores),
        const SizedBox(height: Space.s4),
        Text(lines.sum, style: context.text.bodyLarge!.copyWith(color: p.inkMuted)),
        const SizedBox(height: Space.s1),
        Text(lines.total, style: context.text.titleLarge!.copyWith(color: p.accent)),
      ],
    );
  }
}

class _EndVisual extends StatelessWidget {
  const _EndVisual(this.ex, this.config);
  final LanguageExamples ex;
  final BalanceConfig config;
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
        MiniBoard(rows: ex.stuckRows, cell: 34, scores: config.letterScores),
        const SizedBox(height: Space.s4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [pu(AppIconName.powerupRefresh), pu(AppIconName.powerupJoker), pu(AppIconName.powerupHammer)],
        ),
      ],
    );
  }
}
