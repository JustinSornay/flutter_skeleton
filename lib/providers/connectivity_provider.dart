// connectivity_provider.dart
//
// Tracks the device's network connectivity in real time and exposes a single
// boolean — [isOffline] — that the UI can react to.
//
// Uses the connectivity_plus package stream so the state stays current without
// polling. The subscription is cancelled in dispose() to prevent leaks.

import "dart:async";

import "package:connectivity_plus/connectivity_plus.dart";
import "package:flutter/foundation.dart";

/// Listens to platform connectivity changes and notifies listeners whenever
/// the device transitions between online and offline.
///
/// Starts an immediate check on construction so the initial state reflects
/// reality before the first stream event arrives.
final class ConnectivityProvider extends ChangeNotifier {
  bool _isOffline = false;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  /// True when every available interface reports [ConnectivityResult.none].
  bool get isOffline => _isOffline;

  ConnectivityProvider() {
    _subscription = Connectivity().onConnectivityChanged.listen(_onChanged);
    _checkInitial();
  }

  /// Constructor for testing. Bypasses the platform stream and sets a fixed
  /// [isOffline] value.
  @visibleForTesting
  ConnectivityProvider.withState({bool offline = false})
      : _isOffline = offline,
        _subscription = const Stream<List<ConnectivityResult>>.empty()
            .listen((_) {});

  /// Performs a one-shot connectivity check to populate [isOffline] before
  /// the stream delivers its first event.
  Future<void> _checkInitial() async {
    final List<ConnectivityResult> result = await Connectivity().checkConnectivity();
    _onChanged(result);
  }

  /// Evaluates the latest list of connectivity results and notifies listeners
  /// only when the offline status actually changes, avoiding redundant rebuilds.
  void _onChanged(List<ConnectivityResult> results) {
    final bool offline = results.every(
      (ConnectivityResult r) => r == ConnectivityResult.none,
    );
    if (offline != _isOffline) {
      _isOffline = offline;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
