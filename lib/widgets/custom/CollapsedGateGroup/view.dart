// view.dart
//
// Tree of CollapsedGateGroup: the bordered Material, the header
// (widgets/gate_header.dart) and the cross-faded content: feature rows
// (widgets/feature_row.dart) and the optional full-width call to action.
// Colours come from the ColorScheme only.

part of "index.dart";

/// Group corner radius.
const double _groupRadius = 8;

mixin _ViewMixin {
  Widget render(BuildContext context, _CollapsedGateGroupState state) {
    final CollapsedGateGroup widget = state.widget;
    if (widget.features.isEmpty) return const SizedBox.shrink();

    final ColorScheme cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_groupRadius),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Stretch keeps the content at the group's full width while it is
        // hidden or animating, so it never relayouts from the centre.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _GateHeader(
            summary: _orDefault(
              widget.summary,
              "custom.collapsed_gate_group.summary".tr(
                namedArgs: <String, String>{"count": "${widget.features.length}"},
              ),
            ),
            isExpanded: state.isExpanded,
            onToggle: state.toggle,
          ),
          _body(context, state, cs),
        ],
      ),
    );
  }

  /// Cross-fades the content in and out. Under reduced motion the content is
  /// swapped without AnimatedCrossFade, so it shows or hides in one frame.
  Widget _body(BuildContext context, _CollapsedGateGroupState state, ColorScheme cs) {
    final Duration duration = resolveMotion(context, kMotionShort);
    final Widget content = _content(state.widget, cs);
    if (duration == Duration.zero) {
      return state.isExpanded ? content : const SizedBox.shrink();
    }

    return AnimatedCrossFade(
      duration: duration,
      firstCurve: Curves.easeOutCubic,
      secondCurve: Curves.easeOutCubic,
      sizeCurve: Curves.easeOutCubic,
      crossFadeState: state.isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: const SizedBox.shrink(),
      secondChild: content,
    );
  }

  /// Divider, one row per entry, then the optional call to action.
  Widget _content(CollapsedGateGroup widget, ColorScheme cs) {
    final VoidCallback? onAction = widget.onAction;
    final Widget divider = Divider(height: 1, thickness: 1, color: cs.outlineVariant);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        divider,
        for (final GatedFeatureEntry entry in widget.features)
          _FeatureRow(entry: entry, badgeLabel: entry.badgeLabel ?? widget.badgeLabel),
        if (onAction != null) ...<Widget>[
          divider,
          _action(widget, onAction),
        ],
      ],
    );
  }

  /// Full-width call to action, at least kMinTapTarget tall.
  Widget _action(CollapsedGateGroup widget, VoidCallback onAction) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kDefaultPadding * 2,
        kDefaultPadding,
        kDefaultPadding * 2,
        kDefaultPadding * 1.5,
      ),
      child: FilledButton(
        onPressed: onAction,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(kMinTapTarget)),
        child: Text(_orDefault(widget.actionLabel, "custom.collapsed_gate_group.unlock_all".tr())),
      ),
    );
  }

  /// [value] unless it is null or empty, else [fallback].
  String _orDefault(String? value, String fallback) {
    return (value == null || value.isEmpty) ? fallback : value;
  }
}
