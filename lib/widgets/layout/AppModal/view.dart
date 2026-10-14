// view.dart
//
// _ViewMixin — widget tree for AppModal.
//
// Renders a full-screen scrim with a centred card. Tapping the scrim fires
// onDismiss. Taps on the card itself are absorbed by the inner
// GestureDetector so they do not propagate to the scrim.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, _AnimatedModalState state) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: state.ctrl,
      builder: (BuildContext ctx, Widget? child) {
        if (state.ctrl.isDismissed) return const SizedBox.shrink();
        return Material(
          color: cs.scrim.withValues(alpha: 0.48 * state.fade.value),
          child: GestureDetector(
            onTap: state.widget.onDismiss,
            // opaque: captures taps in the scrim's empty areas.
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: GestureDetector(
                // Absorb card taps so they do not bubble up to the scrim detector.
                onTap: () {},
                child: FadeTransition(
                  opacity: state.fade,
                  child: ScaleTransition(
                    scale: state.scale,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 440),
                      margin: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 3),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Semantics(
                        scopesRoute: true,
                        explicitChildNodes: true,
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: state.widget.child,
    );
  }
}
