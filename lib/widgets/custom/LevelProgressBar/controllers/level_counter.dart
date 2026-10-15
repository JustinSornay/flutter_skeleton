// level_counter.dart
//
// LevelProgressCounter — pure split of LevelProgressBar's counter template:
// fills the {count} / {total} / {label} placeholders and cuts the text around
// the first {count} so the view can emphasise the number. It takes the
// already translated template (the view calls .tr()), so it is unit-tested
// without easy_localization. No widgets.

part of "../index.dart";

/// The counter of a [LevelProgressBar], split for display: [before] and
/// [after] are plain runs, [count] is the emphasised number.
@visibleForTesting
@immutable
final class LevelProgressCounter {
  /// Plain text before the number (leading whitespace trimmed).
  final String before;

  /// The number, or empty when the template has no `{count}`.
  final String count;

  /// Plain text after the number (trailing whitespace trimmed).
  final String after;

  const LevelProgressCounter._(this.before, this.count, this.after);

  static const String _countPlaceholder = "{count}";

  /// Fills [template] and splits it around its first `{count}`.
  ///
  /// `{count}`, `{total}` and `{label}` are substituted on both sides (a
  /// null [label] counts as empty), [label] last so placeholder-like text in
  /// it is kept verbatim. The outer whitespace an empty [label] leaves is
  /// trimmed. A template without `{count}` (e.g. a missing translation)
  /// gives a single plain [before] run.
  factory LevelProgressCounter.of(String template, {required int count, required int total, String? label}) {
    String fill(String text) {
      return text
          .replaceAll(_countPlaceholder, "$count")
          .replaceAll("{total}", "$total")
          .replaceAll("{label}", label ?? "");
    }

    final int at = template.indexOf(_countPlaceholder);
    if (at < 0) return LevelProgressCounter._(fill(template).trim(), "", "");
    return LevelProgressCounter._(
      fill(template.substring(0, at)).trimLeft(),
      "$count",
      fill(template.substring(at + _countPlaceholder.length)).trimRight(),
    );
  }

  /// The whole counter as plain text (semantics value).
  String get text => "$before$count$after";
}
