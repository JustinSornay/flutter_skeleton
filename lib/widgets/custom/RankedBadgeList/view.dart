// view.dart
//
// Tree of RankedBadgeList: nothing for an empty list, else the visible rows
// (widgets/badge_row.dart) in an AnimatedSize (skipped under reduced motion),
// followed by the expand toggle (widgets/expand_toggle.dart) when some items
// are hidden.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, _RankedBadgeListState state) {
    final RankedBadgeList widget = state.widget;
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _animated(
          context,
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final RankedBadgeItem item in state.visible)
                _BadgeRow(item: item, trailingBuilder: widget.trailingBuilder),
            ],
          ),
        ),
        if (state.hasMore)
          _ExpandToggle(
            label: _toggleLabel(widget, state.isExpanded),
            isExpanded: state.isExpanded,
            onTap: state.toggle,
          ),
      ],
    );
  }

  /// Animates height changes of [rows]. Under reduced motion the rows are
  /// returned as is (an AnimatedSize with a zero duration asserts during
  /// layout), so the list grows or shrinks in one frame.
  Widget _animated(BuildContext context, Widget rows) {
    final Duration duration = resolveMotion(context, kMotionShort);
    if (duration == Duration.zero) return rows;

    return AnimatedSize(
      duration: duration,
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: rows,
    );
  }

  /// Host override when set, else the built-in key for the current state.
  String _toggleLabel(RankedBadgeList widget, bool isExpanded) {
    if (isExpanded) {
      return widget.showLessLabel ?? "custom.ranked_badge_list.show_less".tr();
    }
    return widget.showAllLabel ??
        "custom.ranked_badge_list.show_all".tr(
          namedArgs: <String, String>{"count": "${widget.items.length}"},
        );
  }
}
