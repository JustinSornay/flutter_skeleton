// column.dart
//
// Column declaration of CardTable: CardTableEmphasis (weight of a built-in
// text cell) and CardTableColumn<T> (header label, flex share or fixed
// width, alignment, cell builder, plus the `.text` shortcut). Also the
// private sizing helper shared by the header and body rows so their cells
// line up.

part of "index.dart";

/// Visual weight of a text cell built with [CardTableColumn.text].
enum CardTableEmphasis {
  /// Primary text: 12.5 sp, w700, `cs.onSurface`.
  strong,

  /// Secondary text: 11.5 sp, w400, `cs.onSurfaceVariant`.
  muted,
}

/// One column of a [CardTable]: header label, sizing, alignment and how to
/// build a cell.
@immutable
final class CardTableColumn<T> {
  /// Header text, already localised. Rendered uppercased; an empty label
  /// leaves the header cell blank (for an icon or action column).
  final String label;

  /// Flex share of the remaining width, used when [width] is null.
  final int flex;

  /// Fixed logical width; overrides [flex] when set.
  final double? width;

  /// Horizontal placement of the header label and of the cell content:
  /// start / left, center, end / right (justify behaves as start).
  final TextAlign align;

  /// Builds the content of this column's cell for [row].
  final Widget Function(BuildContext context, T row) cellBuilder;

  const CardTableColumn({
    required this.label,
    required this.cellBuilder,
    this.flex = 1,
    this.width,
    this.align = TextAlign.start,
  })  : assert(flex > 0, "flex must be > 0"),
        assert(width == null || width > 0, "width must be > 0");

  /// Single-line text cell (ellipsis) showing `text(row)`, styled by
  /// [emphasis].
  factory CardTableColumn.text({
    required String label,
    required String Function(T row) text,
    CardTableEmphasis emphasis = CardTableEmphasis.muted,
    int flex = 1,
    double? width,
    TextAlign align = TextAlign.start,
  }) {
    return CardTableColumn<T>(
      label: label,
      flex: flex,
      width: width,
      align: align,
      cellBuilder: (BuildContext context, T row) => _TextCell(
        text: text(row),
        emphasis: emphasis,
        align: align,
      ),
    );
  }

  /// Alignment matching [align] inside the cell.
  AlignmentGeometry get _alignment {
    return switch (align) {
      TextAlign.start || TextAlign.justify => AlignmentDirectional.centerStart,
      TextAlign.end => AlignmentDirectional.centerEnd,
      TextAlign.center => Alignment.center,
      TextAlign.left => Alignment.centerLeft,
      TextAlign.right => Alignment.centerRight,
    };
  }

  /// Wraps [child] in this column's slot: a fixed-width box or an
  /// [Expanded] share, with the content aligned by [align].
  Widget _slot(Widget child) {
    final Widget aligned = Align(alignment: _alignment, child: child);
    final double? fixed = width;
    if (fixed != null) return SizedBox(width: fixed, child: aligned);
    return Expanded(flex: flex, child: aligned);
  }
}

/// Lays [columns] out in a row, building each cell with [cell] and leaving a
/// [kDefaultPadding] gap between columns.
List<Widget> _columnSlots<T>(
  List<CardTableColumn<T>> columns,
  Widget Function(CardTableColumn<T> column) cell,
) {
  final List<Widget> slots = <Widget>[];
  for (final CardTableColumn<T> column in columns) {
    if (slots.isNotEmpty) slots.add(const SizedBox(width: kDefaultPadding));
    slots.add(column._slot(cell(column)));
  }
  return slots;
}
