// index.dart
//
// ModalConsumer — stacks ModalProvider.currentModal above the page content.

import "package:flutter/material.dart";
import "package:flutter_skeleton/providers/modal_provider.dart";
import "package:provider/provider.dart";

part "view.dart";

/// Generic modal overlay consumer.
///
/// Stacks [ModalProvider.currentModal] as a full-screen overlay above [child].
/// Must be placed inside the GoRouter subtree (ShellRoute builder) so that
/// modals injected via [ModalProvider.show] inherit a valid GoRouter context.
final class ModalConsumer extends StatelessWidget with _ViewMixin {
  final Widget child;

  const ModalConsumer({super.key, required this.child});

  @override
  Widget build(BuildContext context) => render(context, this);
}
