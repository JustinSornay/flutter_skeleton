// index.dart
//
// MultiSelectSheet<K> — content for a bottom sheet or a modal that picks
// several values and commits them on confirm: a header (title + live counter
// pill), a capped-height checkbox list of ChoiceOption<K> rows (or an empty
// state) and a full-width confirm button. The pending selection lives in
// view_model.dart, the tree in view.dart and the private pieces in widgets/.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";

part "view_model.dart";
part "view.dart";
part "widgets/option_row.dart";
part "widgets/pill.dart";
part "widgets/sheet_header.dart";

/// Multi-choice panel whose selection stays pending until the user confirms,
/// hosted in a modal bottom sheet or an `AppModal`.
///
/// Renders, top to bottom:
/// - [title] (`textTheme.titleMedium`, w700, `cs.onSurface`, header
///   semantics) and a counter pill (radius 999, `cs.surfaceContainerHighest`
///   fill, 1 dp `cs.outlineVariant` border, `textTheme.labelMedium` w600
///   `cs.onSurfaceVariant`, live region): "count/max" when [max] is set,
///   "count" otherwise;
/// - one checkbox row per entry of [options], in the given order, separated
///   by 1 dp `cs.outlineVariant` dividers, in a list at most 360 dp tall that
///   scrolls beyond that (and shrinks when the host is shorter);
/// - or, when [options] is empty, [emptyLabel] centred
///   (`textTheme.bodyMedium`, `cs.onSurfaceVariant`);
/// - a full-width 48 dp confirm button (radius 10).
///
/// Each row (at least 48 dp tall, one merged semantics node with checked,
/// selected and enabled states) renders these [ChoiceOption] fields:
/// - `label` (`textTheme.bodyMedium`, w500, one line with ellipsis,
///   `cs.onSurface`, `cs.onSurfaceVariant` when the row is disabled);
/// - `trailing`: optional badge pill on the right (radius 4,
///   `cs.surfaceContainerHighest` fill, 1 dp `cs.outlineVariant` border,
///   `textTheme.labelSmall` w500 `cs.onSurfaceVariant`); hidden when null or
///   empty;
/// - `enabled`: `false` disables the row (it keeps its initial checked state
///   and ignores taps);
/// - `semanticsLabel`: replaces the row's spoken text (default: label, then
///   trailing).
///
/// `ChoiceOption.description` and `ChoiceOption.icon` are not rendered.
///
/// Selection starts with the values of [initialSelection] that match an
/// option (compared with `==`), at most [max] of them in iteration order;
/// the other values are dropped, so they are neither counted nor emitted.
/// The selection keeps insertion order. Tapping a row or its checkbox
/// toggles it. Once
/// [max] values are selected, the remaining unchecked rows are disabled
/// until one is unchecked. The confirm button is disabled while nothing is
/// selected and otherwise calls [onConfirm] with a copy of the selection.
/// [initialSelection] is read once, at mount.
///
/// The widget never closes itself: the host dismisses its container in
/// [onConfirm] (`Navigator.of(sheetContext).pop()` for a bottom sheet,
/// `modalProvider.dismiss()` for an `AppModal`); dismissing the container
/// any other way is a cancel.
///
/// Content only: no drag handle, no background, no route handling. Mount it
/// with `showModalBottomSheet(showDragHandle: true, …)` or
/// `ModalProvider.show(AppModal(...))`. It needs a bounded height (both hosts
/// provide one). It paints its own transparent [Material] for the row and
/// button ink. It uses no overlay ([Tooltip], popup), so it has no [Overlay]
/// requirement.
///
/// Built-in strings: `custom.multi_select_sheet.counter` (`{count}`),
/// `custom.multi_select_sheet.counter_max` (`{count}`, `{max}`), and the
/// defaults `custom.multi_select_sheet.empty` / `custom.multi_select_sheet.confirm`
/// (replaced by [emptyLabel] / [confirmLabel]).
final class MultiSelectSheet<K> extends StatefulWidget {
  /// Header text, already localised.
  final String title;

  /// Rows in display order. Values are compared with `==`: use enums, ids or
  /// value types.
  final List<ChoiceOption<K>> options;

  /// Called with the selected values, in selection order, when the confirm
  /// button is pressed. Never called with an empty set; only values of
  /// [options] are emitted, at most [max] of them.
  final ValueChanged<Set<K>> onConfirm;

  /// Values checked at mount (read once). Values that match no option are
  /// dropped, and only the first [max] remaining ones are kept.
  final Set<K> initialSelection;

  /// Maximum number of selected values, or null for no cap.
  final int? max;

  /// Replaces the default empty-state text (`custom.multi_select_sheet.empty`).
  final String? emptyLabel;

  /// Replaces the default confirm label (`custom.multi_select_sheet.confirm`).
  final String? confirmLabel;

  const MultiSelectSheet({
    super.key,
    required this.title,
    required this.options,
    required this.onConfirm,
    this.initialSelection = const <Never>{},
    this.max,
    this.emptyLabel,
    this.confirmLabel,
  }) : assert(max == null || max > 0, "max must be positive");

  @override
  State<MultiSelectSheet<K>> createState() => _MultiSelectSheetState<K>();
}
