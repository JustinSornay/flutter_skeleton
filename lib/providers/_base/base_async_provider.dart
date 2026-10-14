import "package:flutter/foundation.dart";

/// Base class for providers that perform async operations.
///
/// Provides a dispose-safe [notify] method and tracks [disposed] to prevent
/// calling [notifyListeners] after the widget tree has unmounted the provider.
abstract class BaseAsyncProvider extends ChangeNotifier {
  bool _disposed = false;

  bool get disposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Calls [notifyListeners] only when the provider has not yet been disposed.
  void notify() {
    if (!_disposed) notifyListeners();
  }
}
