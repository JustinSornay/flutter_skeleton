// index.dart
//
// ErrorToastCard — floating feedback banner that surfaces ErrorProvider state.
//
// Renders a coloured card below the header for info, warning, and error
// messages. Auto-dismissed by ErrorProvider's internal timer.
// Manual dismissal via the close icon on the trailing edge.
//
// Single file by exception: trivial logic, no lifecycle.
//
// Colour mapping (theme tokens, not hardcoded):
//   info    → primaryContainer / onPrimaryContainer / primary
//   warning → tertiaryContainer / onTertiaryContainer / tertiary
//   error   → errorContainer / onErrorContainer / error

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/providers/_base/consumer.dart";
import "package:flutter_skeleton/providers/error_provider.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:provider/provider.dart";

/// Floating feedback toast driven by [ErrorProvider].
final class ErrorToastCard extends StatelessWidget {
  const ErrorToastCard({super.key});

  @override
  Widget build(BuildContext context) {
    return renderSelector<ErrorProvider, AppError?>(
      (ErrorProvider p) => p.current,
      (AppError? error) {
        final Widget content = error == null
            ? const SizedBox.shrink(key: ValueKey<String>("empty"))
            : _card(context, error);

        return AnimatedSwitcher(
          duration: resolveMotion(context, kMotionShort),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: content,
        );
      },
    );
  }

  Widget _card(BuildContext context, AppError error) {
    final _ToastColors colors = _ToastColors.fromLevel(error.level, Theme.of(context).colorScheme);

    return Padding(
      key: ValueKey<AppError>(error),
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 2, vertical: kDefaultPadding),
      child: Semantics(
        liveRegion: true,
        child: Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(10),
          color: colors.background,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border(left: BorderSide(color: colors.accent, width: 4)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: kDefaultPadding * 2),
              child: Row(
                children: <Widget>[
                  Icon(_iconForLevel(error.level), size: 18, color: colors.accent),
                  const SizedBox(width: kDefaultPadding),
                  Expanded(
                    child: Text(
                      error.message,
                      style: TextStyle(
                        color: colors.foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // No tooltip: Layout sits above the Navigator, so there is
                  // no Overlay for a Tooltip to attach to.
                  IconButton(
                    onPressed: () => context.read<ErrorProvider>().clear(),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: colors.foreground,
                      semanticLabel: "common.close".tr(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForLevel(AppErrorLevel level) {
    return switch (level) {
      AppErrorLevel.info    => Icons.info_outline_rounded,
      AppErrorLevel.warning => Icons.warning_amber_rounded,
      AppErrorLevel.error   => Icons.error_outline_rounded,
    };
  }
}

final class _ToastColors {
  final Color background;
  final Color foreground;
  final Color accent;

  const _ToastColors({
    required this.background,
    required this.foreground,
    required this.accent,
  });

  factory _ToastColors.fromLevel(AppErrorLevel level, ColorScheme cs) {
    return switch (level) {
      AppErrorLevel.info => _ToastColors(
          background: cs.primaryContainer,
          foreground: cs.onPrimaryContainer,
          accent: cs.primary,
        ),
      AppErrorLevel.warning => _ToastColors(
          background: cs.tertiaryContainer,
          foreground: cs.onTertiaryContainer,
          accent: cs.tertiary,
        ),
      AppErrorLevel.error => _ToastColors(
          background: cs.errorContainer,
          foreground: cs.onErrorContainer,
          accent: cs.error,
        ),
    };
  }
}
