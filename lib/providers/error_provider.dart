// error_provider.dart
//
// ErrorProvider — global in-app error feedback channel.
//
// Any widget or service calls ErrorProvider.show() to surface a contextual
// message to the user. Only one message is visible at a time. New messages
// replace the current one and restart the auto-dismiss timer.
//
// Severity levels map to theme colour tokens in ErrorToastCard:
//   info    → ColorScheme.primaryContainer / onPrimaryContainer
//   warning → ColorScheme.tertiaryContainer / onTertiaryContainer
//   error   → ColorScheme.errorContainer / onErrorContainer

import "dart:async";
import "package:flutter/foundation.dart";

/// Severity level for an in-app error toast.
enum AppErrorLevel { info, warning, error }

/// Immutable data model for a single in-app error toast.
final class AppError {
  final String message;
  final AppErrorLevel level;

  const AppError({required this.message, required this.level});
}

/// Drives the global in-app error toast (ErrorToastCard) rendered by Layout.
final class ErrorProvider extends ChangeNotifier {
  AppError? _current;
  Timer? _dismissTimer;

  /// The currently active error, or null when no toast is shown.
  AppError? get current => _current;

  /// True when an error is currently being shown.
  bool get hasError => _current != null;

  /// Show a toast with [message] at [level].
  /// Replaces any currently visible toast and resets the dismiss timer.
  void show(String message, {AppErrorLevel level = AppErrorLevel.error}) {
    _dismissTimer?.cancel();
    _current = AppError(message: message, level: level);
    notifyListeners();

    final Duration duration = level == AppErrorLevel.info
        ? const Duration(seconds: 3)
        : const Duration(seconds: 5);

    _dismissTimer = Timer(duration, clear);
  }

  /// Immediately hides the current toast.
  void clear() {
    if (_current == null) return;
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _current = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }
}
