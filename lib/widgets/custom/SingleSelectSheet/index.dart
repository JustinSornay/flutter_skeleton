// index.dart
//
// SingleSelectSheet<T> — content for a bottom sheet or a modal that picks
// exactly one value and commits it on confirm: a header (title + close
// button), an optional section label, one radio row per ChoiceOption<T> and a
// cancel / confirm action bar. The pending selection lives in
// view_model.dart, the tree in view.dart and the private pieces in widgets/.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";

part "view_model.dart";
part "view.dart";
part "widgets/action_bar.dart";
part "widgets/option_row.dart";
part "widgets/sheet_header.dart";

/// Single-choice panel whose selection stays pending until the user confirms,
/// hosted in a modal bottom sheet or an `AppModal`.
///
/// Renders, top to bottom:
/// - [title] (`textTheme.titleMedium`, w800, `cs.onSurface`, header
///   semantics) and a 48 dp close button;
/// - a divider, then a scrolling body with the optional [sectionLabel]
///   (`textTheme.labelSmall`, w700, `cs.onSurfaceVariant`) and one radio row
///   per entry of [options], in the given order;
/// - a divider and the action bar: an outlined cancel button (flex 1) and a
///   filled confirm button (flex 2), both 48 dp tall.
///
/// Each row (radius 10, at least 48 dp tall, one semantics node that is a
/// button in a mutually exclusive group with a checked state) renders these
/// [ChoiceOption] fields:
/// - `label` (`textTheme.bodyMedium`, w700 when selected, w600 otherwise,
///   `cs.onSurface`);
/// - `trailing`: optional short hint aligned right (`textTheme.bodySmall`,
///   w600), `cs.primary` when the row is selected, `cs.onSurfaceVariant`
///   otherwise; one line, at most half of the row width, ellipsized when
///   longer; hidden when null or empty;
/// - `enabled`: `false` dims the row to 38 % and ignores taps;
/// - `semanticsLabel`: replaces the row's spoken text (default: label, then
///   trailing).
///
/// `ChoiceOption.description` and `ChoiceOption.icon` are not rendered.
///
/// The selected row has a `cs.primary` 8 % background, a 1.5 dp `cs.primary`
/// border and a checked radio icon in `cs.primary`; the others have a 1 dp
/// `cs.outlineVariant` border and an unchecked `cs.onSurfaceVariant` icon.
///
/// Selection starts at [initialValue] (compared with `==`) when it is the
/// value of one of [options]; otherwise no row is checked. Tapping a row
/// only moves the pending selection. The confirm button calls [onConfirm]
/// with it, and stays disabled while nothing is selected ([initialValue]
/// null or not among [options], and no tap yet). The close and cancel
/// buttons call [onCancel]. The widget never closes itself: the host
/// dismisses its container in both callbacks
/// (`Navigator.of(sheetContext).pop()` for a bottom sheet,
/// `modalProvider.dismiss()` for an `AppModal`).
///
/// Content only: no drag handle, no background, no route handling. Mount it
/// with `showModalBottomSheet(showDragHandle: true, …)` or
/// `ModalProvider.show(AppModal(...))`. It needs a bounded height (both hosts
/// provide one); the rows scroll when it is too short. It paints its own
/// transparent [Material] for the button and row ink.
///
/// The close button has a [Tooltip]: the widget needs an [Overlay] ancestor
/// (a routed page or a modal).
///
/// Built-in strings: `custom.single_select_sheet.close` (close tooltip),
/// `custom.single_select_sheet.cancel` and `custom.single_select_sheet.confirm`
/// (default button labels, replaced by [cancelLabel] / [confirmLabel]).
final class SingleSelectSheet<T extends Object> extends StatefulWidget {
  /// Header text, already localised.
  final String title;

  /// Optional small label above the rows; omitted when null.
  final String? sectionLabel;

  /// Rows in display order. Values are compared with `==`: use enums, ids or
  /// value types.
  final List<ChoiceOption<T>> options;

  /// Initially selected value. Null or a value not among [options] leaves
  /// every row unchecked and confirm disabled until a tap.
  final T? initialValue;

  /// Called with the pending selection when the confirm button is pressed.
  final ValueChanged<T> onConfirm;

  /// Called by the close button and the cancel button.
  final VoidCallback onCancel;

  /// Replaces the default confirm label (`custom.single_select_sheet.confirm`).
  final String? confirmLabel;

  /// Replaces the default cancel label (`custom.single_select_sheet.cancel`).
  final String? cancelLabel;

  const SingleSelectSheet({
    super.key,
    required this.title,
    required this.options,
    required this.onConfirm,
    required this.onCancel,
    this.sectionLabel,
    this.initialValue,
    this.confirmLabel,
    this.cancelLabel,
  });

  @override
  State<SingleSelectSheet<T>> createState() => _SingleSelectSheetState<T>();
}
