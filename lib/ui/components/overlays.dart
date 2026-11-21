import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../config/asset_paths.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'app_icon.dart';
import 'widgets.dart';

/// Game-style toast: a pill that drops in under the status bar, stacks
/// nothing (a new one replaces the old) and never blocks touches.
/// Replaces Material snack bars, which read as a desktop/web pattern.
void showGameToast(BuildContext context, String text, {AppIconName icon = AppIconName.check}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _ToastHost.current?.dismiss();
  late final OverlayEntry entry;
  final key = GlobalKey<_ToastState>();
  entry = OverlayEntry(
    builder: (_) => _Toast(key: key, text: text, icon: icon, onDone: () => entry.remove()),
  );
  _ToastHost.current = _ToastHost(key);
  overlay.insert(entry);
}

class _ToastHost {
  _ToastHost(this.key);
  static _ToastHost? current;
  final GlobalKey<_ToastState> key;
  void dismiss() => key.currentState?.hide();
}

class _Toast extends StatefulWidget {
  const _Toast({super.key, required this.text, required this.icon, required this.onDone});
  final String text;
  final AppIconName icon;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: Motion.screen);
  Timer? _timer;
  bool _removed = false;

  @override
  void initState() {
    super.initState();
    _a.forward();
    _timer = Timer(const Duration(milliseconds: 2000), hide);
  }

  void hide() {
    _timer?.cancel();
    if (!mounted) return;
    _a.reverse().whenComplete(_remove);
  }

  void _remove() {
    if (_removed) return;
    _removed = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final top = MediaQuery.paddingOf(context).top + Space.s3;
    return Positioned(
      top: top,
      left: Space.s4,
      right: Space.s4,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _a,
          builder: (context, child) {
            final t = Curves.easeOutBack.transform(_a.value);
            return Opacity(
              opacity: _a.value,
              child: Transform.translate(
                offset: Offset(0, context.reduceMotion ? 0 : (1 - t) * -24),
                child: child,
              ),
            );
          },
          child: Center(
            child: Semantics(
              liveRegion: true,
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
                  padding: const EdgeInsets.fromLTRB(Space.s2, Space.s2, Space.s4, Space.s2),
                  decoration: BoxDecoration(
                    color: p.ink,
                    borderRadius: BorderRadius.circular(Radii.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: Space.s2),
                        child: AppIcon(widget.icon, size: 20, color: p.accent),
                      ),
                      const SizedBox(width: Space.s3),
                      Flexible(
                        child: Text(
                          widget.text,
                          style: context.text.labelLarge!.copyWith(color: p.background),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom confirm sheet with one primary and one quiet action.
/// Replaces AlertDialog, which feels like a system/desktop prompt in a game.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
  required String cancel,
  AppIconName icon = AppIconName.info,
}) async {
  final ok = await showGameSheet<bool>(
    context,
    builder: (ctx) {
      final p = ctx.palette;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: AppIcon(icon, size: 36, color: p.accent)),
          const SizedBox(height: Space.s4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: ctx.text.headlineSmall!.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: Space.s2),
          Text(
            body,
            textAlign: TextAlign.center,
            style: ctx.text.bodyMedium!.copyWith(color: p.inkMuted, height: 1.4),
          ),
          const SizedBox(height: Space.s6),
          PrimaryButton(label: confirm, onPressed: () => Navigator.pop(ctx, true)),
          const SizedBox(height: Space.s3),
          SecondaryButton(label: cancel, onPressed: () => Navigator.pop(ctx, false)),
        ],
      );
    },
  );
  return ok ?? false;
}

/// The one bottom-sheet frame used across the app: rounded top, accent
/// hairline, grab handle, safe-area padding, centred max width.
Future<T?> showGameSheet<T>(BuildContext context, {required WidgetBuilder builder, bool dismissible = true}) {
  final p = context.palette;
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    elevation: 0,
    showDragHandle: false,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    barrierColor: p.background.withValues(alpha: 0.72),
    builder: (ctx) => GameSheetFrame(child: builder(ctx)),
  );
}

class GameSheetFrame extends StatelessWidget {
  const GameSheetFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      constraints: const BoxConstraints(maxWidth: Space.maxContentWidth),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(p.surface, p.accent, 0.06)!, p.surface, Color.lerp(p.surface, p.background, 0.5)!],
          stops: const [0, 0.35, 1],
        ),
        border: Border(top: BorderSide(color: p.accent.withValues(alpha: 0.35))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.s5, Space.s3, Space.s5, Space.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: p.divider, borderRadius: BorderRadius.circular(Radii.pill)),
                ),
              ),
              const SizedBox(height: Space.s5),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    );
  }
}
