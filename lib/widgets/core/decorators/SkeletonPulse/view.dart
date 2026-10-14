part of "index.dart";

mixin _ViewMixin {
  Widget render(
    BuildContext context,
    SkeletonPulse widget,
    AnimationController internalController,
  ) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;

    final AnimationController active = widget.controller ?? internalController;

    return AnimatedBuilder(
      animation: active,
      builder: (_, _) => Opacity(
        opacity: 0.3 + 0.4 * active.value,
        child: widget.child,
      ),
    );
  }
}
