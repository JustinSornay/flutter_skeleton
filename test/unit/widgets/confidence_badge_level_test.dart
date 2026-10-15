// confidence_badge_level_test.dart
//
// Unit tests for ConfidenceBadge.levelOf (lib/widgets/custom/ConfidenceBadge/
// index.dart): the default and custom thresholds, equal thresholds, clamping,
// NaN, the tone of each ConfidenceLevel and the threshold-order assertion.

import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/ConfidenceBadge/index.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("ConfidenceBadge.levelOf", () {
    test("default thresholds: >= 0.8 high, >= 0.5 moderate, else low", () {
      expect(ConfidenceBadge.levelOf(1.0), ConfidenceLevel.high);
      expect(ConfidenceBadge.levelOf(0.8), ConfidenceLevel.high);
      expect(ConfidenceBadge.levelOf(0.7999), ConfidenceLevel.moderate);
      expect(ConfidenceBadge.levelOf(0.5), ConfidenceLevel.moderate);
      expect(ConfidenceBadge.levelOf(0.4999), ConfidenceLevel.low);
      expect(ConfidenceBadge.levelOf(0.0), ConfidenceLevel.low);
    });

    test("custom thresholds move the boundaries", () {
      expect(ConfidenceBadge.levelOf(0.95, highAt: 0.9, moderateAt: 0.6), ConfidenceLevel.high);
      expect(ConfidenceBadge.levelOf(0.85, highAt: 0.9, moderateAt: 0.6), ConfidenceLevel.moderate);
      expect(ConfidenceBadge.levelOf(0.55, highAt: 0.9, moderateAt: 0.6), ConfidenceLevel.low);
    });

    test("equal thresholds leave no moderate band", () {
      expect(ConfidenceBadge.levelOf(0.7, highAt: 0.7, moderateAt: 0.7), ConfidenceLevel.high);
      expect(ConfidenceBadge.levelOf(0.69, highAt: 0.7, moderateAt: 0.7), ConfidenceLevel.low);
    });

    test("out-of-range values are clamped and NaN counts as 0", () {
      expect(ConfidenceBadge.levelOf(-0.2), ConfidenceLevel.low);
      expect(ConfidenceBadge.levelOf(1.5), ConfidenceLevel.high);
      expect(ConfidenceBadge.levelOf(double.nan), ConfidenceLevel.low);
    });
  });

  test("each level exposes its tone", () {
    expect(ConfidenceLevel.high.tone, StatusTone.success);
    expect(ConfidenceLevel.moderate.tone, StatusTone.warning);
    expect(ConfidenceLevel.low.tone, StatusTone.danger);
  });

  test("moderateAt above highAt is rejected", () {
    expect(() => ConfidenceBadge(value: 0.5, highAt: 0.4, moderateAt: 0.6), throwsAssertionError);
  });
}
