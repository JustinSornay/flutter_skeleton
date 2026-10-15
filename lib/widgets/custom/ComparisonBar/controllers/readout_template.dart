// readout_template.dart
//
// ComparisonBarReadout — splits a localized readout template such as
// "{baseline} → {comparison}" into literal runs and placeholder runs, so the
// view can style each run on its own. Pure string logic, unit-tested in
// test/unit/widgets/comparison_bar_readout_test.dart.

part of "../index.dart";

/// One run of a readout template: a `{name}` placeholder when [placeholder]
/// is set, else literal text. [text] is the run as written in the template.
typedef ComparisonBarReadoutPart = ({String? placeholder, String text});

/// Readout template splitting of [ComparisonBar].
@visibleForTesting
abstract final class ComparisonBarReadout {
  /// Placeholder of the baseline value in the changed readout.
  static const String baseline = "baseline";

  /// Placeholder of the comparison value in the changed readout.
  static const String comparison = "comparison";

  /// Placeholder of the single value in the unchanged readout.
  static const String value = "value";

  /// Used when the changed template lacks a placeholder (missing key).
  static const String changedFallback = "{$baseline} → {$comparison}";

  /// Used when the unchanged template lacks its placeholder (missing key).
  static const String unchangedFallback = "{$value} =";

  static final RegExp _placeholderPattern = RegExp(r"\{(\w+)\}");

  /// Runs of [template], in order. `{name}` becomes a placeholder run when
  /// `name` is in [names]; any other text, unknown `{…}` included, stays
  /// literal. Returns null when a name of [names] is missing from
  /// [template].
  static List<ComparisonBarReadoutPart>? split(String template, Set<String> names) {
    final List<ComparisonBarReadoutPart> parts = <ComparisonBarReadoutPart>[];
    final Set<String> found = <String>{};
    int cursor = 0;
    for (final RegExpMatch match in _placeholderPattern.allMatches(template)) {
      final String? name = match.group(1);
      if (name == null || !names.contains(name)) continue;
      if (match.start > cursor) {
        parts.add((placeholder: null, text: template.substring(cursor, match.start)));
      }
      parts.add((placeholder: name, text: template.substring(match.start, match.end)));
      found.add(name);
      cursor = match.end;
    }
    if (cursor < template.length) {
      parts.add((placeholder: null, text: template.substring(cursor)));
    }
    return found.length == names.length ? parts : null;
  }

  /// [split] of [template], or of [fallback] when [template] lacks a name of
  /// [names]. [fallback] must contain every name.
  static List<ComparisonBarReadoutPart> resolve(String template, String fallback, Set<String> names) {
    final List<ComparisonBarReadoutPart>? parts = split(template, names) ?? split(fallback, names);
    assert(parts != null, "fallback must contain every placeholder");
    return parts ?? const <ComparisonBarReadoutPart>[];
  }
}
