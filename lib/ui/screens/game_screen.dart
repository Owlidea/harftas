import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_model.dart';
import '../../config/asset_paths.dart';
import '../../progress/profile.dart';
import '../../core/core.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/calendar.dart';
import '../../progress/next_goal.dart';
import '../../progress/progression.dart';
import '../components/app_icon.dart';
import '../components/confetti.dart';
import '../components/overlays.dart';
import '../components/sprite_anim.dart';
import '../components/widgets.dart';
import '../game/board_view.dart';
import '../game/game_controller.dart';
import '../game/pause_sheet.dart';
import '../game/tile_renderer.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'missions_screen.dart' show missionText;
import 'share_card.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.initial, this.dailyDay});

  final GameState initial;
  final DayKey? dailyDay;

  static Route<void> route(GameState s, {DayKey? dailyDay}) => MaterialPageRoute(
    builder: (_) => GameScreen(initial: s, dailyDay: dailyDay),
  );

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late final GameController c;
  late final Ticker _ticker;
  late final AppLifecycleListener _lifecycle;
  final _boardKey = GlobalKey();
  final _slotKeys = List.generate(3, (_) => GlobalKey());
  final _shareKey = GlobalKey();
  TileRenderer? _renderer;
  Palette? _rendererPalette;
  String? _rendererStyle;
  bool _letterSheetOpen = false;

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    c = GameController(app: app, state: widget.initial, dailyDay: widget.dailyDay)..addListener(_onChange);
    _ticker = createTicker(_onTick)..start();
    _lifecycle = AppLifecycleListener(onHide: c.cancelDrag, onPause: c.cancelDrag);
    c.playEntrance();
  }

  void _onTick(Duration d) {
    if (c.animating) c.tick(d);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = context.palette;
    final style = context.appTheme.tileStyle;
    if (_renderer == null || _rendererPalette != p || _rendererStyle != style.id) {
      _renderer = TileRenderer(palette: p, style: style, scores: AppScope.read(context).data!.config.letterScores);
      _rendererPalette = p;
      _rendererStyle = style.id;
    }
    c
      ..palette = p
      ..reduceMotion = context.reduceMotion;
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    _showToasts();
    if (c.effects.isNotEmpty) {
      for (final asset in c.effects) {
        if (SpriteAnim.available(asset)) _fx.add((id: _fxSeq++, asset: asset));
      }
      c.effects.clear();
    }
    if (c.phase == UiPhase.pickJokerLetter && !_letterSheetOpen) _pickLetter();
    if (c.phase == UiPhase.over && c.endResult?.dailyResult != null) _maybeAskNotifications();
  }

  /// Celebration sprite sheets currently playing over the board.
  final List<({int id, String asset})> _fx = [];
  int _fxSeq = 0;

  void _showToasts() {
    if (c.toasts.isEmpty) return;
    final l = L10n.of(context);
    final items = List.of(c.toasts);
    c.toasts.clear();
    for (final t in items) {
      final text = switch (t) {
        MissionToast(:final mission) => '${l.missionCompleted}: ${missionText(l, mission)}',
        LevelToast(:final reward) => l.levelUp(reward.level),
        TextToast(kind: TextToastKind.dailyNoPowerups) => l.dailyNoPowerups,
        TextToast(kind: TextToastKind.noPowerupLeft) => l.noPowerupLeft,
      };
      showGameToast(
        context,
        text,
        icon: switch (t) {
          MissionToast() => AppIconName.missions,
          LevelToast() => AppIconName.star,
          TextToast() => AppIconName.info,
        },
      );
    }
  }

  bool _askedThisScreen = false;
  Future<void> _maybeAskNotifications() async {
    final app = AppScope.read(context);
    if (_askedThisScreen || app.profile.notificationAsked) return;
    _askedThisScreen = true;
    // Spec 8: ask only after the first daily puzzle, explaining why.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final l = L10n.of(context);
    final yes = await showConfirmSheet(
      context,
      title: l.notifAskTitle,
      body: l.notifAskBody,
      confirm: l.notifAllow,
      cancel: l.notifDeny,
      icon: AppIconName.calendar,
    );
    app.profile.notificationAsked = true;
    unawaited(app.saveProfile());
    if (yes) {
      await app.enableNotifications(
        ReminderTexts(
          dailyTitle: l.notifDailyTitle,
          dailyBody: l.notifDailyBody,
          streakTitle: l.notifStreakTitle,
          streakBody: l.notifStreakBody,
        ),
      );
    }
  }

  void _measure() {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (c.geometry?.rect != rect) c.geometry = BoardGeometry(rect);
    for (var i = 0; i < 3; i++) {
      final b = _slotKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (b != null && b.hasSize) c.slotCenters[i] = b.localToGlobal(b.size.center(Offset.zero));
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _lifecycle.dispose();
    c
      ..removeListener(_onChange)
      ..dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ actions

  Future<void> _pickLetter() async {
    _letterSheetOpen = true;
    final l = L10n.of(context);
    final letter = await showGameSheet<String>(
      context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.s4, 0, Space.s4, Space.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.jokerPickLetter, style: ctx.text.headlineSmall),
              const SizedBox(height: Space.s3),
              Wrap(
                spacing: Space.s2,
                runSpacing: Space.s2,
                alignment: WrapAlignment.center,
                children: [
                  for (final letter in TrAlphabet.all)
                    Semantics(
                      button: true,
                      label: letter,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(Radii.sm),
                        onTap: () => Navigator.pop(ctx, letter),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: ctx.palette.tile,
                            borderRadius: BorderRadius.circular(Radii.sm),
                            border: Border.all(color: ctx.palette.tileEdge),
                          ),
                          child: Text(
                            letter,
                            style: ctx.text.headlineSmall!.copyWith(color: ctx.palette.tileInk),
                            textScaler: TextScaler.noScaling,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    _letterSheetOpen = false;
    c.chooseJokerLetter(letter);
  }

  Future<void> _pause() async {
    c.cancelDrag();
    final l = L10n.of(context);
    final app = AppScope.read(context);
    final action = await showPauseSheet(context, state: c.state);
    if (!mounted) return;
    if (action == PauseAction.menu) {
      Navigator.of(context).pop();
    } else if (action == PauseAction.restart) {
      final ok = await showConfirmSheet(
        context,
        title: l.restartConfirmTitle,
        body: l.restartConfirmBody,
        confirm: l.restart,
        cancel: l.cancel,
        icon: AppIconName.powerupRefresh,
      );
      if (ok && mounted) c.reset(app.newClassicGame());
    }
  }

  Future<void> _playAgain() async {
    final app = AppScope.read(context);
    await c.leaveFinishedGame();
    if (!mounted) return;
    c.reset(app.newClassicGame());
  }

  Future<void> _home() async {
    await c.leaveFinishedGame();
    if (mounted) Navigator.of(context).pop();
  }

  // ------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final p = context.palette;
    final app = AppScope.of(context);
    final left = app.settings.leftHanded;
    return PopScope(
      canPop: c.phase != UiPhase.resolving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) unawaited(c.leaveFinishedGame());
      },
      child: Scaffold(
        backgroundColor: p.background,
        body: Stack(
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (context, box) {
                  final width = math.min(box.maxWidth - 2 * Space.screenGutter, 560.0);
                  final boardSize = math.min(width, box.maxHeight * 0.56);
                  // Hand tray sits in the thumb zone; it takes spare height on tall phones.
                  final trayHeight = math.max(boardSize * 0.4, math.min(box.maxHeight * 0.19, 188.0));
                  return Center(
                    child: SizedBox(
                      width: math.max(boardSize, math.min(width, 560)),
                      child: Column(
                        children: [
                          _Hud(controller: c, leftHanded: left, onPause: _pause),
                          const Spacer(flex: 2),
                          SizedBox.square(
                            dimension: boardSize,
                            child: BoardView(controller: c, renderer: _renderer!, boardKey: _boardKey),
                          ),
                          const SizedBox(height: Space.s4),
                          _PowerupBar(controller: c, leftHanded: left),
                          const Spacer(),
                          Container(
                            height: trayHeight,
                            decoration: BoxDecoration(
                              color: p.surface.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(Radii.xl + 4),
                              border: Border.all(color: p.divider.withValues(alpha: 0.7)),
                            ),
                            child: Row(
                              children: [
                                for (var i = 0; i < 3; i++)
                                  Expanded(
                                    child: HandSlot(key: _slotKeys[i], controller: c, index: i, renderer: _renderer!),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: Space.s3),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned.fill(
              child: DragOverlay(controller: c, renderer: _renderer!),
            ),
            for (final fx in _fx)
              Positioned.fill(
                key: ValueKey(fx.id),
                child: IgnorePointer(
                  child: Align(
                    alignment: const Alignment(0, -0.18),
                    child: SpriteAnim(
                      fx.asset,
                      size: 340,
                      onDone: () {
                        if (mounted) setState(() => _fx.removeWhere((e) => e.id == fx.id));
                      },
                    ),
                  ),
                ),
              ),
            if (c.phase == UiPhase.pickHammerCell || c.phase == UiPhase.pickJokerCell)
              _Hint(
                text: c.phase == UiPhase.pickHammerCell
                    ? L10n.of(context).hammerPickCell
                    : L10n.of(context).jokerPickCell,
              ),
            if (c.phase == UiPhase.stuck) _StuckPanel(controller: c),
            if (c.phase == UiPhase.over)
              _GameOverPanel(controller: c, onPlayAgain: _playAgain, onHome: _home, shareKey: _shareKey),
            if (c.phase == UiPhase.over && (c.endResult?.newRecord ?? false))
              const Positioned.fill(child: Celebration()),
          ],
        ),
      ),
    );
  }
}

typedef AppSettingsUpdate = AppSettings Function(bool v);

class _Hud extends StatelessWidget {
  const _Hud({required this.controller, required this.leftHanded, required this.onPause});
  final GameController controller;
  final bool leftHanded;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = AppScope.of(context);
    final s = controller.state;
    final pause = IconBtn(icon: AppIconName.pause, label: l.pause, onPressed: onPause);
    final streak10 = s.streak == 0 ? 10 : math.min(10 + s.streak - 1, 20);
    final side = s.mode == GameMode.daily
        ? InfoChip(
            icon: AppIconName.calendar,
            text: l.handOf(math.min(s.handCounter, app.data!.config.dailyHandLimit), app.data!.config.dailyHandLimit),
          )
        : AnimatedOpacity(
            duration: Motion.pick,
            opacity: s.streak >= 2 ? 1 : 0,
            child: InfoChip(
              icon: AppIconName.streak,
              text: l.streakMultiplier((streak10 / 10).toStringAsFixed(1).replaceAll('.', ',')),
              highlight: s.streak >= 5,
            ),
          );
    final score = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<int>(
          valueListenable: controller.frame,
          builder: (context, _, _) {
            final v = controller.displayedScore.round();
            return Semantics(
              liveRegion: true,
              label: l.a11yScore(s.score),
              excludeSemantics: true,
              child: Text(
                '$v',
                style: TypeScale.score.copyWith(color: context.palette.ink, fontFamily: appFontFamily),
              ),
            );
          },
        ),
        if (s.mode == GameMode.classic)
          Text('${l.best} ${math.max(app.profile.bestScore, s.score)}', style: context.text.bodySmall),
      ],
    );
    final children = <Widget>[
      SizedBox(
        width: 104,
        child: Align(alignment: Alignment.centerLeft, child: leftHanded ? pause : side),
      ),
      Expanded(child: score),
      SizedBox(
        width: 104,
        child: Align(alignment: Alignment.centerRight, child: leftHanded ? side : pause),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.s1, Space.s2, Space.s1, 0),
      child: Row(children: children),
    );
  }
}

class _PowerupBar extends StatelessWidget {
  const _PowerupBar({required this.controller, required this.leftHanded});
  final GameController controller;
  final bool leftHanded;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final s = controller.state;
    if (s.mode == GameMode.daily) {
      return SizedBox(
        height: 84,
        child: Center(
          child: Text(l.dailyRules, textAlign: TextAlign.center, style: context.text.bodySmall),
        ),
      );
    }
    final p = context.palette;
    Widget btn(PowerupType t, AppIconName icon) {
      final n = s.powerup(t);
      final active =
          (t == PowerupType.joker && controller.phase == UiPhase.pickJokerCell) ||
          (t == PowerupType.hammer && controller.phase == UiPhase.pickHammerCell);
      final empty = n == 0;
      final fg = active ? p.onAccent : (empty ? p.inkMuted : p.accent);
      return Semantics(
        button: true,
        selected: active,
        label: l.a11yPowerup(powerupName(l, t), n),
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            tapFeedback(context);
            controller.tapPowerup(t);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: Motion.pick,
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active ? p.accent : p.surface,
                        borderRadius: BorderRadius.circular(Radii.md + 2),
                        border: Border.all(color: active ? p.accent : p.divider, width: 1.2),
                      ),
                      child: Opacity(
                        opacity: empty && !active ? 0.55 : 1,
                        child: Image.asset(
                          AssetPaths.powerupArtwork(icon),
                          width: 38,
                          height: 38,
                          excludeFromSemantics: true,
                          errorBuilder: (_, _, _) => AppIcon(icon, size: 28, color: fg),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: AnimatedContainer(
                        duration: Motion.pick,
                        constraints: const BoxConstraints(minWidth: 22),
                        height: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: empty ? p.surfaceAlt : p.ink,
                          borderRadius: BorderRadius.circular(Radii.pill),
                          border: Border.all(color: p.background, width: 2),
                        ),
                        child: Text(
                          '$n',
                          textScaler: TextScaler.noScaling,
                          style: context.text.bodySmall!.copyWith(
                            color: empty ? p.inkMuted : p.background,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.s1 + 2),
                Text(
                  powerupName(l, t),
                  textScaler: TextScaler.noScaling,
                  style: context.text.bodySmall!.copyWith(
                    color: active ? p.accent : p.inkMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 84,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: leftHanded ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          btn(PowerupType.refresh, AppIconName.powerupRefresh),
          btn(PowerupType.joker, AppIconName.powerupJoker),
          btn(PowerupType.hammer, AppIconName.powerupHammer),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Positioned(
    left: Space.s4,
    right: Space.s4,
    top: MediaQuery.paddingOf(context).top + 72,
    child: IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s2),
          decoration: BoxDecoration(color: context.palette.ink, borderRadius: BorderRadius.circular(Radii.pill)),
          child: Text(text, style: context.text.labelLarge!.copyWith(color: context.palette.background)),
        ),
      ),
    ),
  );
}

/// Bottom sheet-like overlay; keeps the board visible above.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Motion.screen,
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: p.background.withValues(alpha: 0.55 * t)),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionalTranslation(
                translation: Offset(0, context.reduceMotion ? 0 : (1 - t) * 0.3),
                child: Opacity(opacity: t, child: child),
              ),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(Space.s3),
            padding: const EdgeInsets.fromLTRB(Space.s5, Space.s6, Space.s5, Space.s5),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(Radii.xl)),
            child: SafeArea(top: false, child: child),
          ),
        ),
      ),
    );
  }
}

