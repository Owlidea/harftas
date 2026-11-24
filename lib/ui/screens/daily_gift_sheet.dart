import 'package:material_ui/material_ui.dart';

import '../../app/app_model.dart';
import '../../config/asset_paths.dart';
import '../../core/core.dart';
import '../../l10n/app_localizations.dart';
import '../components/app_icon.dart';
import '../components/overlays.dart';
import '../components/sprite_anim.dart';
import '../components/widgets.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Opens today's free gift and offers a second one for a rewarded ad.
/// Call only when [AppModel.dailyGiftAvailable] is true.
Future<void> showDailyGiftSheet(BuildContext context) =>
    showGameSheet<void>(context, builder: (_) => const _DailyGiftSheet());

class _DailyGiftSheet extends StatefulWidget {
  const _DailyGiftSheet();
  @override
  State<_DailyGiftSheet> createState() => _DailyGiftSheetState();
}

class _DailyGiftSheetState extends State<_DailyGiftSheet> {
  PowerupType? _gift;
  int _count = 0;
  bool _opened = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Opening the gift changes the profile, which notifies the app scope:
    // that must not happen while this sheet is still being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _opened) return;
      final app = AppScope.read(context);
      // The gift is taken the moment the box opens; nothing is lost if the
      // sheet is dismissed mid-animation.
      final gift = app.openDailyGift();
      if (gift != null) app.services.audio.play(SoundId.missionDone);
      setState(() {
        _opened = true;
        _gift = gift;
        _count = gift == null ? 0 : 1;
      });
    });
  }

  Future<void> _double() async {
    final gift = _gift;
    if (gift == null || _busy) return;
    setState(() => _busy = true);
    final ok = await AppScope.read(context).doubleDailyGift(gift);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _count = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final p = context.palette;
    final app = AppScope.of(context);
    final gift = _gift;
    final canDouble = gift != null && _count == 1 && (app.services.ads.supported || app.profile.adsRemoved);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.giftTitle,
          textAlign: TextAlign.center,
          style: context.text.headlineSmall!.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: Space.s2),
        SizedBox(
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // What was inside: appears as the lid comes off.
              if (gift != null)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 1250),
                  curve: const Interval(0.62, 1, curve: Curves.easeOutBack),
                  builder: (_, t, child) => Opacity(
                    opacity: t.clamp(0, 1).toDouble(),
                    child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
                  ),
                  child: Image.asset(
                    AssetPaths.powerupArtwork(powerupIcon(gift)),
                    width: 88,
                    height: 88,
                    filterQuality: FilterQuality.medium,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => AppIcon(powerupIcon(gift), size: 56, color: powerupColor(context, gift)),
                  ),
                ),
              if (SpriteAnim.available(AssetPaths.fxGiftOpen)) const SpriteAnim(AssetPaths.fxGiftOpen, size: 170),
            ],
          ),
        ),
        const SizedBox(height: Space.s2),
        if (gift != null)
          AnimatedSwitcher(
            duration: Motion.settle,
            child: Text(
              l.giftGot(_count, powerupName(l, gift)),
              key: ValueKey(_count),
              textAlign: TextAlign.center,
              style: context.text.titleLarge!.copyWith(fontWeight: FontWeight.w800, color: powerupColor(context, gift)),
            ),
          ),
        const SizedBox(height: Space.s1),
        Text(
          l.giftTomorrow,
          textAlign: TextAlign.center,
          style: context.text.bodySmall!.copyWith(color: p.inkMuted),
        ),
        const SizedBox(height: Space.s5),
        if (canDouble) ...[
          PrimaryButton(
            label: app.profile.adsRemoved ? l.giftDoubleFree : l.giftDoubleAd,
            icon: AppIconName.gift,
            onPressed: _busy ? null : _double,
          ),
          const SizedBox(height: Space.s3),
          SecondaryButton(label: l.ok, onPressed: () => Navigator.pop(context)),
        ] else
          PrimaryButton(label: l.ok, onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}
