// index.dart
//
// OptionPickerSheet<T> — content for a bottom sheet or a modal that picks one
// value immediately: a header and one tappable card per ChoiceOption<T>. The
// current value gets a primary border and a check, the others a chevron. The
// tree lives in view.dart, the card in widgets/option_card.dart.

import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";

part "view.dart";
part "widgets/option_card.dart";

/// Single-choice picker panel, hosted in a modal bottom sheet or an
/// `AppModal`.
///
/// Renders, top to bottom:
/// - [title] (`textTheme.titleMedium`, w700, `cs.onSurface`, header
///   semantics);
/// - one card per entry of [options], in the given order. The list scrolls
///   when the available height is too short.
///
/// Each card (radius 12, at least 72 dp tall, one button semantics node in a
/// mutually exclusive group) renders these [ChoiceOption] fields:
/// - `icon`: optional leading icon (24 dp, `cs.primary`);
/// - `label` (`textTheme.titleSmall`, w700, `cs.onSurface`);
/// - `description`: optional second line (`textTheme.bodySmall`,
///   `cs.onSurfaceVariant`), hidden when null or empty;
/// - `enabled`: `false` dims the card to 38 % and ignores taps;
/// - `semanticsLabel`: replaces the card's spoken text.
///
/// `ChoiceOption.trailing` is not rendered.
///
/// The card whose `value == selected` has a 2 dp `cs.primary` border and a
/// `cs.primary` check icon, and is announced as selected. The other cards
/// have a 1 dp `cs.outlineVariant` border and a `cs.onSurfaceVariant`
/// chevron. A null [selected] highlights nothing.
///
/// The widget never closes itself: [onSelected] runs on every tap of an
/// enabled card, including the one already selected, and the host dismisses
/// its container there (`Navigator.of(sheetContext).pop()` for a bottom
/// sheet, `modalProvider.dismiss()` for an `AppModal`).
///
/// Content only: no drag handle, no background, no route handling. Mount it
/// with `showModalBottomSheet(showDragHandle: true, …)` or
/// `ModalProvider.show(AppModal(...))`. It needs a bounded height (both hosts
/// provide one). It paints its own transparent [Material] for the card ink,
/// has no tooltip or other overlay (no `Overlay` ancestor is needed) and no
/// built-in strings: every text is a parameter, already localised by the
/// host.
final class OptionPickerSheet<T> extends StatelessWidget with _ViewMixin<T> {
  /// Header text.
  final String title;

  /// Cards in display order. Values are compared with `==`: use enums, ids
  /// or value types.
  final List<ChoiceOption<T>> options;

  /// Current value, or null for no highlighted card.
  final T? selected;

  /// Called with the value of the tapped card (enabled cards only).
  final ValueChanged<T> onSelected;

  const OptionPickerSheet({
    super.key,
    required this.title,
    required this.options,
    required this.onSelected,
    this.selected,
  });

  @override
  Widget build(BuildContext context) => render(context, this);
}
