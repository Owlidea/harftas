import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_model.dart';
import '../../config/asset_paths.dart';
import '../../core/core.dart';
import '../../l10n/app_localizations.dart';
import '../../services/analytics.dart';
import '../components/app_icon.dart';
import '../components/widgets.dart';
import '../game/board_view.dart';
import '../game/game_controller.dart';
import '../game/tile_renderer.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'game_screen.dart';

/// Four playable, skippable steps (spec 9).
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key, this.thenPlay = false});
  final bool thenPlay;

  static Route<void> route({bool thenPlay = false}) =>
      MaterialPageRoute(builder: (_) => TutorialScreen(thenPlay: thenPlay));

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> with SingleTickerProviderStateMixin {
  GameController? c;
  late final Ticker _ticker;
  final _boardKey = GlobalKey();
  final _slotKeys = List.generate(3, (_) => GlobalKey());
  TileRenderer? _renderer;
  int _step = 0; // 0..3, 4 = done
  bool _great = false;

  static Piece _mono(String l) => Piece(ShapeCatalog.byFamily[ShapeFamily.mono]!.single, [l]);

  static const _boards = [
    ['........', '........', '........', '..KA....', '........', '........', '........', '........'],
    ['........', '........', '...T....', '...A....', '........', '........', '........', '........'],
    ['..K.....', '..A.....', 'NA......', '........', '........', '........', '........', '........'],
    ['........', '........', '........', '..KAJ...', '........', '........', '........', '........'],
  ];
  static const _letters = ['R', 'Ş', 'R', 'R'];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) {
      if (c?.animating ?? false) c!.tick(d);
    })..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(0));
  }

  void _load(int step) {
    final app = AppScope.read(context);
    app.services.analytics.log(AnalyticsEvent.tutorialStep, {'step': step + 1});
    final e = app.engine!;
    final base = e.newGame(
      seed: 7,
      mode: GameMode.classic,
      startedAt: app.clock(),
      powerups: {PowerupType.refresh: 0, PowerupType.joker: 0, PowerupType.hammer: step == 3 ? 1 : 0},
    );
    final s = base.copyWith(
      grid: Grid.fromRows(_boards[step]),
      hand: [null, _mono(_letters[step]), null],
      status: GameStatus.playing,
    );
    c?.dispose();
    c = GameController(app: app, state: s, tutorial: true, onResolved: _onResolved)
      ..palette = context.palette
      ..reduceMotion = context.reduceMotion
      ..addListener(() {
        if (mounted) setState(() {});
      })
      ..playEntrance();
    setState(() {
      _step = step;
      _great = false;
    });
  }

  void _onResolved(GameAction a, List<GameEvent> events) {
    if (!events.any((e) => e is WordsFound)) return;
    setState(() => _great = true);
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_step < 3) {
        _load(_step + 1);
      } else {
        setState(() => _step = 4);
      }
    });
  }

  Future<void> _finish({bool skipped = false}) async {
    final app = AppScope.read(context);
    if (skipped) app.services.analytics.log(AnalyticsEvent.tutorialSkip, {'step': _step + 1});
    app.profile.tutorialDone = true;
    unawaited(app.saveProfile());
    if (!mounted) return;
    if (widget.thenPlay) {
      final s = app.savedClassic ?? app.newClassicGame();
      await Navigator.of(context).pushReplacement(GameScreen.route(s));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _renderer = TileRenderer(
      palette: context.palette,
      style: context.appTheme.tileStyle,
      scores: AppScope.read(context).data!.config.letterScores,
    );
    c?.palette = context.palette;
  }

  @override
  void dispose() {
    _ticker.dispose();
    c?.dispose();
    super.dispose();
  }

  void _measure() {
    final ctrl = c;
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (ctrl == null || box == null || !box.hasSize) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (ctrl.geometry?.rect != rect) ctrl.geometry = BoardGeometry(rect);
    for (var i = 0; i < 3; i++) {
      final b = _slotKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (b != null && b.hasSize) ctrl.slotCenters[i] = b.localToGlobal(b.size.center(Offset.zero));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final p = context.palette;
    final ctrl = c;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final hints = [l.tutorialStep1, l.tutorialStep2, l.tutorialStep3, l.tutorialStep4];

    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final size = math.min(math.min(box.maxWidth - 2 * Space.screenGutter, 520.0), box.maxHeight * 0.5);
                return Center(
                  child: SizedBox(
                    width: size,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (_step < 4) Text(l.tutorialStepOf(_step + 1), style: context.text.labelLarge),
                            const Spacer(),
                            if (_step < 4)
                              TextButton(onPressed: () => _finish(skipped: true), child: Text(l.tutorialSkip)),
                          ],
                        ),
                        const SizedBox(height: Space.s3),
                        AnimatedSwitcher(
                          duration: Motion.screen,
                          child: Panel(
                            key: ValueKey('$_step$_great'),
                            color: _great ? p.accentSoft : null,
                            child: Row(
                              children: [
                                AppIcon(_great ? AppIconName.check : AppIconName.info, color: p.accent),
                                const SizedBox(width: Space.s3),
                                Expanded(
                                  child: Text(
                                    _step == 4 ? l.tutorialDone : (_great ? l.tutorialGreat : hints[_step]),
                                    style: context.text.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_step < 4 && ctrl != null) ...[
                          SizedBox.square(
                            dimension: size,
                            child: BoardView(controller: ctrl, renderer: _renderer!, boardKey: _boardKey),
                          ),
                          const SizedBox(height: Space.s3),
                          SizedBox(
                            height: 52,
                            child: _step == 3
                                ? Center(
                                    child: SecondaryButton(
                                      label: '${l.powerupHammer} · ${ctrl.state.powerup(PowerupType.hammer)}',
                                      icon: AppIconName.powerupHammer,
                                      onPressed: ctrl.state.powerup(PowerupType.hammer) > 0
                                          ? () => ctrl.tapPowerup(PowerupType.hammer)
                                          : null,
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(
                            height: math.min(size * 0.36, 150),
                            child: Row(
                              children: [
                                for (var i = 0; i < 3; i++)
                                  Expanded(
                                    child: HandSlot(
                                      key: _slotKeys[i],
                                      controller: ctrl,
                                      index: i,
                                      renderer: _renderer!,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ] else if (_step == 4) ...[
                          const Logo(height: 96),
                          const Spacer(),
                          PrimaryButton(label: l.tutorialStart, onPressed: _finish),
                        ],
                        const SizedBox(height: Space.s4),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (ctrl != null && _step < 4)
            Positioned.fill(
              child: DragOverlay(controller: ctrl, renderer: _renderer!),
            ),
        ],
      ),
    );
  }
}
