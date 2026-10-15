// digit_mask.dart
//
// DigitMask — pure '#'-pattern formatter shared by MaskedDigitField and by
// hosts that display a stored value with the same grouping. No Flutter
// dependency; unit-tested in test/unit/widgets/masked_digit_field_mask_test.dart.

part of "../index.dart";

/// Formats digits into a pattern where `#` is a digit slot and any other
/// character is a literal separator.
///
/// ```dart
/// const DigitMask mask = DigitMask("##/##/####");
/// mask.format("01022024"); // "01/02/2024"
/// mask.format("010"); // "01/0"
/// mask.sample(); // "12/34/5678"
/// ```
@immutable
final class DigitMask {
  /// `#` = one digit slot; any other character is a separator written only
  /// when a digit follows it. A pattern without `#` accepts no digit.
  final String pattern;

  const DigitMask(this.pattern);

  /// Slot character of [pattern].
  static const String _slot = "#";

  /// Digit sequence repeated by [sample].
  static const String _sampleDigits = "1234567890";

  static final RegExp _nonDigit = RegExp(r"\D");

  /// Number of `#` slots, i.e. the maximum digit count.
  int get maxDigits => _slot.allMatches(pattern).length;

  /// Formats the digits of [text] into [pattern].
  ///
  /// Non-digit characters of [text] are ignored and digits beyond [maxDigits]
  /// are dropped. Separators are written only before a digit, so the result
  /// never ends with a separator (a leading separator such as `(` is written
  /// once the first digit arrives). Empty when [text] has no digit.
  String format(String text) {
    final String all = digitsOf(text);
    // Clamped first, so separators after the last slot are never written.
    final String digits = all.length > maxDigits ? all.substring(0, maxDigits) : all;
    final StringBuffer buffer = StringBuffer();
    int next = 0;
    for (final String char in pattern.split("")) {
      if (next >= digits.length) break;
      buffer.write(char == _slot ? digits[next++] : char);
    }
    return buffer.toString();
  }

  /// [pattern] with every `#` replaced by the sequence `1234567890`
  /// (repeating), separators kept: `"# ## ## ## ##"` → `"1 23 45 67 89"`.
  String sample() {
    final StringBuffer buffer = StringBuffer();
    int next = 0;
    for (final String char in pattern.split("")) {
      buffer.write(char == _slot ? _sampleDigits[next++ % _sampleDigits.length] : char);
    }
    return buffer.toString();
  }

  /// [text] without any non-digit character (separators, `+`, letters…).
  static String digitsOf(String text) => text.replaceAll(_nonDigit, "");
}
