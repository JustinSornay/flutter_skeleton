// header_row.dart
//
// _HeaderRow — the cs.primary header of ValueMatrix: the corner cell (the
// optional row header label) then one _HeaderCell per column.
// _HeaderCell — a kMinTapTarget-tall InkWell showing the column label, the
// optional caption and, on the sort column, an up / down arrow. One button
// semantics node: full label, sort hint and the sorted direction as value.

part of "../index.dart";

final class _HeaderRow extends StatelessWidget {
  /// Columns in display order.
  final List<ValueMatrixColumn> columns;

  /// Corner cell text; nothing when null.
  final String? rowHeaderLabel;

  final double firstColumnWidth;

  final double columnWidth;

  /// Sort direction of a column id; null when it is not the sort column.
  final bool? Function(String columnId) sortAscendingOf;

  /// Header tap with the column id.
  final ValueChanged<String> onSort;

  const _HeaderRow({
    required this.columns,
    required this.rowHeaderLabel,
    required this.firstColumnWidth,
    required this.columnWidth,
    required this.sortAscendingOf,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? corner = rowHeaderLabel;

    return Row(
      children: <Widget>[
        Container(
          width: firstColumnWidth,
          height: kMinTapTarget,
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: cs.primary,
            border: Border(
              right: BorderSide(color: cs.outlineVariant),
              bottom: BorderSide(color: cs.outlineVariant),
            ),
          ),
          child: corner == null
              ? null
              : Text(
                  corner,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onPrimary),
                ),
        ),
        for (final ValueMatrixColumn column in columns)
          _HeaderCell(
            column: column,
            width: columnWidth,
            sortAscending: sortAscendingOf(column.id),
            onTap: () => onSort(column.id),
          ),
      ],
    );
  }
}

final class _HeaderCell extends StatelessWidget {
  final ValueMatrixColumn column;

  final double width;

  /// Sort direction; null when this is not the sort column.
  final bool? sortAscending;

  final VoidCallback onTap;

  const _HeaderCell({
    required this.column,
    required this.width,
    required this.sortAscending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool? ascending = sortAscending;
    final String? caption = column.caption;

    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      label: column.fullLabel,
      hint: "custom.value_matrix.sort_hint".tr(),
      value: _sortedValue(ascending),
      onTap: onTap,
      child: Material(
        color: cs.primary,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: width,
            height: kMinTapTarget,
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: cs.outlineVariant, width: 0.5),
                bottom: BorderSide(color: cs.outlineVariant),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    column.label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onPrimary),
                  ),
                  if (caption != null && caption.isNotEmpty)
                    Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w400, color: cs.onPrimary),
                    ),
                  if (ascending != null)
                    Icon(
                      ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 12,
                      color: cs.onPrimary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String? _sortedValue(bool? ascending) {
    if (ascending == null) return null;
    return ascending ? "custom.value_matrix.sorted_ascending".tr() : "custom.value_matrix.sorted_descending".tr();
  }
}
