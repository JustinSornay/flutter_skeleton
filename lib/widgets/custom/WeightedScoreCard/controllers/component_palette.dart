// component_palette.dart
//
// WeightedScorePalette — the ColorScheme colour cycle of WeightedScoreCard
// for components without an explicit colour or tone. Every entry stays
// visible on the card surface and on the slider track (WCAG 1.4.11, 3:1),
// enforced by test/unit/widgets/weighted_score_card_palette_test.dart. Used
// by view.dart; public only for unit tests.

part of "../index.dart";

/// Default component colours of a [WeightedScoreCard], picked by component
/// index modulo the cycle length.
@visibleForTesting
abstract final class WeightedScorePalette {
  /// primary, tertiary, secondary, error, onPrimaryContainer,
  /// onTertiaryContainer, outline.
  ///
  /// Each entry reaches 3:1 against `cs.surface` (card, donut, legend) and
  /// `cs.surfaceContainerHighest` (inactive slider track) in both
  /// brightnesses. The `*Container` roles are deliberately absent: they sit
  /// at about 1:1 against the track.
  static List<Color> cycle(ColorScheme cs) {
    return <Color>[
      cs.primary,
      cs.tertiary,
      cs.secondary,
      cs.error,
      cs.onPrimaryContainer,
      cs.onTertiaryContainer,
      cs.outline,
    ];
  }
}
