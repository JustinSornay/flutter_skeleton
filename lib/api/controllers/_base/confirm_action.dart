// confirm_action.dart
//
// confirmAction() — asks the user to confirm an action in a modal
// (ModalProvider + AppModal + ConfirmCard) and completes with the answer.
// Used by controllers before a destructive or irreversible call.

import "dart:async";

import "package:flutter/widgets.dart";
import "package:flutter_skeleton/providers/modal_provider.dart";
import "package:flutter_skeleton/widgets/custom/ConfirmCard/index.dart";
import "package:flutter_skeleton/widgets/layout/AppModal/index.dart";
import "package:provider/provider.dart";

/// Shows a confirmation modal and completes with `true` when the user
/// confirms, `false` when they cancel, tap the scrim, or another modal
/// replaces this one through [ModalProvider] (so the caller never hangs).
///
/// [context] is only read synchronously (to reach [ModalProvider]), so the
/// caller may keep awaiting after its own widget is gone.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required String cancelLabel,
  String? message,
  bool destructive = false,
}) {
  final ModalProvider modals = context.read<ModalProvider>();
  final Completer<bool> answer = Completer<bool>();
  late final Widget modal;
  late final VoidCallback watch;

  void finish(bool confirmed) {
    if (answer.isCompleted) return;
    modals.removeListener(watch);
    answer.complete(confirmed);
  }

  void close(bool confirmed) {
    if (answer.isCompleted) return;
    finish(confirmed);
    if (identical(modals.currentModal, modal)) modals.dismiss();
  }

  watch = () {
    if (!identical(modals.currentModal, modal)) finish(false);
  };

  modal = AppModal(
    isVisible: true,
    onDismiss: () => close(false),
    child: ConfirmCard(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
      onConfirm: () => close(true),
      onCancel: () => close(false),
    ),
  );
  modals.show(modal);
  modals.addListener(watch);
  return answer.future;
}
