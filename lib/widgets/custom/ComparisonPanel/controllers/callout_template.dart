// callout_template.dart
//
// _CalloutTemplate — turns the localized callout template
// "{label} : {from} → {to}" into styled runs (the from / to values are
// emphasised), falling back to a built-in pattern when the template lacks a
// placeholder (untranslated key). Pure string logic used by
// widgets/change_callout.dart.

part of "../index.dart";

/// One run of the callout: [text] to render, [emphasis] for the from / to
/// values.
typedef _CalloutRun = ({String text, bool emphasis});

abstract final class _CalloutTemplate {
  static const String _label = "label";
  static const String _from = "from";
  static const String _to = "to";

  /// Used when the translated template lacks a placeholder.
  static const String _fallback = "{$_label}: {$_from} → {$_to}";

  static final RegExp _placeholder = RegExp(r"\{(label|from|to)\}");

  /// Runs of [template] filled with [change], or of the built-in fallback
  /// when [template] lacks one of `{label}`, `{from}`, `{to}`.
  static List<_CalloutRun> runs(String template, ComparisonChange change) {
    return _split(template, change) ?? _split(_fallback, change) ?? const <_CalloutRun>[];
  }

  static List<_CalloutRun>? _split(String template, ComparisonChange change) {
    final List<_CalloutRun> runs = <_CalloutRun>[];
    final Set<String> found = <String>{};
    int cursor = 0;
    for (final RegExpMatch match in _placeholder.allMatches(template)) {
      if (match.start > cursor) {
        runs.add((text: template.substring(cursor, match.start), emphasis: false));
      }
      final String name = match.group(1) ?? "";
      runs.add(_valueRun(name, change));
      found.add(name);
      cursor = match.end;
    }
    if (cursor < template.length) {
      runs.add((text: template.substring(cursor), emphasis: false));
    }
    return found.length == 3 ? runs : null;
  }

  static _CalloutRun _valueRun(String name, ComparisonChange change) {
    return switch (name) {
      _from => (text: change.from, emphasis: true),
      _to => (text: change.to, emphasis: true),
      _ => (text: change.label, emphasis: false),
    };
  }
}
