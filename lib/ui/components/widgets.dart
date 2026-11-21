import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_model.dart';
import '../../config/app_info.dart';
import '../../config/asset_paths.dart';
import '../../core/model/game_state.dart';
import '../../core/text/turkish_text.dart';
import '../../l10n/app_localizations.dart';
import '../../services/haptics_service.dart';
import '../../core/config/balance_config.dart';
import '../game/tile_renderer.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'app_icon.dart';

void tapFeedback(BuildContext context) {
  final app = AppScope.read(context);
  app.services.haptics.play(HapticKind.button);
  app.services.audio.play(SoundId.button);
}

/// The one main action of a screen.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon, this.trailing});

  final String label;
  final VoidCallback? onPressed;
  final AppIconName? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: _Pressable(
        onTap: enabled
            ? () {
                tapFeedback(context);
                onPressed!();
              }
            : null,
        child: AnimatedOpacity(
          duration: Motion.pick,
          opacity: enabled ? 1 : 0.45,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: Space.s6, vertical: Space.s3),
            decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Radii.lg)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[AppIcon(icon!, color: p.onAccent, size: 22), const SizedBox(width: Space.s2)],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: context.text.labelLarge!.copyWith(color: p.onAccent, fontSize: 18),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: Space.s2), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary action: outlined, same height.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed, this.icon, this.trailing});

  final String label;
  final VoidCallback? onPressed;
  final AppIconName? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: _Pressable(
        onTap: enabled
            ? () {
                tapFeedback(context);
                onPressed!();
              }
            : null,
        child: AnimatedOpacity(
          duration: Motion.pick,
          opacity: enabled ? 1 : 0.45,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: Space.s5, vertical: Space.s3),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(color: p.divider, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[AppIcon(icon!, color: p.ink, size: 20), const SizedBox(width: Space.s2)],
                Flexible(
                  child: Text(label, textAlign: TextAlign.center, style: context.text.labelLarge),
                ),
                if (trailing != null) ...[const SizedBox(width: Space.s2), trailing!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 44x44 minimum icon button.
class IconBtn extends StatelessWidget {
  const IconBtn({super.key, required this.icon, required this.label, required this.onPressed, this.color, this.badge});

  final AppIconName icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: _Pressable(
        onTap: onPressed == null
            ? null
            : () {
                tapFeedback(context);
                onPressed!();
              },
        child: SizedBox.square(
          dimension: Space.touch + Space.s1,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              AppIcon(icon, color: color ?? context.palette.ink, size: 24),
              if (badge != null) Positioned(right: 2, top: 2, child: badge!),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scale-down-on-press feedback without ripple clutter.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down && !context.reduceMotion ? 0.96 : 1,
        duration: Motion.pick,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Standard screen frame: background, safe area, centred max width, header.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    required this.child,
    this.actions = const [],
    this.showBack = true,
    this.scroll = true,
  });

  final String? title;
  final Widget child;
  final List<Widget> actions;
  final bool showBack;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.screenGutter),
          child: child,
        ),
      ),
    );
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: Column(
          children: [
            if (title != null || showBack)
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.s2, Space.s2, Space.s2, 0),
                child: Row(
                  children: [
                    if (showBack)
                      IconBtn(icon: AppIconName.back, label: l.back, onPressed: () => Navigator.of(context).maybePop())
                    else
                      const SizedBox(width: Space.touch),
                    Expanded(
                      child: Text(
                        title ?? '',
                        textAlign: TextAlign.center,
                        style: context.text.headlineSmall,
                        semanticsLabel: title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (actions.isEmpty) const SizedBox(width: Space.touch) else ...actions,
                  ],
                ),
              ),
            Expanded(
              child: scroll
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.only(top: Space.s1, bottom: Space.s6),
                      child: body,
                    )
                  : body,
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded surface card.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(Space.s4), this.color});
  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(color: color ?? p.surface, borderRadius: BorderRadius.circular(Radii.lg)),
      child: child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.s1, Space.s6, Space.s1, Space.s2),
    child: Semantics(
      header: true,
      child: Text(
        TurkishText.toUpper(text),
        style: context.text.bodySmall!.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.height = 8});
  final double value;
  final double height;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.pill),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: p.surfaceAlt),
            FractionallySizedBox(
              widthFactor: value.clamp(0, 1),
              child: Container(color: p.accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip with icon + text.
class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.icon, required this.text, this.highlight = false});
  final AppIconName icon;
  final String text;
  final bool highlight;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = highlight ? p.onAccent : p.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: Space.s1 + 2),
      decoration: BoxDecoration(
        color: highlight ? p.accent : p.accentSoft,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 16, color: fg),
          const SizedBox(width: Space.s1),
          Text(
            text,
            style: context.text.bodySmall!.copyWith(color: fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Logo: delivered SVG, or the placeholder built from real game tiles
/// ("HARF" ivory, "TAŞ" accent) that drop in one by one.
class Logo extends StatelessWidget {
  const Logo({super.key, this.height = 72, this.animate = false});
  final double height;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final path = dark ? AssetPaths.logoDark : AssetPaths.logoLight;
    if (AssetIndex.has(path)) {
      return SvgPicture.asset(path, height: height, semanticsLabel: AppInfo.displayName);
    }
    final p = context.palette;
    final style = context.appTheme.tileStyle;
    final scores = BalanceConfig.defaults.letterScores;
    final renderers = [
      TileRenderer(palette: p, style: style, scores: scores),
      TileRenderer(palette: p.accentTiles, style: style, scores: scores),
    ];
    final tile = height * 0.5;
    final gap = tile * 0.1;
    final move = animate && !context.reduceMotion;
    var index = 0;
    return Semantics(
      label: AppInfo.displayName,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row = 0; row < AppInfo.logoLines.length; row++)
            Padding(
              padding: EdgeInsets.only(top: row == 0 ? 0 : gap),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final ch in AppInfo.logoLines[row].split(''))
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: gap / 2),
                      child: _LogoTile(
                        letter: ch,
                        size: tile,
                        renderer: renderers[row % 2],
                        delay: move ? index++ * 70 : -1,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LogoTile extends StatelessWidget {
  const _LogoTile({required this.letter, required this.size, required this.renderer, required this.delay});
  final String letter;
  final double size;
  final TileRenderer renderer;

  /// Entrance delay in ms; -1 = no animation.
  final int delay;

  @override
  Widget build(BuildContext context) {
    final tile = CustomPaint(size: Size.square(size), painter: _TilePainter(renderer, letter));
    if (delay < 0) return tile;
    final total = 420 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutBack),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, (1 - t) * -size * 0.6), child: child),
      ),
      child: tile,
    );
  }
}

