// index.dart
//
// ComparisonBar — one compact row comparing a baseline value and a comparison
// value of the same metric on a bounded scale: a label column, a track with
// two dots joined by a gradient segment, and a localized
// "baseline → comparison" readout whose connector carries the direction tone.
// The row lives in view.dart; the track and the readout are private parts in
// widgets/; the readout template splitter is in controllers/.

import "dart:math" as math;

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "controllers/readout_template.dart";
part "view.dart";
part "widgets/comparison_readout.dart";
part "widgets/comparison_track.dart";

/// Share of the range under which both values count as unchanged (0.5 %).
const double _unchangedTolerance = 0.005;

/// One-row comparison of [baselineValue] and [comparisonValue] on the
/// [min]..[max] scale.
///
/// Renders, left to right:
/// - a [labelWidth] column with [label] (11 / w700, `cs.onSurface`, two lines
///   max, ellipsis) and the optional [sublabel] (9 / w600,
///   `cs.onSurfaceVariant`);
/// - a 14 dp track area: a 5 dp track (`cs.surfaceContainerHighest`, radius
///   999), a segment between the dots filled with a gradient from one dot
///   colour to the other in position order, then two 10 dp dots ringed 2 dp
///   with `cs.surface` — [baselineColor] first, [comparisonColor] on top;
/// - a [valueWidth] readout, scaled down when it does not fit:
///   `custom.comparison_bar.readout` ("{baseline} → {comparison}") with the
///   baseline value in [baselineColor] (w700), the comparison value in
///   [comparisonColor] (w800) and the connector in the direction tone
///   foreground (`StatusTone.success` when the comparison is better,
///   `StatusTone.danger` when it is worse), followed by the tone's
///   [StatusTone.icon] (10 dp, same foreground) so the direction never relies
///   on colour alone. When both values differ by less than 0.5 % of the raw
///   range it shows `custom.comparison_bar.readout_unchanged` ("{value} =",
///   muted italic connector), no icon and no segment.
///
/// The dots are clamped to the track; the readout always shows
/// [formatValue] of the raw values, and better / worse / unchanged are
/// decided on the raw values too. The axis reads "right = better": with
/// [lowerIsBetter] it is flipped. The direction is carried without colour by
/// the tone icon and by the semantics text.
///
/// Accessibility: the row is one semantics node labelled
/// `custom.comparison_bar.semantics_better` / `semantics_worse` (`label`,
/// `from`, `to`) or `semantics_unchanged` (`label`, `value`), where `label`
/// is "label (sublabel)" when a [sublabel] is set. The glyphs of the readout
/// are not read out.
///
/// Needs a bounded width. No `Overlay` ancestor is needed. [label] and
/// [sublabel] are already localised by the host.
final class ComparisonBar extends StatelessWidget with _ViewMixin {
  /// Main label, in the left column.
  final String label;

  /// Optional second line under [label] (unit, reading hint…).
  final String? sublabel;

  /// Reference value: first dot, left part of the readout.
  final double baselineValue;

  /// Value compared with the baseline: second dot, right part of the readout.
  final double comparisonValue;

  /// Lower bound of the scale (left end, or right end when [lowerIsBetter]).
  final double min;

  /// Upper bound of the scale. Must be greater than [min].
  final double max;

  /// True when a lower value is better: flips the axis so that right still
  /// reads as better, and flips the direction tone of the readout connector.
  final bool lowerIsBetter;

  /// Formats a raw value for the readout and the semantics label.
  final String Function(double value) formatValue;

  /// Colour of the baseline dot, value and gradient end. Null →
  /// `cs.onSurfaceVariant`.
  final Color? baselineColor;

  /// Colour of the comparison dot, value and gradient end. Null →
  /// `cs.primary`.
  final Color? comparisonColor;

  /// Width of the label column.
  final double labelWidth;

  /// Width of the readout column.
  final double valueWidth;

  const ComparisonBar({
    super.key,
    required this.label,
    required this.baselineValue,
    required this.comparisonValue,
    required this.max,
    required this.formatValue,
    this.min = 0,
    this.sublabel,
    this.lowerIsBetter = false,
    this.baselineColor,
    this.comparisonColor,
    this.labelWidth = 108,
    this.valueWidth = 80,
  }) : assert(max > min, "max must be greater than min");

  /// Position of [value] on the track, `0..1` from the left: clamped, and
  /// flipped when [lowerIsBetter].
  double _positionOf(double value) {
    final double fraction = (value.clamp(min, max) - min) / (max - min);
    return lowerIsBetter ? 1 - fraction : fraction;
  }

  double get _baselinePosition => _positionOf(baselineValue);

  double get _comparisonPosition => _positionOf(comparisonValue);

  /// True when the raw values (not the clamped dot positions) differ by less
  /// than 0.5 % of the range.
  bool get _isUnchanged {
    return (comparisonValue - baselineValue).abs() < (max - min) * _unchangedTolerance;
  }

  /// True when [comparisonValue] is better than [baselineValue].
  bool get _isBetter {
    return lowerIsBetter ? comparisonValue < baselineValue : comparisonValue > baselineValue;
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}
