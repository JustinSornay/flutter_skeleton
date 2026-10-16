// comparison_bar_readout_test.dart
//
// Unit tests for ComparisonBarReadout
// (lib/widgets/custom/ComparisonBar/controllers/readout_template.dart):
// splitting a readout template into literal and placeholder runs, unknown
// placeholders, missing placeholders and the fallback of resolve().

import "package:flutter_skeleton/widgets/custom/ComparisonBar/index.dart";
import "package:flutter_test/flutter_test.dart";

const Set<String> _changed = <String>{ComparisonBarReadout.baseline, ComparisonBarReadout.comparison};
const Set<String> _unchanged = <String>{ComparisonBarReadout.value};

void main() {
  group("split", () {
    test("splits placeholders and literal runs in order", () {
      expect(
        ComparisonBarReadout.split("{baseline} → {comparison}", _changed),
        <ComparisonBarReadoutPart>[
          (placeholder: "baseline", text: "{baseline}"),
          (placeholder: null, text: " → "),
          (placeholder: "comparison", text: "{comparison}"),
        ],
      );
    });

    test("keeps leading and trailing literal text", () {
      expect(
        ComparisonBarReadout.split("from {baseline} to {comparison}.", _changed),
        <ComparisonBarReadoutPart>[
          (placeholder: null, text: "from "),
          (placeholder: "baseline", text: "{baseline}"),
          (placeholder: null, text: " to "),
          (placeholder: "comparison", text: "{comparison}"),
          (placeholder: null, text: "."),
        ],
      );
    });

    test("supports a reversed order", () {
      final List<ComparisonBarReadoutPart>? parts = ComparisonBarReadout.split("{comparison} ← {baseline}", _changed);

      expect(parts?.map((ComparisonBarReadoutPart part) => part.placeholder), <String?>["comparison", null, "baseline"]);
    });

    test("leaves unknown placeholders as literal text", () {
      expect(
        ComparisonBarReadout.split("{value} {unit} =", _unchanged),
        <ComparisonBarReadoutPart>[
          (placeholder: "value", text: "{value}"),
          (placeholder: null, text: " {unit} ="),
        ],
      );
    });

    test("joining the runs gives back the template", () {
      const String template = "{baseline} → {comparison}";
      final List<ComparisonBarReadoutPart>? parts = ComparisonBarReadout.split(template, _changed);

      expect(parts?.map((ComparisonBarReadoutPart part) => part.text).join(), template);
    });

    test("returns null when a placeholder is missing", () {
      expect(ComparisonBarReadout.split("custom.comparison_bar.readout", _changed), isNull);
      expect(ComparisonBarReadout.split("{baseline} →", _changed), isNull);
    });
  });

  group("resolve", () {
    test("uses the template when it has every placeholder", () {
      expect(
        ComparisonBarReadout.resolve("{value} (=)", ComparisonBarReadout.unchangedFallback, _unchanged),
        <ComparisonBarReadoutPart>[
          (placeholder: "value", text: "{value}"),
          (placeholder: null, text: " (=)"),
        ],
      );
    });

    test("falls back when the template is an untranslated key", () {
      expect(
        ComparisonBarReadout.resolve("custom.comparison_bar.readout", ComparisonBarReadout.changedFallback, _changed),
        ComparisonBarReadout.split(ComparisonBarReadout.changedFallback, _changed),
      );
      expect(
        ComparisonBarReadout.resolve("custom.comparison_bar.readout_unchanged", ComparisonBarReadout.unchangedFallback, _unchanged),
        <ComparisonBarReadoutPart>[
          (placeholder: "value", text: "{value}"),
          (placeholder: null, text: " ="),
        ],
      );
    });
  });
}
