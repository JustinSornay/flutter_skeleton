// index.dart
//
// ValueMatrix — a sortable rows × columns table of numeric values. Each column
// is loaded by an injected async callback, a few columns at a time. The widget
// owns the load lifecycle (Loader, error + retry, empty), the coloured header
// row with a sort arrow, the row-label column, tone-tinted value cells and an
// optional CSV export bar.
//
// Value classes live in values.dart, state in view_model.dart, the tree in
// view.dart, the row ordering and CSV building in controllers/matrix_table.dart
// and the header, rows, cells, export bar and state messages in widgets/.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/utils/formatters/intl_locale.dart";
import "package:flutter_skeleton/utils/load_state.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";
import "package:logger/logger.dart";

part "controllers/matrix_table.dart";
part "values.dart";
part "view.dart";
part "view_model.dart";
part "widgets/body_row.dart";
part "widgets/export_bar.dart";
part "widgets/header_row.dart";
part "widgets/state_message.dart";
part "widgets/value_cell.dart";

/// Sortable rows × columns table of numeric values loaded column by column.
///
/// - [rows]: row ids and labels in display order. A row with no value in any
///   column is hidden; values for ids that are not listed are ignored.
/// - [columns]: column ids, labels and optional captions in display order.
/// - [loadColumn]: returns every value of one column as `rowId → value`. It
///   is called once per column on mount, on retry, and when the row ids or
///   the column ids change. Any throw puts the whole matrix in its error
///   state (`custom.value_matrix.load_error` + a `custom.value_matrix.retry`
///   button). Results of a superseded load are dropped. To reload with new
///   query parameters but the same ids, give the widget a new `Key`.
/// - [maxConcurrent]: maximum number of [loadColumn] calls in flight; the
///   columns are loaded in chunks of that size. Must be > 0.
/// - [rowHeaderLabel]: text of the corner cell and first CSV header (empty
///   when null).
/// - [formatValue]: cell and CSV text of a value. Defaults to intl
///   `NumberFormat("0.00")` for the ambient locale.
/// - [toneOf]: tint of a value cell: tone `container` fill with tone
///   `onContainer` text. Null leaves every cell untinted (`cs.onSurface`
///   text). The value text always pairs with the colour.
/// - [onExport]: receives a `;`-separated CSV (header + visible rows in the
///   current sort order, RFC 4180 quoting) when the export button is tapped.
///   Null hides the export bar. Errors thrown by the callback are the host's.
///
/// Tapping a column header sorts by that column: descending first, a second
/// tap reverses. Rows without a value in that column always go last and
/// equal values keep the [rows] order. A missing cell shows "—".
///
/// Every row is [kMinTapTarget] tall. The table scrolls in both directions,
/// so the widget needs a parent with a bounded height (`Column` + `Expanded`,
/// as for `Listing`). It uses no overlay.
final class ValueMatrix extends StatefulWidget {
  /// Rows in display order.
  final List<ValueMatrixRow> rows;

  /// Columns in display order.
  final List<ValueMatrixColumn> columns;

  /// Loads every value of the column [ValueMatrixColumn.id] as
  /// `rowId → value`.
  final Future<Map<String, double>> Function(String columnId) loadColumn;

  /// Maximum number of [loadColumn] calls in flight.
  final int maxConcurrent;

  /// Corner cell text and first CSV header; empty when null.
  final String? rowHeaderLabel;

  /// Cell and CSV text of a value; defaults to `NumberFormat("0.00")`.
  final String Function(double value)? formatValue;

  /// Tone of a value cell; null leaves the cells untinted.
  final StatusTone Function(double value)? toneOf;

  /// Receives the CSV export; null hides the export bar.
  final Future<void> Function(String csv)? onExport;

  /// Width of the row-label column.
  final double firstColumnWidth;

  /// Width of each value column.
  final double columnWidth;

  const ValueMatrix({
    super.key,
    required this.rows,
    required this.columns,
    required this.loadColumn,
    this.maxConcurrent = 2,
    this.rowHeaderLabel,
    this.formatValue,
    this.toneOf,
    this.onExport,
    this.firstColumnWidth = 140,
    this.columnWidth = 90,
  }) : assert(maxConcurrent > 0, "maxConcurrent must be > 0");

  @override
  State<ValueMatrix> createState() => _ValueMatrixState();
}
