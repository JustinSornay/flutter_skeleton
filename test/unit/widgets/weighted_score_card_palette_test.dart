// weighted_score_card_palette_test.dart
//
// Unit tests for WeightedScorePalette
// (lib/widgets/custom/WeightedScoreCard/controllers/component_palette.dart):
// every entry of the default colour cycle reaches the WCAG 1.4.11 non-text
// floor (3:1) against the card surface and the slider track in
// AppTheme.light() and AppTheme.dark(), the entries are distinct, and the
// documented order holds.

import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/custom/WeightedScoreCard/index.dart";
import "package:flutter_test/flutter_test.dart";

/// WCAG 2.x contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  final Map<String, ThemeData> themes = <String, ThemeData>{
    "light": AppTheme.light(),
    "dark": AppTheme.dark(),
  };

  themes.forEach((String name, ThemeData theme) {
    group("cycle ($name)", () {
      final ColorScheme cs = theme.colorScheme;
      final List<Color> cycle = WeightedScorePalette.cycle(cs);

      for (int i = 0; i < cycle.length; i++) {
        test("entry $i on surface >= 3:1", () {
          expect(_contrast(cycle[i], cs.surface), greaterThanOrEqualTo(3));
        });

        test("entry $i on surfaceContainerHighest >= 3:1", () {
          expect(_contrast(cycle[i], cs.surfaceContainerHighest), greaterThanOrEqualTo(3));
        });
      }

      test("has seven distinct colours", () {
        expect(cycle, hasLength(7));
        expect(cycle.toSet(), hasLength(7));
      });

      test("follows the documented order", () {
        expect(cycle, <Color>[
          cs.primary,
          cs.tertiary,
          cs.secondary,
          cs.error,
          cs.onPrimaryContainer,
          cs.onTertiaryContainer,
          cs.outline,
        ]);
      });
    });
  });
}