class _StuckPanel extends StatelessWidget {
  const _StuckPanel({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final s = controller.state;
    Widget use(PowerupType t, AppIconName icon, String desc) => Padding(
      padding: const EdgeInsets.only(bottom: Space.s2),
      child: SecondaryButton(
        label: '${powerupName(l, t)} · ${s.powerup(t)}',
        icon: icon,
        onPressed: s.powerup(t) > 0 ? () => controller.tapPowerup(t) : null,
      ),
    );
    return _Sheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.stuckTitle, textAlign: TextAlign.center, style: context.text.titleLarge),
          const SizedBox(height: Space.s1),
          Text(l.stuckBody, textAlign: TextAlign.center, style: context.text.bodySmall),
          const SizedBox(height: Space.s4),
          use(PowerupType.refresh, AppIconName.powerupRefresh, l.powerupRefreshDesc),
          use(PowerupType.hammer, AppIconName.powerupHammer, l.powerupHammerDesc),
          use(PowerupType.joker, AppIconName.powerupJoker, l.powerupJokerDesc),
          const SizedBox(height: Space.s2),
          TextButton(onPressed: controller.endGame, child: Text(l.endGame)),
        ],
      ),
    );
  }
}

class _GameOverPanel extends StatelessWidget {
  const _GameOverPanel({
    required this.controller,
    required this.onPlayAgain,
    required this.onHome,
    required this.shareKey,
  });
  final GameController controller;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;
  final GlobalKey shareKey;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final p = context.palette;
    final app = AppScope.of(context);
    final s = controller.state;
    final r = controller.endResult;
    final daily = s.mode == GameMode.daily;
    final record = r?.newRecord ?? false;

