// modal_provider.dart
//
// Generic modal overlay controller. Any widget can mount a full-screen modal
// (usually an AppModal) without pushing a Navigator route — consistent with
// the "context.go() only" navigation rule.

import "package:flutter/widgets.dart";

/// Generic modal overlay controller.
///
/// Call [show] to mount a widget as a full-screen modal overlay.
/// Call [dismiss] to remove the current modal from the overlay.
///
/// Consumed by [ModalConsumer] in the ShellRoute builder, which renders
/// [currentModal] above all page content inside the GoRouter subtree.
final class ModalProvider extends ChangeNotifier {
  Widget? _currentModal;

  /// The widget currently displayed as a modal overlay, or null if none.
  Widget? get currentModal => _currentModal;

  /// Mounts [modal] as the active overlay and notifies listeners.
  void show(Widget modal) {
    _currentModal = modal;
    notifyListeners();
  }

  /// Removes the current modal overlay and notifies listeners.
  void dismiss() {
    if (_currentModal == null) return;
    _currentModal = null;
    notifyListeners();
  }
}
