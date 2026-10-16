// header_row.dart
//
// _HeaderRow — the cs.surfaceContainerHigh header of CardTable: one
// _HeaderLabel per column, laid out with the same slots as the body rows.
// _HeaderLabel — the uppercased micro-label of one column, exposed as a
// semantic header carrying the label as written; blank for an empty label.

part of "../index.dart";

/// Font size of the header micro-labels.
const double _headerFontSize = 9;

/// Tracking of the header micro-labels.
const double _headerLetterSpacing = 0.6;

final class _HeaderRow<T> extends StatelessWidget {
  /// Columns from left to right.
  final List<CardTableColumn<T>> columns;

  const _HeaderRow({required this.columns});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: _rowPadding,
        child: Row(
          children: _columnSlots<T>(
            columns,
            (CardTableColumn<T> column) => _HeaderLabel(label: column.label, align: column.align),
          ),
        ),
      ),
    );
  }
}

final class _HeaderLabel extends StatelessWidget {
  /// Column label as written by the host.
  final String label;

  final TextAlign align;

  const _HeaderLabel({required this.label, required this.align});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    final ThemeData theme = Theme.of(context);
    return Semantics(
      container: true,
      header: true,
      label: label,
      excludeSemantics: true,
      child: Text(
        label.toUpperCase(),
        textAlign: align,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: _headerFontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: _headerLetterSpacing,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
