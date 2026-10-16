// index.dart
//
// StepRangeChart — a read-only categorical step chart. Each column shows its
// value as a flat step across the column width with a dot at its centre;
// adjacent valued columns are joined by vertical connectors. Columns may
// carry a low–high envelope, be locked (wash + lock glyph) or have no value
// (the line breaks). One column can be selected. Background bands on the
// value axis use the shared ValueBand (custom/_base/value_band.dart).
// The tree and the semantics summary live in view.dart; the painter is a
// private part in widgets/step_range_painter.dart and takes its caption
// styles from controllers/caption_style.dart. Value class: StepRangeColumn.

import "dart:math" as math;

import "package:easy_localization/easy_localization.dart" hide TextDirection;
import "package:flutter/foundation.dart" show listEquals;
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/_base/value_band.dart";

part "controllers/caption_style.dart";
part "view.dart";
part "widgets/step_range_painter.dart";

/// One categorical column of a [StepRangeChart], in display order.
@immutable
final class StepRangeColumn {
  /// A column with an optional [value] and an optional [low]–[high]
  /// envelope (both or neither).
  const StepRangeColumn({
    required this.label,
    this.sublabel,
    this.value,
    this.low,
    this.high,
    this.flex = 1,
    this.emphasized = false,
  }) : locked = false,
       assert((low == null) == (high == null), "low and high must be set together"),
       assert(flex > 0, "flex must be positive");

  /// A gated column: muted wash and lock glyph over its slot, value shown as
  /// "—", no step, dot or envelope, never selected.
  const StepRangeColumn.locked({
    required this.label,
    this.sublabel,
    this.flex = 1,
  }) : locked = true,
       value = null,
       low = null,
       high = null,
       emphasized = false,
       assert(flex > 0, "flex must be positive");

  /// Name under the column, already localised.
  final String label;

  /// Small caption under [label], already localised.
  final String? sublabel;

  /// Value on the chart's value axis. Null → no step or dot (the line
  /// breaks), "—" and muted captions.
  final double? value;

  /// Envelope lower bound, in value units.
  final double? low;

  /// Envelope upper bound, in value units.
  final double? high;

  /// Relative width of the column.
  final int flex;

  /// Reference column: larger value caption in `cs.onSurface`.
  final bool emphasized;

  /// Whether the column was built with [StepRangeColumn.locked].
  final bool locked;

  @override
  bool operator ==(Object other) {
    return other is StepRangeColumn &&
        other.label == label &&
        other.sublabel == sublabel &&
        other.value == value &&
        other.low == low &&
        other.high == high &&
        other.flex == flex &&
        other.emphasized == emphasized &&
        other.locked == locked;
  }

  @override
  int get hashCode => Object.hash(label, sublabel, value, low, high, flex, emphasized, locked);
}

/// Step line with per-column low–high envelopes over categorical columns.
///
/// Painted in a fixed 420 × 180 design viewport scaled to the available
/// width (`AspectRatio` 420 / 180; needs a bounded width). Sizes below are
/// viewport units:
/// - a 30-unit gutter on the left holds the [bands] labels, right-aligned and
///   vertically centred in their band, in the band tone `foreground`
///   (`StatusTones.colorsOf(context, band.tone)`), plus
///   `valueFormatter(maxValue)` on the top edge and
///   `valueFormatter(minValue)` on the bottom edge (`cs.onSurfaceVariant`).
/// - the plot area: [bands] filled at their `[from, to)` position
///   (`ValueBand.resolveColor`: tone `container` unless `color`), clipped to
///   [minValue]..[maxValue]; 0.5 `cs.outlineVariant` lines between
///   columns. Empty [bands] leave the plot area plain. Saturated band fills
///   (tone containers) mute the envelopes; pass a lighter `color` if needed.
/// - columns share the plot width by their `flex`. The selected column gets
///   a halo ([color] at 6 %). A column with `low` / `high` gets an envelope
///   across its width ([color] at 15 % fill, 40 % 0.5 outline). A locked
///   column gets a `cs.surfaceContainerHighest` wash (90 %) with a
///   `cs.outlineVariant` outline and a centred lock glyph
///   (`cs.onSurfaceVariant`).
/// - the step line (2.5, [color]) draws one flat segment per valued
///   column across its full width, with a vertical connector where the next
///   column also has a value; locked and valueless columns break it. Dots
///   sit at the column centres: radius 3.5 `cs.surface` with a [color] ring, or
///   4.5 filled [color] with a `cs.surface` ring when selected.
/// - under each column: [StepRangeColumn.label] (9 / w700), the optional
///   sublabel (7 / w600) and the formatted value (10 / w800, tabular
///   figures; 11 when selected or emphasized). Captions are
///   `cs.onSurfaceVariant`, [color] for the selected column (name w800),
///   `cs.onSurface` for an emphasized value, and `cs.onSurfaceVariant` at
///   50 % with "—" as value for locked and valueless columns
///   ([StepRangeCaptions] holds these choices). An empty sublabel or band
///   label is not painted.
///
/// Values and envelopes are mapped linearly from [minValue]..[maxValue] and
/// clamped to the plot. Text sizes are design-viewport units based on
/// `textTheme.labelSmall`; they scale with the width, not with the text
/// scale factor — the semantics summary carries every caption.
///
/// Accessibility: one semantics node whose label joins with ". ":
/// [semanticLabel] (when non-empty); the scale
/// (`custom.step_range_chart.axis`, the formatted [minValue] and
/// [maxValue]); one `custom.step_range_chart.band` entry per painted band
/// label (non-empty label, band overlapping the axis), with its bounds
/// clamped to the axis; then one entry per column:
/// `custom.step_range_chart.value` (or `.locked` / `.unavailable`), then
/// `custom.step_range_chart.range` when the column has an envelope and
/// `custom.step_range_chart.selected` for the selected column. The column
/// name is `label (sublabel)`.
///
/// Read-only: no gestures. No `Overlay` ancestor is needed.
final class StepRangeChart extends StatelessWidget with _ViewMixin {
  /// Columns in display order; at least one (asserted at build time).
  final List<StepRangeColumn> columns;

  /// Index of the highlighted column, or null. Ignored when it points at a
  /// locked or valueless column; must be within [columns].
  final int? selectedIndex;

  /// Background bands on the value axis. Fields used: `from`, `to`, `tone`,
  /// `color`, `label` (painted in the gutter and announced).
  final List<ValueBand> bands;

  /// Bottom of the value axis.
  final double minValue;

  /// Top of the value axis. Must be greater than [minValue].
  final double maxValue;

  /// Formats the column values, the axis and band bounds, and the semantics
  /// values. Defaults to the value rounded to an integer.
  final String Function(double value)? valueFormatter;

  /// Line, dots, envelopes, halo and selected captions. Defaults to
  /// `cs.primary`.
  final Color? color;

  /// Chart title prefixed to the semantics summary, already localised.
  final String? semanticLabel;

  const StepRangeChart({
    super.key,
    required this.columns,
    this.selectedIndex,
    this.bands = const <ValueBand>[],
    this.minValue = 0,
    this.maxValue = 100,
    this.valueFormatter,
    this.color,
    this.semanticLabel,
  }) : assert(minValue < maxValue, "minValue must be less than maxValue");

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}