    // Only what this game earned, at most two short lines.
    final earned = <String>[
      for (final rw in r?.rewards ?? const <Reward>[])
        switch (rw) {
          LevelUpReward(:final level) => l.levelUp(level),
          MissionReward(:final mission) => '${l.missionCompleted}: ${missionText(l, mission)}',
          StreakBadgeReward(:final days) => l.streakBadge(days),
        },
      if (r != null && r.newWords > 0) l.newWordsAdded(r.newWords),
    ];

    final title = daily ? l.dailyComplete : (record ? l.newRecord : l.gameOver);
    return _Sheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            TurkishText.toUpper(title),
            textAlign: TextAlign.center,
            style: context.text.bodySmall!.copyWith(
              letterSpacing: 1.6,
              fontWeight: FontWeight.w800,
              color: record ? p.accent : p.inkMuted,
            ),
          ),
          const SizedBox(height: Space.s2),
          if (daily && r?.dailyResult != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: RepaintBoundary(
                key: shareKey,
                child: DailyShareCard(day: controller.dailyDay!, result: r!.dailyResult!),
              ),
            )
          else ...[
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: s.score.toDouble()),
              duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => Text(
                '${v.round()}',
                textAlign: TextAlign.center,
                style: TypeScale.display.copyWith(color: p.ink, fontSize: 64, fontFamily: appFontFamily, height: 1),
              ),
            ),
            if (!record) ...[
              const SizedBox(height: Space.s1),
              Text(
                l.bestChip(math.max(app.profile.bestScore, s.score)),
                textAlign: TextAlign.center,
                style: context.text.bodySmall,
              ),
            ],
          ],
          const SizedBox(height: Space.s5),
          Container(
            padding: const EdgeInsets.symmetric(vertical: Space.s3),
            decoration: BoxDecoration(
              border: Border.symmetric(horizontal: BorderSide(color: p.divider)),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _Mini(label: l.wordsBuilt, value: '${s.wordCount}'),
                  VerticalDivider(color: p.divider, width: 1),
                  _Mini(label: l.bestWord, value: s.bestWord.isEmpty ? l.dash : s.bestWord),
                  VerticalDivider(color: p.divider, width: 1),
                  _Mini(label: 'XP', value: '+${r?.xpGained ?? 0}'),
                ],
              ),
            ),
          ),
          if (earned.isNotEmpty) ...[
            const SizedBox(height: Space.s3),
            for (final line in earned.take(2))
              Padding(
                padding: const EdgeInsets.only(top: Space.s1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcon(AppIconName.check, size: 15, color: p.accent),
                    const SizedBox(width: Space.s2),
                    Flexible(
                      child: Text(
                        line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall!.copyWith(color: p.ink),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (!daily && r != null) ...[
            const SizedBox(height: Space.s4),
            _NextGoalRow(
              NextGoal.pick(
                score: s.score,
                best: app.profile.bestScore,
                missions: r.missionsAfter,
                totalXp: app.profile.totalXp,
              ),
            ),
          ],
          const SizedBox(height: Space.s5),
          if (daily) ...[
            if (r?.dailyResult != null)
              PrimaryButton(
                label: l.share,
                icon: AppIconName.share,
                onPressed: () => Sharing.shareDaily(context, shareKey, controller.dailyDay!, r!.dailyResult!),
              ),
            const SizedBox(height: Space.s2),
            Center(
              child: _LinkButton(icon: AppIconName.home, label: l.mainMenu, onTap: onHome),
            ),
          ] else ...[
            PrimaryButton(label: l.playAgain, onPressed: onPlayAgain),
            if (controller.canContinue && (app.services.ads.supported || app.profile.adsRemoved)) ...[
              const SizedBox(height: Space.s2),
              _ContinueButton(
                title: app.profile.adsRemoved ? l.continueFree : l.continueWithAd,
                subtitle: l.continueHint,
                onTap: controller.continueGame,
              ),
            ],
            const SizedBox(height: Space.s3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LinkButton(icon: AppIconName.home, label: l.mainMenu, onTap: onHome),
                const SizedBox(width: Space.s6),
                _LinkButton(
                  icon: AppIconName.share,
                  label: l.share,
                  onTap: () => Sharing.shareScore(context, s.score, s.wordCount),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One line that points at the closest goal (record, mission or level), so
/// "play again" has a reason attached.
class _NextGoalRow extends StatelessWidget {
  const _NextGoalRow(this.goal);
  final NextGoal goal;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final p = context.palette;
    final (icon, text) = switch (goal) {
      RecordGoal(:final pointsLeft) => (AppIconName.crown, l.nextGoalRecord(pointsLeft)),
      MissionGoal(:final mission) => (AppIconName.missions, l.nextGoalMission(missionText(l, mission))),
      LevelGoal(:final nextLevel, :final xpLeft) => (AppIconName.star, l.nextGoalLevel(nextLevel, xpLeft)),
    };
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(icon, size: 15, color: p.accent),
              const SizedBox(width: Space.s2),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall!.copyWith(color: p.ink, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.s2),
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.pill),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(color: p.surfaceAlt),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: goal.fraction.clamp(0.0, 1.0)),
                    duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, f, _) => FractionallySizedBox(
                      widthFactor: f,
                      child: Container(color: p.accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: context.text.headlineSmall!.copyWith(fontSize: 19),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(label, style: context.text.bodySmall!.copyWith(fontSize: 12), textAlign: TextAlign.center),
      ],
    ),
  );
}

/// Outlined two-line button: action + small explanation.
class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.title, required this.subtitle, required this.onTap});
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: p.divider, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.lg),
          onTap: () {
            tapFeedback(context);
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
            child: Column(
              children: [
                Text(title, style: context.text.labelLarge),
                const SizedBox(height: 2),
                Text(subtitle, textAlign: TextAlign.center, style: context.text.bodySmall!.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.icon, required this.label, required this.onTap});
  final AppIconName icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: () {
          tapFeedback(context);
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: Space.s3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(icon, size: 18, color: p.inkMuted),
              const SizedBox(width: Space.s2),
              Text(label, style: context.text.labelLarge!.copyWith(color: p.inkMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
