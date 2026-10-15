// segment.dart
//
// Value class of DistributionBar: DistributionBarSegment, one slice of the
// breakdown (label, weight, optional tone or explicit colour). No UI here.

part of "index.dart";

/// One slice of a [DistributionBar].
@immutable
final class DistributionBarSegment {
  /// Legend label, already localised by the host.
  final String label;

  /// Finite, non-negative weight. Share = value / sum of all segment values.
  final double value;

  /// Tone whose foreground colours the slice and the legend dot when [color]
  /// is null.
  final StatusTone? tone;

  /// Explicit data-palette colour; wins over [tone].
  final Color? color;

  const DistributionBarSegment({
    required this.label,
    required this.value,
    this.tone,
    this.color,
  }) : assert(value >= 0 && value < double.infinity, "value must be finite and >= 0");
}
