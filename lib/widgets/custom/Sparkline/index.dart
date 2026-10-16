// index.dart
//
// Sparkline — compact inline trend line for an ordered numeric series (a
// metric history in a table cell, a list tile or a summary tile). No axes,
// grid, dots, fill, touch or entry animation. Declares the widget and the
// pure Y-range rule ([Sparkline.yRange]); the chart tree lives in view.dart.

import "dart:math" as math;

import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "view.dart";

/// Compact inline trend line for an ordered numeric series.
///
/// - Each value of [values] (oldest first) is plotted at `x = index` and the
///   points are joined by straight segments with round caps, [strokeWidth]
///   thick, in [color] (default `cs.primary`).
/// - No axes, grid, border, dots, area fill, touch handling or entry
///   animation (the chart is drawn at once, so there is nothing to slow down
///   under reduced motion).
/// - Y axis: [minY] / [maxY] when given, otherwise fitted to the data (see
///   [yRange]). When a value falls outside that range the line is clipped
///   to the box. Otherwise nothing is clipped, so the stroke and its round
///   caps keep their full width at the box edges (up to half the stroke is
///   drawn just outside the box).
/// - Fewer than 2 values: an empty box of the same [width] × [height], so
///   rows and columns stay aligned.
///
/// Colour: the line colour alone carries no meaning for the widget. A host
/// that maps a status to it (e.g. `StatusTones.colorsOf(context, tone)
/// .foreground`) keeps that status in nearby text or an icon.
///
/// Accessibility: decorative by default — the subtree is excluded from
/// semantics, for when nearby text already gives the value. With
/// [semanticsLabel] it is a single image node carrying that label (also when
/// the series is too short, so the host can announce "no data").
///
/// Inert and overlay-free (no callbacks, no tooltip): it needs no `Overlay`
/// ancestor.
final class Sparkline extends StatelessWidget with _ViewMixin {
  /// Ordered series, oldest first. Each value is plotted at x = its index.
  /// Values must be finite (checked by a debug assert at build time).
  final List<double> values;

  /// Line colour. Null means `Theme.of(context).colorScheme.primary`.
  final Color? color;

  /// Lower bound of the Y axis. Null means it is fitted to the data.
  final double? minY;

  /// Upper bound of the Y axis. Null means it is fitted to the data.
  final double? maxY;

  /// Box width (default 56 = 7 × kDefaultPadding).
  final double width;

  /// Box height (default 24 = 3 × kDefaultPadding).
  final double height;

  /// Line thickness in logical pixels.
  final double strokeWidth;

  /// Accessible description, e.g. "Trend: rising from 42 to 88" (already
  /// localised by the host). Null means decorative: excluded from semantics.
  final String? semanticsLabel;

  const Sparkline({
    super.key,
    required this.values,
    this.color,
    this.minY,
    this.maxY,
    this.width = kDefaultPadding * 7,
    this.height = kDefaultPadding * 3,
    this.strokeWidth = 1.5,
    this.semanticsLabel,
  }) : assert(minY == null || maxY == null || minY < maxY);

  /// The Y range that is actually plotted.
  ///
  /// `lo = minY ?? min(values)`, `hi = maxY ?? max(values)` (an empty series
  /// counts as 0). When `hi <= lo` (flat series, or data entirely beyond a
  /// one-sided bound) the open bound is widened so the span is never zero:
  /// - both open → `(lo - 0.5, hi + 0.5)`, a flat line sits in the middle;
  /// - only [minY] open → `lo = hi - 1`;
  /// - otherwise → `hi = lo + 1`.
  ({double min, double max}) get yRange {
    final double dataMin = values.isEmpty ? 0 : values.reduce(math.min);
    final double dataMax = values.isEmpty ? 0 : values.reduce(math.max);
    final double lo = minY ?? dataMin;
    final double hi = maxY ?? dataMax;
    if (hi > lo) return (min: lo, max: hi);
    if (minY == null && maxY == null) return (min: lo - 0.5, max: hi + 0.5);
    if (minY == null) return (min: hi - 1, max: hi);
    return (min: lo, max: lo + 1);
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}
