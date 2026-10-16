// index.dart
//
// ConfirmCard — content of a confirmation modal: a title, an optional
// message, and cancel / confirm buttons. The host mounts it (usually with
// confirmAction() from api/controllers/_base, inside an AppModal) and reacts
// to the callbacks. The tree lives in view.dart.

import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "view.dart";

/// Confirmation content: [title], optional [message], then a [cancelLabel]
/// text button and a [confirmLabel] filled button, aligned to the end.
///
/// - [destructive] paints the confirm button with `cs.error` / `cs.onError`
///   (delete, revoke…); otherwise it uses the theme's filled button.
/// - Both buttons keep at least a [kMinTapTarget] (48 dp) hit area.
/// - The title is announced as a header.
///
/// Content only: no background, no scrim, never touches the Navigator.
/// `AppModal` provides the card surface; strings are already localised by
/// the host.
final class ConfirmCard extends StatelessWidget with _ViewMixin {
  /// Question asked to the user, already localised.
  final String title;

  /// Consequences of the action. Hidden when null or empty.
  final String? message;

  /// Confirm button text, already localised.
  final String confirmLabel;

  /// Cancel button text, already localised.
  final String cancelLabel;

  /// Paints the confirm button in the error colours.
  final bool destructive;

  /// Called on a confirm tap. The host closes the modal.
  final VoidCallback onConfirm;

  /// Called on a cancel tap. The host closes the modal.
  final VoidCallback onCancel;

  const ConfirmCard({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
    this.message,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}
