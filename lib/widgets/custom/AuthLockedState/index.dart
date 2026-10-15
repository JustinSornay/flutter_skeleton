// index.dart
//
// AuthLockedState — centred empty state for content that needs a signed-in
// user: an icon, a title, a short explanation and one sign-in button. It is
// a preset of StateMessageView (neutral tone, one primary action). The
// sign-in flow is an injected async callback; the widget never reads a
// provider, an auth SDK or Http. The tree lives in view.dart.

import "dart:async";

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/StateMessageView/index.dart";

part "view.dart";

/// Centred empty state for auth-gated content visited without a session.
///
/// Renders a [StateMessageView] with the neutral tone:
/// - a decorative 64 dp badge holding [icon] (`cs.onSurfaceVariant` on
///   `cs.surfaceContainerHighest`), excluded from semantics;
/// - [title] (announced as a header) and [subtitle], both centred, in a live
///   region;
/// - one full-width [FilledButton] (at least `kMinTapTarget` tall) with a
///   leading `Icons.login_rounded` and [actionLabel], else
///   `custom.auth_locked_state.sign_in`.
///
/// A tap awaits [onSignIn]; when it resolves `true` and this widget is still
/// mounted, [onAuthenticated] runs once. Errors thrown by [onSignIn] are not
/// caught: the host handles them inside its own flow. The content scrolls
/// when the available height is too short. No `Overlay` ancestor is needed.
final class AuthLockedState extends StatelessWidget with _ViewMixin {
  /// Headline, already localised by the host.
  final String title;

  /// Explanation under [title], already localised by the host.
  final String subtitle;

  /// Opens the app's sign-in flow (a modal, an auth SDK, a route…) and
  /// resolves `true` when the user is now signed in, `false` when the flow
  /// was dismissed.
  final Future<bool> Function() onSignIn;

  /// Called once after [onSignIn] resolved `true`, only while this widget is
  /// still mounted (for example: reload the gated data). Leave null when the
  /// host already rebuilds from its own session state.
  final VoidCallback? onAuthenticated;

  /// Button label; null → `custom.auth_locked_state.sign_in`.
  final String? actionLabel;

  /// Decorative icon of the badge above [title].
  final IconData icon;

  const AuthLockedState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSignIn,
    this.onAuthenticated,
    this.actionLabel,
    this.icon = Icons.lock_outline_rounded,
  });

  /// Runs [onSignIn], then [onAuthenticated] on success if still mounted.
  Future<void> _handleSignIn(BuildContext context) async {
    final bool authenticated = await onSignIn();
    if (authenticated && context.mounted) onAuthenticated?.call();
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}
