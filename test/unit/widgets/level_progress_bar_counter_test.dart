// level_progress_bar_counter_test.dart
//
// Unit tests for LevelProgressCounter
// (lib/widgets/custom/LevelProgressBar/controllers/level_counter.dart): the
// split around the first {count}, {total} / {label} substitution on both
// sides, trimming of the outer whitespace an empty label leaves, the
// no-placeholder fallback, repeated {count}, placeholder-like label text and
// the plain text joined back.

import "package:flutter_skeleton/widgets/custom/LevelProgressBar/index.dart";
import "package:flutter_test/flutter_test.dart";

const String _default = "{count}/{total} {label}";

/// The three runs of [counter], for one-line comparisons.
List<String> _runs(LevelProgressCounter counter) => <String>[counter.before, counter.count, counter.after];

void main() {
  group("split around {count}", () {
    test("count first: nothing before, total and label after", () {
      final LevelProgressCounter counter = LevelProgressCounter.of(_default, count: 9, total: 12, label: "items");

      expect(_runs(counter), <String>["", "9", "/12 items"]);
      expect(counter.text, "9/12 items");
    });

    test("count in the middle: placeholders filled on both sides", () {
      final LevelProgressCounter counter = LevelProgressCounter.of(
        "{label}: {count} of {total}",
        count: 3,
        total: 5,
        label: "steps",
      );

      expect(_runs(counter), <String>["steps: ", "3", " of 5"]);
    });

    test("count last: everything before", () {
      final LevelProgressCounter counter = LevelProgressCounter.of("{total} max, now {count}", count: 2, total: 4);

      expect(_runs(counter), <String>["4 max, now ", "2", ""]);
    });

    test("only the first {count} is emphasised; later ones are plain text", () {
      final LevelProgressCounter counter = LevelProgressCounter.of("{count} ({count}/{total})", count: 1, total: 2);

      expect(_runs(counter), <String>["", "1", " (1/2)"]);
    });
  });

  group("label", () {
    test("null label: the trailing space is trimmed", () {
      final LevelProgressCounter counter = LevelProgressCounter.of(_default, count: 9, total: 12);

      expect(_runs(counter), <String>["", "9", "/12"]);
      expect(counter.text, "9/12");
    });

    test("empty label at the start: the leading space is trimmed", () {
      final LevelProgressCounter counter = LevelProgressCounter.of(
        "{label} {count}/{total}",
        count: 1,
        total: 3,
        label: "",
      );

      expect(_runs(counter), <String>["", "1", "/3"]);
    });

    test("inner whitespace is kept", () {
      final LevelProgressCounter counter = LevelProgressCounter.of("{count} / {total}", count: 1, total: 3);

      expect(_runs(counter), <String>["", "1", " / 3"]);
    });

    test("placeholder-like text in the label is kept verbatim", () {
      final LevelProgressCounter counter = LevelProgressCounter.of(
        _default,
        count: 1,
        total: 2,
        label: "{count} {total}",
      );

      expect(counter.text, "1/2 {count} {total}");
    });
  });

  group("template without {count}", () {
    test("gives a single plain run with the other placeholders filled", () {
      final LevelProgressCounter counter = LevelProgressCounter.of(" of {total} {label} ", count: 1, total: 2);

      expect(_runs(counter), <String>["of 2", "", ""]);
    });

    test("a raw translation key is kept as is", () {
      final LevelProgressCounter counter = LevelProgressCounter.of(
        "custom.level_progress_bar.counter",
        count: 1,
        total: 2,
        label: "items",
      );

      expect(_runs(counter), <String>["custom.level_progress_bar.counter", "", ""]);
      expect(counter.text, "custom.level_progress_bar.counter");
    });
  });
}
