// view.dart
//
// Tree of CardTable: the empty card when there is no row, otherwise the
// bordered card whose content is clipped to the border's inner radius: a
// transparent Material (ink surface for the rows), the header row and one
// body row per item. Colours come from the ColorScheme only.

part of "index.dart";

/// Corner radius of the card.
const double _cardRadius = 12;

/// Width of the card border ([Border.all] default).
const double _cardBorderWidth = 1;

/// Horizontal and vertical padding of the header and body rows.
const EdgeInsets _rowPadding = EdgeInsets.symmetric(
  horizontal: kDefaultPadding * 2,
  vertical: kDefaultPadding,
);

/// Card frame shared by the table and the empty card.
BoxDecoration _cardDecoration(ColorScheme cs) {
  return BoxDecoration(
    color: cs.surfaceContainerLowest,
    border: Border.all(color: cs.outlineVariant),
    borderRadius: BorderRadius.circular(_cardRadius),
  );
}

mixin _ViewMixin<T> {
  Widget render(BuildContext context, CardTable<T> widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    if (widget.rows.isEmpty) {
      return _EmptyCard(message: widget.emptyMessage ?? "custom.card_table.empty".tr());
    }

    // The content is clipped inside the border (inner radius), not by the
    // Container: a clip on the outer radius lets the header fill and the row
    // ink paint over the border arc at the corners.
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(cs),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_cardRadius - _cardBorderWidth),
        child: Material(
          type: MaterialType.transparency,
          animationDuration: resolveMotion(context, kThemeChangeDuration),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _HeaderRow<T>(columns: widget.columns),
              for (final T row in widget.rows)
                _BodyRow<T>(
                  row: row,
                  columns: widget.columns,
                  onTap: widget.onRowTap,
                  semanticLabel: widget.rowSemanticLabel?.call(row),
                  detail: widget.rowDetailBuilder?.call(context, row),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
