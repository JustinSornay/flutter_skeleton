// table.dart
//
// Private table of FilterableDataTable: a Material DataTable in a horizontal
// scroll view, built from the host's DataTableColumnSpecs, with controlled
// sorting, optional row taps (never a checkbox column) and 48 × 48 dp
// targets where the headers or rows are interactive (row height plus a
// minimum column width).

part of "../index.dart";

/// Height of a non-interactive heading row, and minimum height of a
/// non-interactive data row.
const double _compactRowHeight = kDefaultPadding * 5;

/// Width of an interactive column (sortable header, or any column of tappable
/// rows): its content width, but never less than a tap target. The table
/// sits in a horizontal scroll view, so the flex DataTable would give a lone
/// text column has no effect there.
const TableColumnWidth _interactiveColumnWidth = MaxColumnWidth(
  IntrinsicColumnWidth(),
  FixedColumnWidth(kMinTapTarget),
);

/// Heading text size.
const double _headingFontSize = 11;

/// Cell text size.
const double _cellFontSize = 13;

final class _Table<T, F> extends StatelessWidget {
  final FilterableDataTable<T, F> table;

  const _Table({required this.table});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final void Function(int columnIndex, bool ascending)? onSort = table.onSort;
    final bool sortableHeading =
        onSort != null && table.columns.any((DataTableColumnSpec<T> column) => column.sortable);
    final bool tappableRows = table.onRowTap != null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        sortColumnIndex: table.sortColumnIndex,
        sortAscending: table.sortAscending,
        showCheckboxColumn: false,
        headingRowHeight: sortableHeading ? kMinTapTarget : _compactRowHeight,
        dataRowMinHeight: tappableRows ? kMinTapTarget : _compactRowHeight,
        // Unbounded so rows hug their content above the minimum (a bounded
        // maximum makes every cell expand to it).
        dataRowMaxHeight: double.infinity,
        columnSpacing: kDefaultPadding * 2,
        headingTextStyle: theme.textTheme.labelSmall?.copyWith(
          fontSize: _headingFontSize,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
        ),
        dataTextStyle: theme.textTheme.bodyMedium?.copyWith(fontSize: _cellFontSize, color: cs.onSurface),
        columns: <DataColumn>[
          for (final DataTableColumnSpec<T> column in table.columns)
            DataColumn(
              label: Text(column.label),
              numeric: column.numeric,
              tooltip: column.tooltip,
              onSort: column.sortable ? onSort : null,
              columnWidth: tappableRows || (column.sortable && onSort != null) ? _interactiveColumnWidth : null,
            ),
        ],
        rows: <DataRow>[for (final T row in table.rows) _row(context, row)],
      ),
    );
  }

  DataRow _row(BuildContext context, T row) {
    final ValueChanged<T>? onRowTap = table.onRowTap;

    return DataRow(
      onSelectChanged: onRowTap == null ? null : (bool? _) => onRowTap(row),
      cells: <DataCell>[
        for (final DataTableColumnSpec<T> column in table.columns) DataCell(column.cellBuilder(context, row)),
      ],
    );
  }
}
