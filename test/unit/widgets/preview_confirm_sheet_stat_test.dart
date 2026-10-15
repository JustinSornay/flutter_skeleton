// preview_confirm_sheet_stat_test.dart
//
// Unit tests for PreviewStat (PreviewConfirmSheet value class): constructor
// defaults and the PreviewStat.delta factory (epsilon, sign, tone,
// higherIsBetter, fractionDigits, semanticsLabel).

import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/PreviewConfirmSheet/index.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("the default constructor is untoned, not tinted, without a semantics label", () {
    const PreviewStat stat = PreviewStat(label: "Now", value: "0.72");

    expect(stat.label, "Now");
    expect(stat.value, "0.72");
    expect(stat.tone, isNull);
    expect(stat.tinted, isFalse);
    expect(stat.semanticsLabel, isNull);
  });

  group("PreviewStat.delta", () {
    test("a change below epsilon renders '=' in the neutral tone, tinted", () {
      for (final double delta in <double>[0, 0.004, -0.004, 0.0049]) {
        final PreviewStat stat = PreviewStat.delta(label: "Change", delta: delta);
        expect(stat.value, "=", reason: "delta $delta");
        expect(stat.tone, StatusTone.neutral, reason: "delta $delta");
        expect(stat.tinted, isTrue, reason: "delta $delta");
      }
    });

    test("a positive change is '+x.xx' and good by default", () {
      final PreviewStat stat = PreviewStat.delta(label: "Change", delta: 0.05);

      expect(stat.label, "Change");
      expect(stat.value, "+0.05");
      expect(stat.tone, StatusTone.success);
      expect(stat.tinted, isTrue);
    });

    test("a negative change is '-x.xx' and bad by default", () {
      final PreviewStat stat = PreviewStat.delta(label: "Change", delta: -0.05);

      expect(stat.value, "-0.05");
      expect(stat.tone, StatusTone.danger);
      expect(stat.tinted, isTrue);
    });

    test("higherIsBetter: false flips the tones but not the signs", () {
      final PreviewStat up = PreviewStat.delta(label: "Change", delta: 0.05, higherIsBetter: false);
      final PreviewStat down = PreviewStat.delta(label: "Change", delta: -0.05, higherIsBetter: false);

      expect(up.value, "+0.05");
      expect(up.tone, StatusTone.danger);
      expect(down.value, "-0.05");
      expect(down.tone, StatusTone.success);
    });

    test("the epsilon boundary itself counts as a change", () {
      expect(PreviewStat.delta(label: "Change", delta: 0.005).tone, StatusTone.success);
      expect(PreviewStat.delta(label: "Change", delta: -0.005).tone, StatusTone.danger);
    });

    test("fractionDigits sets the decimals", () {
      expect(PreviewStat.delta(label: "Change", delta: 0.12, fractionDigits: 1).value, "+0.1");
      expect(PreviewStat.delta(label: "Change", delta: -3, fractionDigits: 0).value, "-3");
      expect(PreviewStat.delta(label: "Change", delta: 0.125, fractionDigits: 3).value, "+0.125");
    });

    test("a custom epsilon is respected", () {
      expect(PreviewStat.delta(label: "Change", delta: 0.4, epsilon: 0.5).value, "=");
      expect(PreviewStat.delta(label: "Change", delta: 0.5, epsilon: 0.5).value, "+0.50");
      expect(PreviewStat.delta(label: "Change", delta: 0.001, epsilon: 0.0001).value, "+0.00");
    });

    test("semanticsLabel is passed through", () {
      expect(PreviewStat.delta(label: "Change", delta: 0.05, semanticsLabel: "Up, good").semanticsLabel, "Up, good");
      expect(PreviewStat.delta(label: "Change", delta: 0, semanticsLabel: "No change").semanticsLabel, "No change");
      expect(PreviewStat.delta(label: "Change", delta: 0.05).semanticsLabel, isNull);
    });
  });
}
