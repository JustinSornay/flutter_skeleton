// index.dart
//
// FilterableDataTable<T, F> — controlled data-table card: a titled header
// with the row count, an optional row of single-choice filter chips
// (ChoiceChipRow, "all" first) and a horizontally scrolling, sortable
// Material DataTable whose columns the caller declares (DataTableColumnSpec,
// column_spec.dart). The host filters and sorts the rows. The card lives in
// view.dart; the header, table and delta pill (a StatusPill) in widgets/.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/utils/formatters/intl_locale.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/ChoiceChipRow/index.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";

part "column_spec.dart";
part "view.dart";
part "widgets/delta_badge.dart";
part "widgets/header.dart";
part "widgets/table.dart";

/// Controlled, sortable, filterable data-table card for rows of type [T],
/// filtered by values of type [F] (use a non-nullable [F]: null means "all").
///
/// The widget owns no state. The host passes the rows already filtered and
/// sorted, plus the current sort and filter, and reacts to [onSort] and
/// [onFilterChanged].
///
/// Layout, top to bottom, inside a card (`cs.surface`, 1 dp
/// `cs.outlineVariant` border, radius 10, content clipped to the shape):
/// - Header strip (`cs.surfaceContainerLow`, `cs.outlineVariant` bottom
///   border, padding 16 / 8): [title] as given (10 / w700, letter spacing
///   0.8, `cs.onSurfaceVariant`) then `rows.length` (10 / w500). The strip is
///   one semantics header node.
/// - Filter chips, only when [filters] is not empty: a [ChoiceChipRow] with
///   an "all" chip first ([allFilterLabel], default
///   `custom.filterable_data_table.all`), then one chip per option in the
///   given order. It renders the [ChoiceOption] fields `label`, `icon`,
///   `enabled` and `semanticsLabel`. The chips wrap onto several lines.
/// - When [rows] is empty: [emptyMessage] (default
///   `custom.filterable_data_table.empty`, 13 sp, `cs.onSurfaceVariant`). The
///   header and the chips stay visible so the user can change the filter.
/// - Otherwise a Material [DataTable] in a horizontal scroll view: one
///   column per [DataTableColumnSpec], one row per item, heading 11 / w600
///   `cs.onSurfaceVariant`, cells 13 sp `cs.onSurface`, column spacing 16.
///   Every row is built eagerly: use `Listing` for long or paginated data.
///
/// Sorting: a header with [DataTableColumnSpec.sortable] calls
/// [onSort] with its index and the toggled direction. The sort arrow is drawn
/// on [sortColumnIndex] only when that column is sortable and [onSort] is
/// set (a Material [DataTable] limitation), so a read-only table shows no
/// order indicator. Headers are [kMinTapTarget] tall when a column is
/// sortable and [onSort] is set, 40 dp otherwise; each sortable header is
/// also at least [kMinTapTarget] wide.
///
/// Rows: with [onRowTap] set, tapping a row calls it with the row's item,
/// rows are at least [kMinTapTarget] tall and every column is at least
/// [kMinTapTarget] wide; no checkbox column is ever shown. Rows are as tall
/// as their tallest cell, with a 40 dp minimum otherwise.
///
/// Tones: the table resolves no colours itself. Cells are built by the
/// caller; the built-in [DataTableColumnSpec.delta] column only picks a
/// [StatusTone] (success / danger) for a `StatusPill`, always with an arrow
/// glyph and a value.
///
/// Overlay: a column with a [DataTableColumnSpec.tooltip] wraps its header
/// in a [Tooltip], which **needs an `Overlay` ancestor** (a routed page or a
/// modal, not `Layout`). Without tooltips no Overlay is needed.
///
/// Content strings ([title], labels, [emptyMessage], [allFilterLabel]) are
/// already localised by the host.
final class FilterableDataTable<T, F> extends StatelessWidget with _ViewMixin<T, F> {
  /// Header overline, rendered exactly as given (the host picks the case).
  final String title;

  /// Rows to display, already filtered and sorted by the host. The header
  /// shows `rows.length`.
  final List<T> rows;

  /// Column definitions, left to right (must not be empty; asserted when the
  /// table builds, so the constructor stays const).
  final List<DataTableColumnSpec<T>> columns;

  /// Index in [columns] of the sorted column; null for none. Its header
  /// shows the sort arrow only when it is sortable and [onSort] is set.
  final int? sortColumnIndex;

  /// Direction of the arrow on [sortColumnIndex].
  final bool sortAscending;

  /// Called with `(columnIndex, ascending)` when a sortable header is
  /// tapped. Null makes every header inert.
  final void Function(int columnIndex, bool ascending)? onSort;

  /// Filter options after the "all" chip, usually computed by the host from
  /// the unfiltered data so chips do not disappear while a filter is active.
  /// Empty hides the chip row.
  final List<ChoiceOption<F>> filters;

  /// Currently selected filter value; null selects the "all" chip.
  final F? selectedFilter;

  /// Receives the tapped option's value, or null for the "all" chip and when
  /// the selected chip is tapped again. Required when [filters] is not empty
  /// (asserted when the table builds).
  final ValueChanged<F?>? onFilterChanged;

  /// Label of the "all" chip (e.g. for grammatical agreement); defaults to
  /// `"custom.filterable_data_table.all".tr()`.
  final String? allFilterLabel;

  /// Text shown when [rows] is empty; defaults to
  /// `"custom.filterable_data_table.empty".tr()`.
  final String? emptyMessage;

  /// Called with the tapped row's item. Null makes rows non-interactive.
  final ValueChanged<T>? onRowTap;

  const FilterableDataTable({
    super.key,
    required this.title,
    required this.rows,
    required this.columns,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.filters = const <Never>[],
    this.selectedFilter,
    this.onFilterChanged,
    this.allFilterLabel,
    this.emptyMessage,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}
