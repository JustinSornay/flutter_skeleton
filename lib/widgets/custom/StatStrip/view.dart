// view.dart
//
// Tree of StatStrip: the padded row of equal-height Expanded tiles, or the
// two-column grid built from such rows (an empty slot completes an odd last
// row). Every tile is an outlined MetricTile fed 1:1 from its StatStripItem.

part of "index.dart";

/// Gap between two tiles, horizontally and vertically.
const double _gap = kDefaultPadding;

/// Tiles per row in [StatStripLayout.grid].
const int _gridColumns = 2;

mixin _ViewMixin {
  Widget render(BuildContext context, StatStrip widget) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: widget.padding,
      child: switch (widget.layout) {
        StatStripLayout.row => _row(widget.items, widget.items.length),
        StatStripLayout.grid => _grid(widget.items),
      },
    );
  }

  /// Rows of [_gridColumns] tiles separated by [_gap].
  Widget _grid(List<StatStripItem> items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int start = 0; start < items.length; start += _gridColumns) ...<Widget>[
          if (start > 0) const SizedBox(height: _gap),
          _row(items.sublist(start, math.min(start + _gridColumns, items.length)), _gridColumns),
        ],
      ],
    );
  }

  /// [slots] equal-width cells separated by [_gap], all as tall as the
  /// tallest tile; the cells past [items] stay empty.
  Widget _row(List<StatStripItem> items, int slots) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int index = 0; index < slots; index++) ...<Widget>[
            if (index > 0) const SizedBox(width: _gap),
            Expanded(child: index < items.length ? _tile(items[index]) : const SizedBox.shrink()),
          ],
        ],
      ),
    );
  }

  Widget _tile(StatStripItem item) {
    return MetricTile(
      label: item.label,
      value: item.value,
      unit: item.unit,
      icon: item.icon,
      valueTone: item.valueTone,
      caption: item.caption,
      captionTone: item.captionTone,
      semanticsLabel: item.semanticsLabel,
      outlined: true,
    );
  }
}
