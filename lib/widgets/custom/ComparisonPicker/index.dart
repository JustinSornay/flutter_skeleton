// index.dart
//
// ComparisonPicker — list where the user assigns up to two items to slot A
// (the reference) and slot B (the comparison). A primary group comes first;
// an optional secondary group (suggestions) sits under a labelled dashed
// divider, with an optional add button and a pulsing loading placeholder
// (SkeletonPulse + SkeletonBlock). The value class lives in models.dart, the
// selection in view_model.dart, the tree in view.dart and the private pieces
// in widgets/.

import "dart:math" as math;

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/core/decorators/SkeletonPulse/index.dart";
import "package:flutter_skeleton/widgets/custom/SkeletonBlock/index.dart";

part "models.dart";
part "view_model.dart";
part "view.dart";
part "widgets/add_button.dart";
part "widgets/dashed_divider.dart";
part "widgets/loading_rows.dart";
part "widgets/picker_row.dart";
part "widgets/slot_controls.dart";
part "widgets/slot_header.dart";

/// Called after every selection change with the ids held by slot A and
/// slot B (null = empty slot).
typedef ComparisonSlotsChanged = void Function(String? slotA, String? slotB);

/// Picks up to two items to compare side by side: slot A (the reference,
/// `cs.primary`) and slot B (the comparison, `cs.tertiary`), e.g. two
/// products, plans or configurations.
///
/// Layout, top to bottom:
/// - In radio mode only, a header aligned on the radio columns: an "A" badge
///   (`cs.primary`, letter `cs.onPrimary`), a "B" badge (`cs.tertiary`,
///   letter `cs.onTertiary`) and the optional [headerLabel]
///   (`cs.onSurfaceVariant`).
/// - One row per [primary] item.
/// - The secondary section, shown when [secondary] is not empty, when
///   [secondaryLoading] is true or when the add button is shown: a dashed
///   `cs.outline` divider labelled [secondaryLabel], the add button, then one
///   row per [secondary] item, or 3 pulsing `SkeletonBlock` rows while
///   [secondaryLoading] is true.
///
/// Rows (radius 8, at least [kMinTapTarget] tall) render the
/// [ComparisonPickerItem] fields: `label` (bold), `subtitle` (muted second
/// line), and `valueLabel` at the end, drawn in a `StatusTones` pill with the
/// tone icon when `tone` is set (`toneLabel` names the tone for screen
/// readers, or is the pill text when there is no `valueLabel`), or as plain
/// bold text otherwise. The value takes at most half of the text width and
/// ends with an ellipsis when longer. The row
/// holding slot A is filled with `cs.primaryContainer` and bordered
/// `cs.primary`; slot B uses `cs.tertiaryContainer` / `cs.tertiary`; the
/// others use `cs.surface` / `cs.outlineVariant`.
///
/// Two modes, chosen from the length of [primary]:
/// - **Locked A** (exactly one primary item): slot A is that item (unless
///   [initialSlotA] names another one). The primary row cannot be tapped;
///   its slot-A dot is filled while it holds slot A and an empty ring
///   otherwise. Tapping a whole secondary row toggles slot B; tapping the
///   row holding slot A moves slot A to slot B, leaving slot A empty.
/// - **Radio** (0 or 2+ primary items): every row has an A radio and a B
///   radio, each with a 48 × 48 hit area. Tapping a selected radio empties
///   the slot; the radio of the other slot on a row that already holds one
///   slot is disabled (dimmed, forbidden cursor). Picking an item for a slot
///   moves that slot.
///
/// The selection lives in the widget, starts from [initialSlotA] /
/// [initialSlotB] and is reported through [onChanged] after every change
/// (never at mount). Give the widget a new key to reset it. The mode follows
/// the current length of [primary], but the locked-A default of slot A is
/// applied at mount only: give a new key when [primary] changes length.
///
/// Accessibility: each radio is one semantics node in a mutually exclusive
/// group with a checked and an enabled state, labelled
/// `custom.comparison_picker.select_a` / `select_b` ("Select {label} as A");
/// a locked-A secondary row is one such node labelled `select_b`; the
/// locked slot-A dot reads `custom.comparison_picker.locked_a` while the
/// primary row holds slot A; each row's texts, value and `toneLabel` merge
/// into one node; the add button is a button node; the loading rows read
/// `custom.comparison_picker.loading` (a generic "Loading").
///
/// Built-in strings: `custom.comparison_picker.slot_a` / `slot_b` (header
/// badges), `secondary` and `add` (defaults of [secondaryLabel] and
/// [addLabel]), plus the semantics labels above.
///
/// The widget never navigates: [onChanged] and [onAdd] do. Each row and the
/// add button carry their own [Material], so no `Material` ancestor is
/// needed, and no `Overlay` ancestor is needed either (no tooltip). It sizes
/// to its content: the host scrolls it.
final class ComparisonPicker extends StatefulWidget {
  /// Items listed first. Exactly one item switches to locked-A mode.
  final List<ComparisonPickerItem> primary;

  /// Items listed under the dashed divider (e.g. suggestions). May be empty.
  final List<ComparisonPickerItem> secondary;

  /// Called after every change with the slot A id and the slot B id.
  final ComparisonSlotsChanged onChanged;

  /// Initial slot A id. In locked-A mode, null means `primary.first.id`.
  final String? initialSlotA;

  /// Initial slot B id.
  final String? initialSlotB;

  /// Column title next to the A / B badges in radio mode (e.g. "Product"),
  /// already localised. Null shows the badges only.
  final String? headerLabel;

  /// Divider text. Null shows `custom.comparison_picker.secondary`.
  final String? secondaryLabel;

  /// Shows the outlined add button at the top of the secondary section when
  /// set (hidden when [readOnly]).
  final VoidCallback? onAdd;

  /// Add button text. Null shows `custom.comparison_picker.add`.
  final String? addLabel;

  /// Disables every radio and row tap and hides the add button.
  final bool readOnly;

  /// Shows 3 pulsing placeholder rows instead of [secondary]. Under reduced
  /// motion the rows are static.
  final bool secondaryLoading;

  const ComparisonPicker({
    super.key,
    required this.primary,
    required this.onChanged,
    this.secondary = const <ComparisonPickerItem>[],
    this.initialSlotA,
    this.initialSlotB,
    this.headerLabel,
    this.secondaryLabel,
    this.onAdd,
    this.addLabel,
    this.readOnly = false,
    this.secondaryLoading = false,
  });

  @override
  State<ComparisonPicker> createState() => _ComparisonPickerState();
}