class _TilePainter extends CustomPainter {
  _TilePainter(this.renderer, this.letter);
  final TileRenderer renderer;
  final String letter;
  @override
  void paint(Canvas canvas, Size size) => renderer.draw(canvas, Offset.zero & size, letter: letter);
  @override
  bool shouldRepaint(_TilePainter old) => old.letter != letter || old.renderer != renderer;
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.text, this.asset, this.icon = AppIconName.info, this.action});
  final String text;
  final String? asset;
  final AppIconName icon;

  /// Optional call to action under the text (e.g. "Oyna").
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.s10, horizontal: Space.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (asset != null && AssetIndex.has(asset!))
            SvgPicture.asset(asset!, height: 120)
          else
            AppIcon(icon, size: 56, color: p.accent),
          const SizedBox(height: Space.s5),
          Text(
            text,
            textAlign: TextAlign.center,
            style: context.text.bodyLarge!.copyWith(color: p.inkMuted, height: 1.45),
          ),
          if (action != null) ...[const SizedBox(height: Space.s6), SizedBox(width: 220, child: action)],
        ],
      ),
    );
  }
}

/// Settings-style row with optional trailing widget.
class ListRow extends StatelessWidget {
  const ListRow({super.key, required this.title, this.subtitle, this.trailing, this.onTap, this.icon});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final AppIconName? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              tapFeedback(context);
              onTap!();
            },
      borderRadius: BorderRadius.circular(Radii.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: Space.s2),
          child: Row(
            children: [
              if (icon != null) ...[AppIcon(icon!, color: p.inkMuted, size: 22), const SizedBox(width: Space.s3)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.bodyLarge),
                    if (subtitle != null) Text(subtitle!, style: context.text.bodySmall),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// One distinct colour per powerup so they read apart at a glance.
Color powerupColor(BuildContext context, PowerupType type) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (type) {
    PowerupType.refresh => context.palette.accent,
    PowerupType.joker => dark ? const Color(0xFFB9A4F7) : const Color(0xFF6B4FC8),
    PowerupType.hammer => dark ? const Color(0xFFF2B35B) : const Color(0xFFB4690E),
  };
}

AppIconName powerupIcon(PowerupType type) => switch (type) {
  PowerupType.refresh => AppIconName.powerupRefresh,
  PowerupType.joker => AppIconName.powerupJoker,
  PowerupType.hammer => AppIconName.powerupHammer,
};

String powerupName(L10n l, PowerupType type) => switch (type) {
  PowerupType.refresh => l.powerupRefresh,
  PowerupType.joker => l.powerupJoker,
  PowerupType.hammer => l.powerupHammer,
};
