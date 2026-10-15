// models.dart
//
// Value classes of ComparisonPanel: one side of the summary header
// (ComparisonSide), one comparison row mapped onto ComparisonBar
// (ComparisonMetric) and the optional "from → to" callout (ComparisonChange).

part of "index.dart";

/// One side of the [ComparisonPanel] summary header.
@immutable
final class ComparisonSide {
  /// Short tag above the title (rendered uppercased in the header) and label
  /// of the side in the legend (rendered as given).
  final String tag;

  /// Main line (item name). One line, ellipsis.
  final String title;

  /// Optional secondary line, already formatted by the host. Null hides it.
  final String? subtitle;

  const ComparisonSide({required this.tag, required this.title, this.subtitle});
}

/// One row of the [ComparisonPanel] detail section, rendered as a
/// [ComparisonBar] (current value = baseline, candidate value = comparison).
@immutable
final class ComparisonMetric {
  /// Row label (left column).
  final String label;

  /// Optional second line under [label] (unit, reading hint…).
  final String? sublabel;

  /// Value of the current side.
  final double current;

  /// Value of the candidate side.
  final double candidate;

  /// Lower bound of the scale.
  final double min;

  /// Upper bound of the scale. Must be greater than [min].
  final double max;

  /// True when a lower raw value is better (the axis is flipped so that
  /// right still reads as better).
  final bool lowerIsBetter;

  /// Formats a raw value for display (for example `"${v.round()}%"`).
  final String Function(double value) format;

  const ComparisonMetric({
    required this.label,
    required this.current,
    required this.candidate,
    required this.max,
    required this.format,
    this.sublabel,
    this.min = 0,
    this.lowerIsBetter = false,
  }) : assert(max > min, "max must be greater than min");
}

/// A "label : from → to" highlight shown under the metrics of a
/// [ComparisonPanel].
@immutable
final class ComparisonChange {
  /// What changes (for example "Main constraint").
  final String label;

  /// Value before the change (current side).
  final String from;

  /// Value after the change (candidate side).
  final String to;

  /// Leading icon of the callout.
  final IconData icon;

  const ComparisonChange({
    required this.label,
    required this.from,
    required this.to,
    this.icon = Icons.check_circle_outline,
  });
}
