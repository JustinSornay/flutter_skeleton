// index.dart
//
// TrendChart — a time-series line chart for a chronological list of
// (date, value) samples, evenly spaced by index, with axis labels, a
// horizontal grid, an entry animation and a fallback message when there is
// no data or too little. An optional TrendThreshold draws a labelled dashed
// reference line, colours the line by side and marks every adverse crossing.
//
// Value classes live in trend_point.dart and trend_threshold.dart, the pure
// geometry in controllers/trend_geometry.dart, the State in view_model.dart,
// the chart tree in view.dart and the fallback text in widgets/.

import "dart:math" as math;

import "package:easy_localization/easy_localization.dart" hide TextDirection;
import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "controllers/trend_geometry.dart";
part "trend_point.dart";
part "trend_threshold.dart";
part "view_model.dart";
part "view.dart";
part "widgets/trend_message.dart";

/// Line chart of a chronological series of [TrendPoint]s.
///
/// - [points] are plotted in list order (oldest first) at `x = index`, so
///   they are evenly spaced whatever their dates. Values must be finite.
/// - Without [threshold]: one `cs.primary` line, no reference line, no
///   markers.
/// - With [threshold]: a dashed reference line in the warning tone with its
///   label, the line coloured by side and switching colour at the exact
///   interpolated crossing point (favourable runs in
///   [TrendThreshold.favourableTone] foreground, adverse runs in
///   [TrendThreshold.adverseTone] foreground), and a dashed vertical marker
///   (adverse tone, 50 % alpha) with its label on every favourable → adverse
///   crossing. The colour is never the only cue: the side of the labelled
///   reference line and the labelled markers carry the same information.
/// - Line labels stay inside the plot when it has room for them: the
///   reference-line label sits top right, above the line, or under it when
///   the threshold is too close to the top; a marker label sits right of
///   its marker, or left of it near the right edge. Keep them short.
/// - Y axis: [minY] / [maxY] when given, otherwise fitted to the values and
///   the threshold, so the reference line always stays in view. The plot is
///   not clipped: the values and the threshold must lie within explicit
///   bounds (asserted). A zero span is widened (±0.5 around a flat series).
///   [yInterval] sets the label and grid step (null = automatic).
/// - Labels: [xLabelBuilder] defaults to intl `DateFormat.Md`, and
///   [yLabelBuilder] to `NumberFormat.decimalPattern`, both for the ambient
///   locale (the app's `context.locale`; intl's default locale when that
///   locale's data is not loaded). X labels step by 1 up to 10 points, 5 up
///   to 30, else 15. Y labels get 30 dp: keep them short.
/// - [caption]: optional italic footnote under the chart.
/// - No points: [emptyMessage] (default `custom.trend_chart.empty`). Fewer
///   than [minPoints]: [insufficientDataMessage] (default
///   `custom.trend_chart.insufficient_data`). Both are centred italic text,
///   shown instead of the chart.
///
/// The chart is [height] dp tall (plus the caption) and needs a finite
/// parent width. The chart area is a single semantics image node labelled
/// [semanticLabel] (default `custom.trend_chart.semantics`; the host can pass
/// a summary such as "rising from 42 to 88"); axis labels are excluded from
/// semantics and the caption is read as its own text. Touch is disabled. The entry
/// animation (500 ms, `Curves.easeOut`) goes through [resolveMotion], so it
/// is instant under reduced motion.
///
/// Inert and overlay-free (no callbacks, no tooltip): it needs no `Overlay`
/// ancestor.
final class TrendChart extends StatefulWidget {
  /// Samples, oldest first.
  final List<TrendPoint> points;

  /// Optional reference line; null draws a plain single-colour line. Its
  /// value must lie within [minY] / [maxY] when they are given (asserted).
  final TrendThreshold? threshold;

  /// Lower bound of the Y axis; null fits the values and the threshold.
  /// When given, no value nor the threshold may be below it (asserted).
  final double? minY;

  /// Upper bound of the Y axis; null fits the values and the threshold.
  /// When given, no value nor the threshold may be above it (asserted).
  final double? maxY;

  /// Y label and horizontal grid step; null lets the chart choose.
  final double? yInterval;

  /// Y axis label of a value; null uses `NumberFormat.decimalPattern`.
  final String Function(double value)? yLabelBuilder;

  /// X axis label of a date; null uses `DateFormat.Md`.
  final String Function(DateTime date)? xLabelBuilder;

  /// Height of the chart area, caption excluded.
  final double height;

  /// Below this number of points the insufficient-data message is shown.
  final int minPoints;

  /// Optional italic footnote under the chart (already localised).
  final String? caption;

  /// Semantics label of the chart; null uses `custom.trend_chart.semantics`.
  final String? semanticLabel;

  /// Text shown when [points] is empty; null uses `custom.trend_chart.empty`.
  final String? emptyMessage;

  /// Text shown when there are fewer than [minPoints] points; null uses
  /// `custom.trend_chart.insufficient_data`.
  final String? insufficientDataMessage;

  const TrendChart({
    super.key,
    required this.points,
    this.threshold,
    this.minY,
    this.maxY,
    this.yInterval,
    this.yLabelBuilder,
    this.xLabelBuilder,
    this.height = 180,
    this.minPoints = 3,
    this.caption,
    this.semanticLabel,
    this.emptyMessage,
    this.insufficientDataMessage,
  }) : assert(minPoints >= 2, "minPoints must be >= 2"),
       assert(minY == null || maxY == null || minY < maxY, "minY must be < maxY");

  @override
  State<TrendChart> createState() => _TrendChartState();
}
