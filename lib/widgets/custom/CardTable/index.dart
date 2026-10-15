// index.dart
//
// CardTable<T> — a lightweight table for short lists, drawn as a bordered
// card: an uppercase micro-label header row, then one divider-separated row
// per item, optionally tappable and optionally followed by a full-width
// detail slot. Stateless; the column value classes live in column.dart, the
// tree in view.dart and the header, body rows and empty card in widgets/.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "column.dart";
part "view.dart";
part "widgets/body_row.dart";
part "widgets/empty_card.dart";
part "widgets/header_row.dart";
part "widgets/text_cell.dart";

/// Small table of rows of type [T] drawn as a bordered card, with columns
/// declared by the caller.
///
/// Meant for short, non-paginated lists (dashboard summaries, settings
/// lists…): every row is built eagerly in a [Column], so the card hugs its
/// content height. Use `Listing` for long or paginated data.
///
/// Layout:
/// - Full available width (`width: double.infinity`), so the card needs a
///   bounded width.
/// - Card: `cs.surfaceContainerLowest`, a 1 dp `cs.outlineVariant` border
///   and radius 12. The content is clipped by a [ClipRRect] at the border's
///   inner radius (11), so the header fill and the row ink never paint over
///   the border at the corners. Rows are hosted on a transparent [Material]
///   so their ink stays inside that clip.
/// - Header row: `cs.surfaceContainerHigh`, padding 16 / 8 dp. Each
///   [CardTableColumn.label] is rendered uppercased in a 9 sp w700
///   micro-label (`cs.onSurfaceVariant`, letter-spacing 0.6) and exposed as a
///   semantic header carrying the label as written. An empty label leaves the
///   header cell blank.
/// - Body rows: a `cs.outlineVariant` top border, padding 16 / 8 dp, cells
///   vertically centred. A cell takes [CardTableColumn.width] when set, its
///   [CardTableColumn.flex] share of the remaining width otherwise, with an
///   8 dp gap between columns. [CardTableColumn.align] places both the header
///   label and the cell content.
///
/// Interaction: with [onRowTap] set, each row is an [InkWell] at least
/// [kMinTapTarget] tall whose semantics node is a button; tapping it calls
/// [onRowTap] with the row's item. Interactive widgets inside a cell (an
/// `IconButton`…) win the gesture, so they do not trigger [onRowTap]. With
/// [onRowTap] null, rows are plain content: no ink, no button semantics, no
/// minimum height.
///
/// Semantics: each row is one semantics node. [rowSemanticLabel] gives it a
/// summary read before the cells' own text (the cells are still read, so the
/// summary should not repeat them); nested controls keep their own nodes.
///
/// [rowDetailBuilder] adds a full-width widget (an inline editor, a note…)
/// under a row, inside the same divider block but outside the row's tap
/// target. The host owns which rows show a detail. Since rows are matched by
/// position, give a stateful detail widget a key derived from its item.
///
/// When [rows] is empty, the header is not drawn: a card of the same frame
/// shows [emptyMessage] (12 sp, `cs.onSurfaceVariant`), defaulting to
/// `custom.card_table.empty`.
///
/// Uses no overlay, so the widget works anywhere in the tree.
final class CardTable<T> extends StatelessWidget with _ViewMixin<T> {
  /// Rows in display order. The caller filters and sorts.
  final List<T> rows;

  /// Columns from left to right (must not be empty).
  final List<CardTableColumn<T>> columns;

  /// Called with the tapped row's item. Null makes rows non-interactive.
  final ValueChanged<T>? onRowTap;

  /// Accessible summary of a row, read before the cells' text, which is
  /// still announced after it.
  ///
  /// Give context the cells do not already show (a status, the position, an
  /// action hint), for example "Row 2 of 5, opens the details.". Repeating
  /// the cells' text makes a screen reader read it twice. Null leaves only
  /// the cells' text.
  final String Function(T row)? rowSemanticLabel;

  /// Optional full-width content under a row; return null for none.
  final Widget? Function(BuildContext context, T row)? rowDetailBuilder;

  /// Text shown when [rows] is empty, already localised. Defaults to
  /// `"custom.card_table.empty".tr()`.
  final String? emptyMessage;

  const CardTable({
    super.key,
    required this.rows,
    required this.columns,
    this.onRowTap,
    this.rowSemanticLabel,
    this.rowDetailBuilder,
    this.emptyMessage,
  }) : assert(columns.length > 0, "columns must not be empty");

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}
