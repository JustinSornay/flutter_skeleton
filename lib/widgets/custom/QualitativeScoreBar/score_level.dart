// score_level.dart
//
// ScoreLevel — one step of a QualitativeScoreBar scale (lower bound, label,
// StatusTone), plus the pure ScoreLevel.resolve that maps a value to its step.
// No UI here; view.dart reads the resolved level.

part of "index.dart";

/// One step of a [QualitativeScoreBar] scale: from [min] upward (until the
/// next step), the bar shows [label] in [tone].
@immutable
final class ScoreLevel {
  /// Inclusive lower bound, in `[0, 1]`.
  final double min;

  /// Text shown for this step, already localised by the host.
  final String label;

  /// Tone of the label and the bar fill (its `foreground`).
  final StatusTone tone;

  const ScoreLevel({
    required this.min,
    required this.label,
    this.tone = StatusTone.neutral,
  });

  /// The step of [levels] matching [value].
  ///
  /// [value] is clamped to `[0, 1]` (NaN counts as 0). Returns the step with
  /// the greatest [min] `<=` the value, or the step with the lowest [min] when
  /// none matches. The order of [levels] does not matter; among steps with
  /// the same [min], the first one wins. Throws an [ArgumentError] when
  /// [levels] is empty.
  static ScoreLevel resolve(List<ScoreLevel> levels, double value) {
    if (levels.isEmpty) {
      throw ArgumentError.value(levels, "levels", "must not be empty");
    }
    final double v = value.isNaN ? 0 : value.clamp(0.0, 1.0);
    ScoreLevel lowest = levels.first;
    ScoreLevel? match;
    for (final ScoreLevel level in levels) {
      if (level.min < lowest.min) lowest = level;
      if (level.min <= v && (match == null || level.min > match.min)) {
        match = level;
      }
    }
    return match ?? lowest;
  }
}
