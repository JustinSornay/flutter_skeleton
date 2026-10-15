// matrix_table.dart
//
// ValueMatrixTable — pure data logic of ValueMatrix: pivots the per-column
// load results into rowId → columnId → value, picks the visible rows, sorts
// them by a column (missing values last, ties in row order) and builds the
// ";"-separated CSV with RFC 4180 quoting. No widgets, so it is unit-tested
// on its own.

part of "../index.dart";

/// Row ordering and CSV building of [ValueMatrix].
@visibleForTesting
@immutable
final class ValueMatrixTable {
  /// Rows in display order.
  final List<ValueMatrixRow> rows;

  /// Columns in display order.
  final List<ValueMatrixColumn> columns;

  /// rowId → columnId → value.
  final Map<String, Map<String, double>> values;

  const ValueMatrixTable({required this.rows, required this.columns, required this.values});

  /// Turns `columnId → (rowId → value)` load results into the
  /// `rowId → columnId → value` map of [values].
  static Map<String, Map<String, double>> pivot(Map<String, Map<String, double>> byColumn) {
    final Map<String, Map<String, double>> byRow = <String, Map<String, double>>{};
    byColumn.forEach((String columnId, Map<String, double> column) {
      column.forEach((String rowId, double value) {
        byRow.putIfAbsent(rowId, () => <String, double>{})[columnId] = value;
      });
    });
    return byRow;
  }

  /// Value of [rowId] in [columnId], or null when missing.
  double? valueOf(String rowId, String columnId) => values[rowId]?[columnId];

  /// Rows with at least one value in a listed column, in [rows] order.
  List<ValueMatrixRow> get visibleRows {
    return rows.where(_hasValue).toList(growable: false);
  }

  bool _hasValue(ValueMatrixRow row) {
    return columns.any((ValueMatrixColumn column) => valueOf(row.id, column.id) != null);
  }

  /// [visibleRows] sorted by [columnId]: descending unless [ascending].
  /// Rows without a value in that column go last in both directions and
  /// equal values keep the [rows] order. A null or unknown [columnId] keeps
  /// the [rows] order.
  List<ValueMatrixRow> sortedRows(String? columnId, {required bool ascending}) {
    final List<ValueMatrixRow> visible = visibleRows;
    if (columnId == null || !columns.any((ValueMatrixColumn column) => column.id == columnId)) {
      return visible;
    }
    final List<int> order = List<int>.generate(visible.length, (int index) => index);
    order.sort((int a, int b) {
      final int byValue = _compare(
        valueOf(visible[a].id, columnId),
        valueOf(visible[b].id, columnId),
        ascending: ascending,
      );
      return byValue != 0 ? byValue : a.compareTo(b);
    });
    return order.map((int index) => visible[index]).toList(growable: false);
  }

  /// Missing values last; otherwise by value in the requested direction.
  static int _compare(double? a, double? b, {required bool ascending}) {
    if (a == null || b == null) {
      if (a == b) return 0;
      return a == null ? 1 : -1;
    }
    return ascending ? a.compareTo(b) : b.compareTo(a);
  }

  /// `;`-separated CSV: a header line ([rowHeader], then each column's
  /// [ValueMatrixColumn.fullLabel]) and one line per row of [orderedRows]
  /// (label, then each value through [format], empty when missing). Every
  /// field is quoted per RFC 4180 when it holds `;`, `"`, CR or LF.
  String toCsv(
    List<ValueMatrixRow> orderedRows, {
    required String rowHeader,
    required String Function(double value) format,
  }) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(<String>[
      rowHeader,
      ...columns.map((ValueMatrixColumn column) => column.fullLabel),
    ].map(_field).join(";"));
    for (final ValueMatrixRow row in orderedRows) {
      buffer.writeln(<String>[
        row.label,
        ...columns.map((ValueMatrixColumn column) {
          final double? value = valueOf(row.id, column.id);
          return value == null ? "" : format(value);
        }),
      ].map(_field).join(";"));
    }
    return buffer.toString();
  }

  static final RegExp _needsQuotes = RegExp("[;\"\r\n]");

  static String _field(String text) {
    if (!_needsQuotes.hasMatch(text)) return text;
    return "\"${text.replaceAll("\"", "\"\"")}\"";
  }
}
