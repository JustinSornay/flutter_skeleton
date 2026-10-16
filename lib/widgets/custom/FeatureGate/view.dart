// view.dart
//
// Tree of FeatureGate: the child while unlocked; otherwise the resolved
// locked strings and the mode's widget (widgets/) inside one container
// semantics node. Hidden renders nothing and has no semantics node.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, FeatureGate widget) {
    if (!widget.isLocked) return widget.child;
    if (widget.mode == GateDisplayMode.hidden) return const SizedBox.shrink();

    final String? custom = _nonEmpty(widget.lockedLabel);
    final String label = custom ?? "custom.feature_gate.title".tr();
    final bool tappable = widget.onUnlock != null &&
        (widget.mode == GateDisplayMode.dimmed || widget.mode == GateDisplayMode.hint);

    return Semantics(
      container: true,
      button: tappable,
      label: custom == null
          ? label
          : "custom.feature_gate.semantics".tr(namedArgs: <String, String>{"label": custom}),
      child: _content(widget, label),
    );
  }

  /// The locked widget of [FeatureGate.mode].
  Widget _content(FeatureGate widget, String label) {
    final Widget badge = _LockBadge(
      label: _nonEmpty(widget.badgeLabel) ?? "custom.feature_gate.locked".tr(),
    );

    return switch (widget.mode) {
      GateDisplayMode.lockCard => _LockCard(
          label: label,
          actionLabel: _nonEmpty(widget.actionLabel) ?? "custom.feature_gate.unlock".tr(),
          onUnlock: widget.onUnlock,
        ),
      GateDisplayMode.dimmed => _DimmedPreview(
          badge: badge,
          onUnlock: widget.onUnlock,
          child: widget.child,
        ),
      GateDisplayMode.teaser => _Teaser(label: label, badge: badge, builder: widget.teaserBuilder),
      GateDisplayMode.hint => _HintRow(label: label, badge: badge, onUnlock: widget.onUnlock),
      // Handled by render(); kept for exhaustiveness.
      GateDisplayMode.hidden => const SizedBox.shrink(),
    };
  }

  /// [value] unless it is null or empty.
  String? _nonEmpty(String? value) {
    return (value == null || value.isEmpty) ? null : value;
  }
}
