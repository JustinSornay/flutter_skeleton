// view.dart
//
// Layout of HistoryTimeline: a kMinTapTarget-tall Row holding the axis
// (track line + one _TimelineDot per visible entry, oldest first so the
// current dot paints on top) and, when entries are hidden, the _OverflowPill.
// Each dot's hit box is up to kMinTapTarget wide and stops at the midpoints
// with its neighbours, so a pointer always reaches the nearest dot. The pill
// takes its own width, so the axis never runs under it. ColorScheme tokens
// only.

part of "index.dart";

/// Y of the track line and of every dot centre inside the strip.
const double _kAxisY = 20;

/// Diameter of the current dot.
const double _kCurrentDotSize = 12;

/// Diameter of a past dot.
const double _kPastDotSize = 8;

/// Y of every date caption: below the largest dot, plus a 2 dp gap.
const double _kCaptionTop = _kAxisY + _kCurrentDotSize / 2 + 2;

mixin _ViewMixin<T> {
  Widget render(BuildContext context, _HistoryTimelineState<T> state) {
    final List<T> ordered = state._visibleOldestFirst;
    if (ordered.isEmpty) return const SizedBox(height: kMinTapTarget);
    final int hidden = state._hiddenCount;

    return SizedBox(
      height: kMinTapTarget,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return _axis(context, state, ordered, constraints.maxWidth);
              },
            ),
          ),
          if (hidden > 0) ...<Widget>[
            const SizedBox(width: kDefaultPadding),
            _OverflowPill(count: hidden, onTap: state._expand),
          ],
        ],
      ),
    );
  }

  /// Track line and dots of [ordered] (oldest first) on a [width]-wide axis.
  Widget _axis(BuildContext context, _HistoryTimelineState<T> state, List<T> ordered, double width) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<double> xs = state._positions(ordered, width);
    final List<({double left, double right})> spans = state._hitSpans(xs);
    final String Function(DateTime date) caption = state._captionFormatter(context);
    final int last = ordered.length - 1;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        if (ordered.length > 1)
          Positioned(
            left: kDefaultPadding,
            right: kDefaultPadding,
            top: _kAxisY - 0.5,
            height: 1,
            child: ColoredBox(color: cs.outlineVariant),
          ),
        for (int i = 0; i <= last; i++)
          Positioned(
            // Newest-first index: the last (newest) dot is index 0. Keyed by
            // it so each mouse region stays with its entry when the strip
            // expands, and hover follows the dot under the pointer.
            key: ValueKey<int>(last - i),
            left: spans[i].left,
            top: 0,
            width: spans[i].right - spans[i].left,
            height: kMinTapTarget,
            child: _dot(state, last - i, ordered[i], caption, xs[i] - spans[i].left),
          ),
      ],
    );
  }

  /// The dot of [item] at newest-first [index], centred [centerX] from the
  /// left edge of its hit box.
  Widget _dot(
    _HistoryTimelineState<T> state,
    int index,
    T item,
    String Function(DateTime date) caption,
    double centerX,
  ) {
    final bool current = index == 0;
    return _TimelineDot(
      centerX: centerX,
      caption: caption(state.widget.dateOf(item)),
      label: state.widget.labelOf(item),
      hint: state._hint(current: current),
      current: current,
      hovered: state._hoverIndex == index,
      onTap: state._isTappable(index) ? () => state._onTap(index, item) : null,
      onHover: (bool inside) => state._onHover(index, inside: inside),
    );
  }
}
