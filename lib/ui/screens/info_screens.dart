import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_model.dart';
import '../../config/app_info.dart';
import '../../l10n/app_localizations.dart';
import '../../config/asset_paths.dart';
import '../../core/text/turkish_text.dart';
import '../components/app_icon.dart';
import '../components/widgets.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return AppScaffold(
      title: l.aboutTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Space.s6),
          const Center(child: Logo(height: 72)),
          const SizedBox(height: Space.s3),
          Text(l.aboutVersion(AppInfo.version), textAlign: TextAlign.center, style: context.text.bodySmall),
          const SizedBox(height: Space.s6),
          Panel(child: Text(l.aboutDictionary, style: context.text.bodyLarge)),
          const SizedBox(height: Space.s4),
          SecondaryButton(
            label: l.aboutLicenses,
            onPressed: () => showLicensePage(
              context: context,
              applicationName: AppInfo.displayName,
              applicationVersion: AppInfo.version,
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = AppScope.of(context);
    final p = context.palette;
    return AppScaffold(
      title: l.privacy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Space.s6),
          const Center(child: _ShieldBadge()),
          const SizedBox(height: Space.s5),
          Text(
            l.privacyHeadline,
            textAlign: TextAlign.center,
            style: context.text.headlineSmall!.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          const SizedBox(height: Space.s2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s6),
            child: Text(
              l.privacyIntro,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium!.copyWith(color: p.inkMuted, height: 1.4),
            ),
          ),
          const SizedBox(height: Space.s8),
          _InfoGroup(
            children: [
              _FactRow(icon: AppIconName.lock, title: l.privacyFactAccountTitle, body: l.privacyFactAccountBody),
              _FactRow(icon: AppIconName.tiles, title: l.privacyFactLocalTitle, body: l.privacyFactLocalBody),
              _FactRow(icon: AppIconName.info, title: l.privacyFactAdsTitle, body: l.privacyFactAdsBody),
              _FactRow(icon: AppIconName.store, title: l.privacyFactPurchasesTitle, body: l.privacyFactPurchasesBody),
            ],
          ),
          const SizedBox(height: Space.s6),
          Padding(
            padding: const EdgeInsets.only(left: Space.s1, bottom: Space.s2),
            child: Text(
              TurkishText.toUpper(l.privacyManage),
              style: context.text.labelSmall!.copyWith(color: p.inkMuted, letterSpacing: 1.2),
            ),
          ),
          FutureBuilder<bool>(
            future: app.services.consent.privacyOptionsRequired,
            builder: (context, snap) => _InfoGroup(
              children: [
                if (snap.data == true)
                  _LinkRow(
                    icon: AppIconName.settings,
                    title: l.privacyOptions,
                    subtitle: l.privacyOptionsSub,
                    onTap: app.services.consent.showPrivacyOptions,
                  ),
                _LinkRow(
                  icon: AppIconName.book,
                  title: l.privacyFullPolicy,
                  subtitle: l.privacyFullPolicySub,
                  external: true,
                  onTap: () => launchUrl(Uri.parse(AppInfo.privacyUrl), mode: LaunchMode.externalApplication),
                ),
                _LinkRow(
                  icon: AppIconName.share,
                  title: l.supportTitle,
                  subtitle: AppInfo.supportEmail,
                  external: true,
                  onTap: () => launchUrl(Uri(scheme: 'mailto', path: AppInfo.supportEmail)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Plain accent lock above the headline.
class _ShieldBadge extends StatelessWidget {
  const _ShieldBadge();

  @override
  Widget build(BuildContext context) =>
      ArtIcon(AppIconName.lock, size: 56, artScale: 1.2, color: context.palette.accent);
}

/// One surface, rows split by inset hairlines.
class _InfoGroup extends StatelessWidget {
  const _InfoGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: p.divider),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, indent: 60, color: p.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip(this.icon);
  final AppIconName icon;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 28, child: AppIcon(icon, size: 22, color: context.palette.accent));
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.icon, required this.title, required this.body});
  final AppIconName icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(Space.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconChip(icon),
          const SizedBox(width: Space.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.bodyLarge!.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body, style: context.text.bodySmall!.copyWith(color: p.inkMuted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.external = false,
  });
  final AppIconName icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool external;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      link: external,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          tapFeedback(context);
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
          child: Row(
            children: [
              _IconChip(icon),
              const SizedBox(width: Space.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.bodyLarge!.copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall!.copyWith(color: p.inkMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.s2),
              Transform.rotate(
                angle: 3.1416, // back chevron turned to point right
                child: AppIcon(AppIconName.back, size: 16, color: p.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
