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
/// confirms, `false` when they cancel or tap the scrim.
///
/// [context] is only read synchronously (to reach [ModalProvider]), so the
/// caller may keep awaiting after its own widget is gone. The modal replaces
/// any modal already shown by [ModalProvider].
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

  void close(bool confirmed) {
    if (answer.isCompleted) return;
    modals.dismiss();
    answer.complete(confirmed);
  }

  modals.show(
    AppModal(
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
    ),
  );
  return answer.future;
}
