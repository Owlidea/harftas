import 'package:material_ui/material_ui.dart';

import '../../app/app_model.dart';
import '../../config/app_info.dart';
import '../../config/asset_paths.dart';
import '../../core/model/game_state.dart';
import '../../core/text/turkish_text.dart';
import '../../l10n/app_localizations.dart';
import '../../services/ads_service.dart';
import '../../services/purchase_service.dart';
import '../components/app_icon.dart';
import '../components/overlays.dart';
import '../components/widgets.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

/// Purchase page (spec 9/12): flat, calm, honest — no timers, no fake
/// discounts, no shadows.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});
  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  late Future<List<StoreProduct>> _products;
  String? _busy;

  @override
  void initState() {
    super.initState();
    _products = AppScope.read(context).services.purchases.products();
  }

  Future<void> _buy(String id) async {
    setState(() => _busy = id);
    final app = AppScope.read(context);
    final ok = await app.services.purchases.buy(id);
    if (!mounted) return;
    setState(() => _busy = null);
    if (ok) {
      showGameToast(context, L10n.of(context).purchaseThanks, icon: AppIconName.crown);
    }
  }

  Future<void> _earn() async {
    final app = AppScope.read(context);
    final l = L10n.of(context);
    // Gift the type the player has fewest of.
    final t = PowerupType.values.reduce(
      (a, b) => (app.profile.powerups[a] ?? 0) <= (app.profile.powerups[b] ?? 0) ? a : b,
    );
    if (await app.watchRewarded(RewardPlacement.earnPowerup)) {
      app.addPowerup(t);
      if (mounted) {
        showGameToast(context, l.earnedPowerup(powerupName(l, t)), icon: AppIconName.gift);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = AppScope.of(context);
    final p = context.palette;

    return AppScaffold(
      title: l.storeTitle,
      child: FutureBuilder<List<StoreProduct>>(
        future: _products,
        builder: (context, snap) {
          final loading = snap.connectionState != ConnectionState.done;
          final products = snap.data ?? const <StoreProduct>[];
          String? price(String id) => products.where((x) => x.id == id).firstOrNull?.price;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Space.s4),
              _Inventory(powerups: app.profile.powerups),
              const SizedBox(height: Space.s5),

              if (!app.services.purchases.supported) ...[
                _MobileOnlyNote(text: l.storeMobileOnly),
                if (app.services.ads.supported) ...[
                  const SizedBox(height: Space.s3),
                  _FreeRow(subtitle: l.freeSubAd, onTap: _earn),
                ],
              ] else ...[
                // ---------------------------------------------- featured
                _RemoveAdsCard(
                  owned: app.profile.adsRemoved,
                  price: price(AppInfo.productRemoveAds),
                  busy: _busy == AppInfo.productRemoveAds,
                  loading: loading,
                  onBuy: () => _buy(AppInfo.productRemoveAds),
                ),

                // ---------------------------------------------- packs
                SectionHeader(l.packsTitle),
                if (!loading && products.isEmpty)
                  EmptyState(text: l.storeUnavailable, icon: AppIconName.store)
                else
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _PackCard(
                            title: l.packSmallShort,
                            each: AppInfo.powerupsSmallAmount,
                            price: price(AppInfo.productPowerupsSmall),
                            busy: _busy == AppInfo.productPowerupsSmall,
                            onBuy: () => _buy(AppInfo.productPowerupsSmall),
                          ),
                        ),
                        const SizedBox(width: Space.s3),
                        Expanded(
                          child: _PackCard(
                            title: l.packLargeShort,
                            each: AppInfo.powerupsLargeAmount,
                            price: price(AppInfo.productPowerupsLarge),
                            busy: _busy == AppInfo.productPowerupsLarge,
                            tag: l.packLargestTag,
                            onBuy: () => _buy(AppInfo.productPowerupsLarge),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: Space.s3),

                // ---------------------------------------------- free
                _FreeRow(subtitle: app.profile.adsRemoved ? l.freeSubNoAds : l.freeSubAd, onTap: _earn),

                const SizedBox(height: Space.s6),
                Center(
                  child: TextButton(onPressed: app.services.purchases.restore, child: Text(l.restorePurchases)),
                ),
              ],
              if (app.services.purchases.supported) ...[
                const SizedBox(height: Space.s1),
                Text(
                  l.storeFootnote,
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall!.copyWith(color: p.inkMuted, fontSize: 12),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Shown instead of the purchase cards where no store exists (web).
class _MobileOnlyNote extends StatelessWidget {
  const _MobileOnlyNote({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(Space.s5),
      decoration: _flat(p),
      child: Column(
        children: [
          ArtIcon(AppIconName.crown, size: 32, artScale: 1.5, color: _Gold.of(context)),
          const SizedBox(height: Space.s3),
          Text(text, textAlign: TextAlign.center, style: context.text.bodyLarge),
        ],
      ),
    );
  }
}

/// Flat surface with a hairline border (no shadow).
BoxDecoration _flat(Palette p, {Color? border, double width = 1, Color? color}) => BoxDecoration(
  color: color ?? p.surface,
  borderRadius: BorderRadius.circular(Radii.xl),
  border: Border.all(color: border ?? p.divider, width: width),
);

/// Premium palette for the "remove ads" card: deep navy + gold, in both themes.
abstract final class _Gold {
  static const Color light = Color(0xFFE9B949);
  static const Color soft = Color(0xFFF6DFA4);
  static const Color navyTop = Color(0xFF233259);
  static const Color navyBottom = Color(0xFF131C33);
  static Color of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? light : const Color(0xFFB07D12);
}

class _Inventory extends StatelessWidget {
  const _Inventory({required this.powerups});
  final Map<PowerupType, int> powerups;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final p = context.palette;
    Widget item(PowerupType t) {
      final c = powerupColor(context, t);
      return Expanded(
        child: Semantics(
          label: l.a11yPowerup(powerupName(l, t), powerups[t] ?? 0),
          excludeSemantics: true,
          child: Column(
            children: [
              AppIcon(powerupIcon(t), size: 32, color: c),
              const SizedBox(height: Space.s2),
              Text('${powerups[t] ?? 0}', style: context.text.titleLarge!.copyWith(height: 1, fontSize: 24)),
              const SizedBox(height: 2),
              Text(
                powerupName(l, t),
                style: context.text.bodySmall!.copyWith(color: c, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: Space.s4),
      decoration: _flat(p),
      child: Column(
        children: [
          Text(
            TurkishText.toUpper(l.yourPowerups),
            style: context.text.bodySmall!.copyWith(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              color: p.inkMuted,
            ),
          ),
          const SizedBox(height: Space.s4),
          Row(
            children: [
              item(PowerupType.refresh),
              Container(width: 1, height: 64, color: p.divider),
              item(PowerupType.joker),
              Container(width: 1, height: 64, color: p.divider),
              item(PowerupType.hammer),
            ],
          ),
        ],
      ),
    );
  }
}

class _RemoveAdsCard extends StatelessWidget {
  const _RemoveAdsCard({
    required this.owned,
    required this.price,
    required this.busy,
    required this.loading,
    required this.onBuy,
  });
  final bool owned;
  final String? price;
  final bool busy;
  final bool loading;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    const white = Colors.white;
    Widget benefit(String text) => Padding(
      padding: const EdgeInsets.only(top: Space.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: AppIcon(AppIconName.check, size: 18, color: _Gold.light),
          ),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Text(
              text,
              style: context.text.bodyLarge!.copyWith(fontSize: 15, color: white.withValues(alpha: 0.92)),
            ),
          ),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.xl),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_Gold.navyTop, _Gold.navyBottom],
          ),
          borderRadius: BorderRadius.circular(Radii.xl),
          border: Border.all(color: _Gold.light.withValues(alpha: 0.45)),
        ),
        child: Stack(
          children: [
            // Oversized watermark crown.
            Positioned(
              right: -28,
              top: -18,
              child: AppIcon(AppIconName.crown, size: 150, color: _Gold.light.withValues(alpha: 0.06)),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.s5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const ArtIcon(AppIconName.crown, size: 22, artScale: 1.6, color: _Gold.light),
                      const SizedBox(width: Space.s2),
                      Text(
                        TurkishText.toUpper(l.storePremium),
                        style: context.text.bodySmall!.copyWith(
                          color: _Gold.light,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.s3),
                  Text(
                    owned ? l.storeOwnedTitle : l.storeHeroTitle,
                    style: context.text.titleLarge!.copyWith(fontSize: 26, color: white, height: 1.15),
                  ),
                  const SizedBox(height: Space.s1),
                  Text(
                    owned ? l.storeOwnedSub : l.storeHeroSub,
                    style: context.text.bodyLarge!.copyWith(fontSize: 14, color: _Gold.soft.withValues(alpha: 0.85)),
                  ),
                  if (!owned) ...[
                    const SizedBox(height: Space.s2),
                    benefit(l.storeBenefit1),
                    benefit(l.storeBenefit2),
                    benefit(l.storeBenefit3),
                    const SizedBox(height: Space.s5),
                    _BuyButton(
                      label: price == null ? (loading ? '…' : l.buy) : '${l.buy} · $price',
                      busy: busy,
                      color: _Gold.light,
                      ink: _Gold.navyBottom,
                      onTap: price == null ? null : onBuy,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.title,
    required this.each,
    required this.price,
    required this.busy,
    required this.onBuy,
    this.tag,
  });
  final String title;
  final int each;
  final String? price;
  final bool busy;
  final VoidCallback onBuy;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Small pack: theme accent. Large pack: violet, so the two read apart.
    final base = tag != null
        ? (dark ? const Color(0xFF6F55CF) : const Color(0xFF5B3FC0))
        : (dark ? Color.lerp(p.accent, Colors.black, 0.38)! : p.accent);
    final band = [Color.lerp(base, Colors.white, 0.12)!, Color.lerp(base, Colors.black, 0.22)!];
    final onBand = Colors.white;

    return Container(
      decoration: _flat(p, border: tag != null ? base.withValues(alpha: 0.6) : null),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 104,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: band),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: Space.s4,
                  bottom: Space.s3,
                  child: Text(
                    '×${each * 3}',
                    style: context.text.titleLarge!.copyWith(
                      color: onBand,
                      fontSize: 34,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Positioned(
                  left: Space.s4,
                  top: Space.s3,
                  child: Row(
                    children: [
                      for (final t in PowerupType.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: AppIcon(powerupIcon(t), size: 20, color: onBand.withValues(alpha: 0.95)),
                        ),
                    ],
                  ),
                ),
                if (tag != null)
                  Positioned(
                    right: Space.s2,
                    top: Space.s2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Radii.pill)),
                      child: Text(
                        TurkishText.toUpper(tag!),
                        textScaler: TextScaler.noScaling,
                        style: context.text.bodySmall!.copyWith(
                          color: base,
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(Space.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.labelLarge!.copyWith(fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(l.packEachShort(each), style: context.text.bodySmall),
                  const Spacer(),
                  const SizedBox(height: Space.s4),
                  _BuyButton(
                    label: price ?? '…',
                    busy: busy,
                    color: base,
                    ink: Colors.white,
                    onTap: price == null ? null : onBuy,
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

class _FreeRow extends StatelessWidget {
  const _FreeRow({required this.subtitle, required this.onTap});
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final p = context.palette;
    final c = powerupColor(context, PowerupType.hammer); // warm amber
    return Semantics(
      button: true,
      label: '${l.freeTitle}. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: c.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
          side: BorderSide(color: c.withValues(alpha: 0.35)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.xl),
          onTap: () {
            tapFeedback(context);
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(Space.s4),
            child: Row(
              children: [
                ArtIcon(AppIconName.gift, size: 30, artScale: 1.4, color: c),
                const SizedBox(width: Space.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.freeTitle, style: context.text.labelLarge!.copyWith(fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: context.text.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: 6),
                  decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(Radii.pill)),
                  child: Text(
                    AppScope.of(context).profile.adsRemoved ? l.freeCtaNoAds : l.freeCta,
                    style: context.text.labelLarge!.copyWith(color: p.background, fontSize: 13),
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

/// Flat filled buy button (no glow / shadow).
class _BuyButton extends StatelessWidget {
  const _BuyButton({
    required this.label,
    required this.busy,
    required this.color,
    required this.ink,
    required this.onTap,
  });
  final String label;
  final bool busy;
  final Color color;
  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg)),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.lg),
          onTap: enabled
              ? () {
                  tapFeedback(context);
                  onTap!();
                }
              : null,
          child: SizedBox(
            height: 50,
            child: Center(
              child: busy
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: ink))
                  : Text(label, style: context.text.labelLarge!.copyWith(color: ink, fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }
}
