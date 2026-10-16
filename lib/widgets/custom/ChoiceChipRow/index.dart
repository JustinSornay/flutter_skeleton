// index.dart
//
// ChoiceChipRow<T> — single-choice selector made of pill-shaped ChoiceChips
// that wrap onto several lines, with an optional small caption above them.
// Options are the shared ChoiceOption<T> (custom/_base). The widget owns no
// state: the host passes selectedValue and reacts to onSelected. The layout
// lives in view.dart, one chip in widgets/option_chip.dart.

import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";

part "view.dart";
part "widgets/option_chip.dart";

/// Wrap of pill-shaped single-choice chips with an optional [label] above.
///
/// Layout: a start-aligned `Column` holding, when [label] is set, the caption
/// (`textTheme.labelSmall`, 9 / w700, letter spacing 1, `cs.onSurfaceVariant`,
/// shown exactly as passed) and a [kDefaultPadding] gap, then a `Wrap` of
/// chips with [kDefaultPadding] between chips and between runs, so wrapped
/// rows of pills stay at least [kDefaultPadding] apart at any text scale.
///
/// Chips are Material [ChoiceChip]s (`StadiumBorder`, compact density, no
/// checkmark, label 12 / w600, at least 50 dp wide) rendering these
/// [ChoiceOption] fields:
/// - `label`: the chip text;
/// - `icon`: an 18 dp leading avatar in the label colour;
/// - `enabled`: `false` greys the chip out (label `cs.onSurface` at 38 %)
///   and ignores taps;
/// - `semanticsLabel`: replaces the spoken label.
///
/// `description` and `trailing` are not rendered.
///
/// Colours come from the `ColorScheme` only: the selected chip has a
/// `cs.primary` fill and border and a `cs.onPrimary` label; the others a
/// `cs.surfaceContainer` fill, a `cs.outlineVariant` border and a
/// `cs.onSurface` label. A disabled chip keeps its fill (a disabled selected
/// chip stays `cs.primary`) and only mutes its label. Screen readers get the
/// selected and enabled states of each chip.
///
/// Every chip has a hit area of at least [kMinTapTarget] × [kMinTapTarget]
/// (48 dp) around its compact visual: taps just above or below the pill
/// select it. The select and enable transitions last
/// `resolveMotion(context, kMotionShort)` and are instant under reduced
/// motion.
///
/// No overlay is used: the row works anywhere, including `Layout`.
///
/// Content strings ([label], option texts) are already localised by the host.
final class ChoiceChipRow<T> extends StatelessWidget with _ViewMixin<T> {
  /// Chips, rendered in the given order.
  final List<ChoiceOption<T>> options;

  /// Currently selected value, compared with `==` to each option's `value`;
  /// when no option matches (for example null with a non-nullable `T`), no
  /// chip is selected. With a nullable `T`, an option whose value is null
  /// (e.g. an "all" choice) is selected by a null [selectedValue].
  final T? selectedValue;

  /// Called with the option's `value` when an enabled chip is tapped,
  /// including the chip that is already selected (the host ignores repeats).
  final ValueChanged<T> onSelected;

  /// Optional small caption above the chips (e.g. "PERIOD"), already
  /// localised and cased by the host.
  final String? label;

  const ChoiceChipRow({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}
