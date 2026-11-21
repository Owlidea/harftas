import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../app/app_model.dart';
import '../../config/asset_paths.dart';
import '../../core/core.dart';
import '../../l10n/app_localizations.dart';
import '../components/app_icon.dart';
import '../components/overlays.dart';
import '../components/widgets.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Result of the pause sheet. `null` = resume.
enum PauseAction { restart, menu }

/// Opens the premium pause sheet over the game.
Future<PauseAction?> showPauseSheet(BuildContext context, {required GameState state}) =>
    showGameSheet<PauseAction>(context, builder: (_) => _PauseSheet(state: state));

class _PauseSheet extends StatelessWidget {
  const _PauseSheet({required this.state});
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final p = context.palette;
    final app = AppScope.of(context);
    final s = app.settings;
    final classic = state.mode == GameMode.classic;
    final best = math.max(app.profile.bestScore, state.score);

    var i = 0;
    Widget enter(Widget child) => _Enter(index: i++, child: child);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        enter(_Header(title: l.paused)),
        const SizedBox(height: Space.s5),
        enter(
          _StatsCard(
            items: [
              (l.score, state.score),
              if (classic) (l.best, best) else (l.bestWord, state.bestWordScore),
              (l.wordsBuilt, state.wordCount),
            ],
          ),
        ),
        const SizedBox(height: Space.s5),
        enter(PrimaryButton(label: l.resume, onPressed: () => Navigator.pop(context))),
        const SizedBox(height: Space.s3),
        enter(
          Row(
            children: [
              if (classic) ...[
                Expanded(
                  child: _ActionTile(
                    icon: AppIconName.powerupRefresh,
                    label: l.restart,
                    onTap: () => Navigator.pop(context, PauseAction.restart),
                  ),
                ),
                const SizedBox(width: Space.s3),
              ],
              Expanded(
                child: _ActionTile(
                  icon: AppIconName.home,
                  label: l.mainMenu,
                  onTap: () => Navigator.pop(context, PauseAction.menu),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.s5),
        enter(
          Row(
            children: [
              Expanded(child: Divider(color: p.divider, height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.s3),
                child: AppIcon(AppIconName.settings, size: 14, color: p.inkMuted),
              ),
              Expanded(child: Divider(color: p.divider, height: 1)),
            ],
          ),
        ),
        const SizedBox(height: Space.s4),
        enter(
          Row(
            children: [
              Expanded(
                child: _ToggleTile(
                  icon: AppIconName.sound,
                  label: l.sound,
                  value: s.sound,
                  onChanged: (v) => app.updateSettings(app.settings.copyWith(sound: v), key: 'sound'),
                ),
              ),
              const SizedBox(width: Space.s3),
              Expanded(
                child: _ToggleTile(
                  icon: AppIconName.music,
                  label: l.music,
                  value: s.music,
                  onChanged: (v) => app.updateSettings(app.settings.copyWith(music: v), key: 'music'),
                ),
              ),
              const SizedBox(width: Space.s3),
              Expanded(
                child: _ToggleTile(
                  icon: AppIconName.haptic,
                  label: l.haptics,
                  value: s.haptics,
                  onChanged: (v) => app.updateSettings(app.settings.copyWith(haptics: v), key: 'haptics'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Glowing pause badge + title.
class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        AppIcon(AppIconName.pause, size: 36, color: p.accent),
        const SizedBox(height: Space.s3),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.text.headlineSmall!.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ],
    );
  }
}

/// Three numbers of the current run, split by hairlines.
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.items});
  final List<(String, int)> items;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Space.s4),
      decoration: BoxDecoration(
        color: p.surfaceAlt.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(Radii.lg + 4),
        border: Border.all(color: p.divider),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) VerticalDivider(color: p.divider, width: 1, thickness: 1),
              Expanded(
                child: Semantics(
                  label: '${items[i].$1}: ${items[i].$2}',
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      Text(
                        '${items[i].$2}',
                        style: context.text.headlineSmall!.copyWith(
                          fontWeight: FontWeight.w800,
                          color: i == 0 ? p.accent : p.ink,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        TurkishText.toUpper(items[i].$1),
                        style: context.text.labelSmall!.copyWith(color: p.inkMuted, letterSpacing: 1.1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Secondary action as a soft tile with an icon chip.
class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});
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
      child: _Press(
        onTap: () {
          tapFeedback(context);
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: Space.s3),
          decoration: BoxDecoration(
            color: p.surfaceAlt,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: p.divider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(icon, size: 20, color: p.ink),
              const SizedBox(height: Space.s1 + 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Square on/off tile: lit with the accent when on, dim when off.
class _ToggleTile extends StatelessWidget {
  const _ToggleTile({required this.icon, required this.label, required this.value, required this.onChanged});
  final AppIconName icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const d = Motion.settle;
    return Semantics(
      toggled: value,
      button: true,
      label: label,
      excludeSemantics: true,
      child: _Press(
        onTap: () {
          tapFeedback(context);
          onChanged(!value);
        },
        child: AnimatedContainer(
          duration: d,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: Space.s3, horizontal: Space.s2),
          decoration: BoxDecoration(
            color: value ? p.accentSoft : p.surfaceAlt.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: value ? p.accent.withValues(alpha: 0.6) : p.divider, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedOpacity(
                duration: d,
                opacity: value ? 1 : 0.45,
                child: AppIcon(icon, size: 24, color: value ? p.accent : p.ink),
              ),
              const SizedBox(height: Space.s2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelMedium!.copyWith(color: value ? p.ink : p.inkMuted),
              ),
              const SizedBox(height: Space.s2),
              // Mini switch track: state is shown by position and fill, not colour alone.
              AnimatedContainer(
                duration: d,
                width: 26,
                height: 14,
                padding: const EdgeInsets.all(2),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: value ? p.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(Radii.pill),
                  border: Border.all(color: value ? p.accent : p.inkMuted.withValues(alpha: 0.6)),
                ),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: value ? p.onAccent : p.inkMuted, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Press extends StatefulWidget {
  const _Press({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => setState(() => _down = true),
    onTapCancel: () => setState(() => _down = false),
    onTapUp: (_) => setState(() => _down = false),
    onTap: widget.onTap,
    child: AnimatedScale(
      scale: _down && !context.reduceMotion ? 0.95 : 1,
      duration: Motion.pick,
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// Staggered rise-in for sheet sections.
class _Enter extends StatelessWidget {
  const _Enter({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    final delay = index * 45;
    final total = 320 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 14), child: child),
      ),
      child: child,
    );
  }
}
