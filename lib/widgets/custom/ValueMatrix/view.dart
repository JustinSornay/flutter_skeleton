// view.dart
//
// UI of ValueMatrix: an exhaustive switch on the load state. Idle / Loading →
// centred Loader; LoadError → error message + retry; Loaded with no visible
// row → empty message; Loaded → the table (header row + body rows) in a
// horizontal + vertical scroll view filling the height, then the export bar
// when onExport is set.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, _ValueMatrixState state) {
    return switch (state._state) {
      Idle<Map<String, Map<String, double>>>() || Loading<Map<String, Map<String, double>>>() => const Center(
          child: Padding(
            padding: EdgeInsets.all(kDefaultPadding * 4),
            child: Loader(),
          ),
        ),
      LoadError<Map<String, Map<String, double>>>() => _StateMessage.error(onRetry: state.retry),
      Loaded<Map<String, Map<String, double>>>(:final Map<String, Map<String, double>> data) =>
        _loaded(context, state, state.table(data)),
    };
  }

  Widget _loaded(BuildContext context, _ValueMatrixState state, ValueMatrixTable table) {
    final List<ValueMatrixRow> rows = state.orderedRows(table);
    if (rows.isEmpty) return const _StateMessage.empty();

    final ValueMatrix widget = state.widget;
    final String Function(double value) format = state.formatter(context);
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _HeaderRow(
                    columns: widget.columns,
                    rowHeaderLabel: widget.rowHeaderLabel,
                    firstColumnWidth: widget.firstColumnWidth,
                    columnWidth: widget.columnWidth,
                    sortAscendingOf: state.sortAscendingOf,
                    onSort: state.sortBy,
                  ),
                  for (final ValueMatrixRow row in rows)
                    _BodyRow(
                      label: row.label,
                      values: widget.columns
                          .map((ValueMatrixColumn column) => table.valueOf(row.id, column.id))
                          .toList(growable: false),
                      format: format,
                      toneOf: widget.toneOf,
                      firstColumnWidth: widget.firstColumnWidth,
                      columnWidth: widget.columnWidth,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (widget.onExport != null) _ExportBar(onPressed: () => state.export(table)),
      ],
    );
  }
}
