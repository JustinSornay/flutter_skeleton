// index.dart
//
// AppModal — animated scrim overlay driven by [isVisible].
//
// Delegates animation lifecycle to [_AnimatedModalState] (view_model.dart)
// and widget tree construction to [_ViewMixin] (view.dart).
//
// Usage with ModalProvider:
//   context.read<ModalProvider>().show(
//     AppModal(isVisible: true, onDismiss: modalProvider.dismiss, child: …),
//   );

import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "view_model.dart";
part "view.dart";

const Duration _kModalMotion = Duration(milliseconds: 260);

/// Animated modal overlay with scrim dismissal.
///
/// [isVisible] drives the open/close animation.
/// [onDismiss] is called when the user taps the scrim outside the card.
/// [child] is the modal card content.
final class AppModal extends StatelessWidget {
  final bool isVisible;
  final Widget child;
  final VoidCallback onDismiss;

  const AppModal({
    super.key,
    required this.isVisible,
    required this.child,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) => _AnimatedModal(
        isVisible: isVisible,
        onDismiss: onDismiss,
        child: child,
      );
}

/// Internal StatefulWidget that owns the AnimationController lifecycle.
final class _AnimatedModal extends StatefulWidget {
  final bool isVisible;
  final Widget child;
  final VoidCallback onDismiss;

  const _AnimatedModal({
    required this.isVisible,
    required this.child,
    required this.onDismiss,
  });

  @override
  State<_AnimatedModal> createState() => _AnimatedModalState();
}
