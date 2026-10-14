// layout.dart
//
// Layout — the root shell widget that wraps every page in the app
// (installed by MaterialApp.router's `builder` in main.dart).
//
// Column with:
//   1. OfflineBanner — connectivity-reactive banner, zero height when online.
//   2. ErrorToastCard — global feedback toast driven by ErrorProvider.
//   3. Expanded page content (the GoRouter navigator).
//
// The AppHeader is NOT included here — it is added by the GoRouter ShellRoute
// so that it is only shown on routes that belong to the shell, not on
// full-screen routes.
//
// Layout sits ABOVE the Navigator: widgets placed here have no Overlay
// ancestor, so they must not use Tooltip, PopupMenuButton or similar.

import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/layout/ErrorToastCard/index.dart";
import "package:flutter_skeleton/widgets/layout/OfflineBanner/index.dart";

/// Root layout shell that applies the offline banner and the error toast
/// to every page in the app.
final class Layout extends StatelessWidget {
  /// The page content to render below the banners.
  final Widget child;

  const Layout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            const OfflineBanner(),
            const ErrorToastCard(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
