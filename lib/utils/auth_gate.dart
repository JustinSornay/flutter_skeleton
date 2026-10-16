// auth_gate.dart
//
// requireAuth() — gates an action behind authentication.
//
// The skeleton ships no auth provider: the app registers how the user signs
// in with AuthGate.setSignInHandler (typically next to the Http auth hooks,
// e.g. a handler that opens a sign-in modal through ModalProvider and
// completes once the user is signed in or gives up). Without a handler,
// requireAuth only reports whether Http already has a token.
//
// Usage (in a controller or view model):
//   if (!await requireAuth(context)) return;
//   // signed in: proceed with the auth-gated call

import "package:flutter/widgets.dart";
import "package:flutter_skeleton/api/http/http.dart";

/// Asks the user to sign in. Completes with true once they are signed in,
/// false when they dismiss it.
typedef SignInHandler = Future<bool> Function(BuildContext context);

/// Registry for the app's sign-in flow, used by [requireAuth].
abstract final class AuthGate {
  static SignInHandler? _signIn;

  /// Registers the sign-in flow. Last write wins; null removes it.
  static void setSignInHandler(SignInHandler? handler) {
    _signIn = handler;
  }

  /// Removes the handler. Call from `tearDown` in tests that set it.
  @visibleForTesting
  static void reset() {
    _signIn = null;
  }
}

/// Returns true when the user is signed in ([Http.hasToken]), running the
/// registered sign-in flow first when they are not.
///
/// Returns false when no handler is registered or the user does not sign in.
/// A handler that reports success while [Http.hasToken] is still false also
/// returns false, so the gated call never goes out without a token.
///
/// [context] is only handed to the handler; check `mounted` before using a
/// context after this future completes.
Future<bool> requireAuth(BuildContext context) async {
  if (Http.hasToken) return true;
  final SignInHandler? signIn = AuthGate._signIn;
  if (signIn == null) return false;
  final bool signedIn = await signIn(context);
  return signedIn && Http.hasToken;
}
