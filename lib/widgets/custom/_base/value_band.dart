// value_band.dart
//
// ValueBand — a shared band [from, to) on a widget's value axis (range bars,
// step charts, value axes). Its fill comes from a StatusTone
// (theme/status_tones.dart) unless an explicit data-palette colour is given.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";

/// A coloured band between [from] and [to] on a value axis.
@immutable
final class ValueBand {
  const ValueBand({
    required this.from,
    required this.to,
    this.tone = StatusTone.neutral,
    this.color,
    this.label,
  }) : assert(from < to);

  /// Lower bound, in the widget's value units.
  final double from;

  /// Upper bound, in the widget's value units.
  final double to;

  /// Fill tone: [ToneColors.container] unless [color] is set.
  final StatusTone tone;

  /// Explicit data-palette override for the fill.
  final Color? color;

  /// Short gutter / legend text, also exposed to semantics.
  final String? label;

  /// Fill colour of the band in the current theme.
  Color resolveColor(BuildContext context) =>
      color ?? StatusTones.colorsOf(context, tone).container;
}
