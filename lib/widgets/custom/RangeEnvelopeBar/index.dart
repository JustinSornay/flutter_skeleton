// index.dart
//
// RangeEnvelopeBar — horizontal banded scale showing the min–max envelope
// (spread) of one or two series of sample values, with an optional reference
// marker, band captions, endpoint labels and a tone-coded spread pill.
// The tree lives in view.dart; the painter, the caption row and the pill are
// private parts in widgets/. Value class: RangeEnvelopeSeries. Bands use the
// shared ValueBand (custom/_base/value_band.dart).

import "dart:math" as math;

import "package:easy_localization/easy_localization.dart" hide TextDirection;
import "package:flutter/foundation.dart" show listEquals;
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/_base/value_band.dart";

part "view.dart";
part "widgets/envelope_painter.dart";
part "widgets/scale_captions.dart";
part "widgets/spread_pill.dart";

/// A series of sample values drawn by [RangeEnvelopeBar] as a min–max
/// envelope.
@immutable
final class RangeEnvelopeSeries {
  /// Accessible name used in the semantics summary (not painted), already
  /// localised by the host.
  final String label;

  /// Sample values, in the bar's value units. Must not be empty (asserted
  /// when the bar renders: a list check cannot run in a const constructor).
  final List<double> values;

  /// Envelope and tick colour: the tone `foreground` from
  /// `StatusTones.colorsOf(context, tone)`. Ignored when [color] is set.
  /// Both null → `cs.primary` for the primary series, `cs.tertiary` for the
  /// secondary one.
  final StatusTone? tone;

  /// Explicit envelope and tick colour (data palette).
  final Color? color;

  const RangeEnvelopeSeries({
    required this.label,
    required this.values,
    this.tone,
    this.color,
  });

  /// Smallest value.
  double get lowest => values.reduce(math.min);

  /// Largest value.
  double get highest => values.reduce(math.max);

  /// `highest - lowest`; helps the host build a spread label and pick its
  /// tone.
  double get spread => highest - lowest;
}

/// Banded value scale with the min–max envelope of one or two sample series.
///
/// Renders, top to bottom:
/// - a 22 dp bar (radius 4) filled with `cs.surfaceContainerHighest`, then
///   the [bands] painted at their `[from, to)` position on the scale
///   (`ValueBand.resolveColor`: tone `container` unless `color`). Bands
///   outside [min]..[max] are clipped.
/// - single layout ([secondary] null): the [primary] envelope spans the bar
///   height (3 dp inset), filled with the series colour at 28 % opacity and
///   outlined 1 dp, plus one 2 × 6 dp tick per value.
/// - dual layout ([secondary] set): [primary] as a 9 dp envelope in the top
///   half, [secondary] (25 % fill) in the bottom half, no per-value ticks.
/// - when [marker] is set, a 2 dp `cs.inverseSurface` tick through the bar
///   and a pill above it (`cs.onInverseSurface` text, 9 / w800) showing
///   [markerLabel] (default `formatValue(marker)`), kept inside the bar
///   width. 16 dp are reserved above the bar for it; without a marker only
///   2 dp are. The painted pill does not follow the text scale factor; the
///   semantics summary carries its text.
/// - a caption row (8 / w700, `cs.onSurfaceVariant`): each band `label`
///   centred under its band, `formatValue(min)` pinned left and
///   `formatValue(max)` pinned right.
/// - when [spreadLabel] is set, a pill (radius 999, tone `container` fill,
///   `onContainer` text, upper-cased 8 / w800) in [spreadTone]. With fewer
///   than two [primary] values it shows the built-in
///   `custom.range_envelope_bar.insufficient_data` text in the neutral tone
///   instead. The pill always carries text, so the tone is never colour-only.
///
/// Values, bands and the marker are mapped linearly from [min]..[max] to the
/// bar width and clamped to it.
///
/// Accessibility: the painted bar is one semantics node whose label lists,
/// for each series, `custom.range_envelope_bar.semantics_range` (`label`,
/// `min`, `max` formatted with [formatValue]), then the marker text. Captions
/// are plain text; the spread pill is read in its original casing.
///
/// Needs a bounded width. No `Overlay` ancestor is needed. Content strings
/// (series labels, band labels, [markerLabel], [spreadLabel]) are already
/// localised by the host.
final class RangeEnvelopeBar extends StatelessWidget with _ViewMixin {
  /// Main series: full-height envelope with ticks (single layout) or top
  /// half (dual layout).
  final RangeEnvelopeSeries primary;

  /// Second series. Non-null switches to the dual layout (bottom half).
  final RangeEnvelopeSeries? secondary;

  /// Background bands, in value units. Fields used: `from`, `to`, `tone`,
  /// `color`, `label` (caption under the band). Empty → plain track, no band
  /// captions.
  final List<ValueBand> bands;

  /// Value at the left end of the bar.
  final double min;

  /// Value at the right end of the bar. Must be greater than [min].
  final double max;

  /// Reference value drawn as a tick and a pill above the bar. Null → no
  /// marker and no space reserved for it.
  final double? marker;

  /// Marker pill text. Null → `formatValue(marker)`.
  final String? markerLabel;

  /// Text of the pill under the scale (shown upper-cased). Null → no pill.
  final String? spreadLabel;

  /// Tone of the spread pill.
  final StatusTone spreadTone;

  /// Formats the endpoint captions, the default marker text and the values
  /// of the semantics summary. Defaults to the value rounded to an integer.
  final String Function(double value) formatValue;

  const RangeEnvelopeBar({
    super.key,
    required this.primary,
    this.secondary,
    this.bands = const <ValueBand>[],
    this.min = 0,
    this.max = 100,
    this.marker,
    this.markerLabel,
    this.spreadLabel,
    this.spreadTone = StatusTone.neutral,
    this.formatValue = _formatRounded,
  }) : assert(max > min, "max must be greater than min");

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

/// Default [RangeEnvelopeBar.formatValue]: the value rounded to an integer.
String _formatRounded(double value) => value.round().toString();
