// view.dart
//
// Tree of DeltaCards: checks the 2-to-4 item contract, then maps every
// DeltaCardItem onto a StatStripItem (caption = trend label or translated
// default, caption tone = item tone) inside an unpadded StatStrip row.

part of "index.dart";

/// Fewest cards the row is designed for.
const int _minItems = 2;

/// Most cards the row is designed for.
const int _maxItems = 4;

mixin _ViewMixin {
  Widget render(BuildContext context, DeltaCards widget) {
    assert(
      widget.items.length >= _minItems && widget.items.length <= _maxItems,
      "DeltaCards needs $_minItems to $_maxItems items, got ${widget.items.length}",
    );

    return StatStrip(
      layout: StatStripLayout.row,
      padding: EdgeInsets.zero,
      items: <StatStripItem>[
        for (final DeltaCardItem item in widget.items) _tile(item),
      ],
    );
  }

  StatStripItem _tile(DeltaCardItem item) {
    return StatStripItem(
      label: item.label,
      value: item.value,
      caption: _caption(item),
      captionTone: item.tone,
    );
  }

  /// [DeltaCardItem.trendLabel], or the translated default of its trend.
  String _caption(DeltaCardItem item) {
    final String? custom = item.trendLabel;
    return custom == null || custom.isEmpty ? item.trend.captionKey.tr() : custom;
  }
}
