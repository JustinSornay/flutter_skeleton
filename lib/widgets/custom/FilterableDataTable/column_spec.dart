// column_spec.dart
//
// Column declaration of FilterableDataTable: DataTableColumnSpec<T> (header
// label, cell builder, numeric alignment, sortability, header tooltip) and
// its `.delta` shortcut, which renders a signed-change pill
// (widgets/delta_badge.dart).

part of "index.dart";

/// One column of a [FilterableDataTable].
@immutable
final class DataTableColumnSpec<T> {
  /// Header text, already localised (e.g. "Name", "Score", "Δ").
  final String label;

  /// Builds the content of this column's cell for [row].
  final Widget Function(BuildContext context, T row) cellBuilder;

  /// Right-aligns the header and the cells ([DataColumn.numeric]).
  final bool numeric;

  /// When true and [FilterableDataTable.onSort] is set, tapping the header
  /// calls it and the header can show the sort arrow.
  final bool sortable;

  /// Optional header tooltip, e.g. to explain "Δ". Needs an `Overlay`
  /// ancestor (a routed page or a modal).
  final String? tooltip;

  const DataTableColumnSpec({
    required this.label,
    required this.cellBuilder,
    this.numeric = false,
    this.sortable = false,
    this.tooltip,
  });

  /// Numeric, signed-change column showing `value(row)` as a pill.
  ///
  /// - `v > 0` and `v >= neutralThreshold`: `"▲ " + format(|v|)` in the
  ///   success tone.
  /// - `v < 0` and `v <= -neutralThreshold`: `"▼ " + format(|v|)` in the
  ///   danger tone.
  /// - Otherwise (`|v| < neutralThreshold`, zero, or NaN): "—" in
  ///   `cs.onSurfaceVariant`. Zero is neutral even with a threshold of 0.
  ///
  /// Pills use the tone `container` fill and `onContainer` text. Screen
  /// readers hear `custom.filterable_data_table.delta_up` / `delta_down`
  /// (with the formatted `{value}`) or `delta_none` instead of the glyphs.
  ///
  /// [format] receives the absolute value. The default reads it as a
  /// fraction and formats a one-decimal percentage for the ambient locale
  /// (`0.05` → "5.0%" in English, "5,0 %" in French).
  factory DataTableColumnSpec.delta({
    required String label,
    required double Function(T row) value,
    String Function(double absValue)? format,
    double neutralThreshold = 0.02,
    bool sortable = true,
    String? tooltip,
  }) {
    assert(neutralThreshold >= 0, "neutralThreshold must be >= 0");
    return DataTableColumnSpec<T>(
      label: label,
      numeric: true,
      sortable: sortable,
      tooltip: tooltip,
      cellBuilder: (BuildContext context, T row) => _DeltaBadge(
        value: value(row),
        format: format,
        neutralThreshold: neutralThreshold,
      ),
    );
  }
}
