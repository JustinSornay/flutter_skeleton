// view.dart
//
// Tree of LevelProgressBar: one semantics node (level n of N + counter value)
// over the header, the segment row and the label row, then the optional
// next-level card. Colours come from the ColorScheme only; spacing from the
// kDefaultPadding grid.

part of "index.dart";

/// Gap between the header and the segment row (8 dp).
const double _headerGap = kDefaultPadding;

/// Gap between the segment row and the label row (4 dp).
const double _labelsGap = kDefaultPadding / 2;

/// Horizontal gap between two segments, repeated under the labels so each
/// label sits exactly under its segment (4 dp).
const double _segmentGap = kDefaultPadding / 2;

/// Gap above the next-level card (12 dp).
const double _cardGap = kDefaultPadding * 1.5;

mixin _ViewMixin {
  Widget render(BuildContext context, LevelProgressBar widget) {
    // Checked here, not in the const constructor: List.length is not a
    // constant expression.
    assert(widget.levels.isNotEmpty, "LevelProgressBar needs at least one level");
    assert(
      widget.currentIndex >= 0 && widget.currentIndex < widget.levels.length,
      "currentIndex must index levels",
    );
    final LevelProgressCounter? counter = switch ((widget.count, widget.total)) {
      (final int count, final int total) => LevelProgressCounter.of(
        "custom.level_progress_bar.counter".tr(),
        count: count,
        total: total,
        label: widget.countLabel,
      ),
      _ => null,
    };
    final List<String>? nextItems = widget._shownNextItems;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          container: true,
          excludeSemantics: true,
          label: _semanticsLabel(widget),
          value: counter?.text,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _LevelHeader(label: widget.levels[widget.currentIndex], counter: counter),
              const SizedBox(height: _headerGap),
              _SegmentedBar(segmentCount: widget.levels.length, filledCount: widget.currentIndex + 1),
              const SizedBox(height: _labelsGap),
              _labels(context, widget),
            ],
          ),
        ),
        if (nextItems != null) ...<Widget>[
          const SizedBox(height: _cardGap),
          _NextLevelCard(
            title: widget.nextTitle ?? "custom.level_progress_bar.next_title".tr(),
            items: nextItems,
            actionLabel: widget.nextActionLabel ?? "custom.level_progress_bar.next_action".tr(),
            onPressed: widget.onNextLevel,
          ),
        ],
      ],
    );
  }

  /// One label per level, each under its segment; reached levels in
  /// `cs.primary`, the others in `cs.onSurfaceVariant`.
  Widget _labels(BuildContext context, LevelProgressBar widget) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final TextStyle base = (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < widget.levels.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: _segmentGap),
          Expanded(
            child: Text(
              widget.levels[i],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: base.copyWith(color: i <= widget.currentIndex ? cs.primary : cs.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }

  /// "Level n of N: label" for the summary node.
  String _semanticsLabel(LevelProgressBar widget) {
    return "custom.level_progress_bar.semantics".tr(
      namedArgs: <String, String>{
        "current": "${widget.currentIndex + 1}",
        "count": "${widget.levels.length}",
        "label": widget.levels[widget.currentIndex],
      },
    );
  }
}
