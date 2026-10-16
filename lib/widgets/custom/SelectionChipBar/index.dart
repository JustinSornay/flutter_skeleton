// index.dart
//
// SelectionChipBar<T> — floating "selection tray" listing the selected
// entries (ChoiceOption<T>) as removable chips next to one primary action
// button (compare, export, delete…). It slides and fades in while the list is
// non-empty and owns no state: the host passes the items and reacts to
// onRemove / onAction. The bar lives in view.dart, the chip and its remove
// button in widgets/.

import "dart:math" as math;

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";

part "view.dart";
part "widgets/item_chip.dart";
part "widgets/remove_button.dart";

/// Floating bar listing the selected [items] as chips plus one action button.
///
/// Visibility: while [items] is non-empty the bar sits in place, fully
/// opaque. When [items] is empty it slides down by its own height and fades
/// out; from that frame on (not only once the fade ends) it is inert: it
/// ignores pointers, cannot take keyboard focus (focus held by the action is
/// dropped) and is excluded from semantics, even with `minItems: 0`. Slide
/// (`easeOutCubic`) and fade use `resolveMotion(context, kMotionShort)` and are
/// instant under reduced motion.
///
/// Bar: `Material(cs.inverseSurface, elevation 6, cs.shadow, radius 12)`
/// with 2× / 1.5× [kDefaultPadding] outer margin. The chips wrap onto several
/// lines when needed; the action button stays on the right. The button is
/// capped so that at least 120 dp (15× [kDefaultPadding], one removable chip
/// with a short label) stays for the chips: a longer [actionLabel] is
/// ellipsised on one line, and its full text is still announced.
///
/// Chips (`cs.secondaryContainer`, radius 8, text 12 / w600
/// `cs.onSecondaryContainer`) render these [ChoiceOption] fields:
/// - `label`, on one line with an ellipsis;
/// - `icon`, a 16 dp leading icon;
/// - `enabled`: `false` dims the chip to 38 % and disables its remove button;
/// - `semanticsLabel`: replaces the spoken label.
///
/// `description` and `trailing` are not rendered. When [onRemove] is set each
/// chip ends with a 48 dp close button (`Icons.close`, 16 dp) labelled
/// `custom.selection_chip_bar.remove` (`{label}` = the item label).
///
/// Action button: a `FilledButton` (`cs.primary` / `cs.onPrimary`, at least
/// 48 × 48, radius 8, text 13 / w700, one line) showing [actionLabel]. It is enabled
/// only when [onAction] is set and `items.length >= minItems`.
///
/// The remove button shows a [Tooltip], so **the bar needs an `Overlay`
/// ancestor** (a routed page or a modal) whenever [onRemove] is set: mount it
/// in a page (for example at the bottom of a `Stack`), not in `Layout`, which
/// sits above the Navigator.
///
/// Content strings ([actionLabel], item texts) are already localised by the
/// host.
final class SelectionChipBar<T> extends StatelessWidget with _ViewMixin<T> {
  /// Selected entries, rendered in the given order. Empty hides the bar.
  final List<ChoiceOption<T>> items;

  /// Text of the action button (e.g. "Compare"), already localised.
  final String actionLabel;

  /// Called with the item's `value` when its remove button is tapped. Null
  /// renders read-only chips without a remove button.
  final ValueChanged<T>? onRemove;

  /// Called when the action button is tapped. Null keeps the button disabled.
  final VoidCallback? onAction;

  /// The action button is enabled once `items.length >= minItems` (and
  /// [onAction] is set). A comparison typically passes 2.
  final int minItems;

  const SelectionChipBar({
    super.key,
    required this.items,
    required this.actionLabel,
    this.onRemove,
    this.onAction,
    this.minItems = 1,
  }) : assert(minItems >= 0);

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}
