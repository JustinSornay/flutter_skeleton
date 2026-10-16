// auth_gate.dart
//
// requireAuth() — gates an action behind authentication.
//
// The skeleton ships no auth provider: the app registers how the user signs
// in with AuthGate.setSignInHandler (typically next to the Http auth hooks,
// e.g. a handler that opens a sign-in modal through ModalProvider and
// completes when that modal closes, signed in or not). Without a handler,
// requireAuth only reports whether Http already has a token.
//
// Usage:
//   // controller method returning bool (null for a T? method)
//   if (!await requireAuth(context)) return false;
//   // view-model method returning void
//   if (!await requireAuth(context) || !mounted) return;

import "package:flutter/widgets.dart";
import "package:flutter_skeleton/api/http/http.dart";

/// Runs the app's sign-in flow and completes when it ends, whether the user
/// signed in or gave up. The outcome is read from [Http.hasToken].
typedef SignInHandler = Future<void> Function(BuildContext context);

/// Registry for the app's sign-in flow, used by [requireAuth].
abstract final class AuthGate {
  static SignInHandler? _signIn;
  static Future<void>? _pending;

  /// Registers the sign-in flow. Last write wins; null removes it.
  static void setSignInHandler(SignInHandler? handler) {
    _signIn = handler;
  }

  /// Removes the handler and forgets a running flow. Call from `tearDown`
  /// in tests that set it.
  @visibleForTesting
  static void reset() {
    _signIn = null;
    _pending = null;
  }
}

/// Returns true when the user is signed in ([Http.hasToken]), running the
/// registered sign-in flow first when they are not.
///
/// Returns false when no handler is registered or the flow ends without a
/// token. Calls made while a flow is already running (a double tap) wait for
/// that same flow instead of starting another one, so every caller
/// completes.
///
/// [context] is only handed to the handler; check `mounted` before using a
/// context after this future completes.
Future<bool> requireAuth(BuildContext context) async {
  if (Http.hasToken) return true;
  final SignInHandler? signIn = AuthGate._signIn;
  if (signIn == null) return false;
  final Future<void> flow = AuthGate._pending ??= signIn(context).whenComplete(() => AuthGate._pending = null);
  await flow;
  return Http.hasToken;
}
