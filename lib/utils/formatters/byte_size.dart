// byte_size.dart
//
// ByteSize — a byte count split into a unit translation key (B / KB / MB /
// GB, 1024 steps) and the number in that unit, formatted for a locale with
// intl's NumberFormat (at most one decimal). Pure Dart, no BuildContext: the
// caller passes the locale tag and translates the key (keys under
// common.byte_units in assets/translations/). Used by FileUploadPanel.

import "package:intl/intl.dart" show Intl, NumberFormat;

/// A byte count ready for display: a unit translation key and the number in
/// that unit, formatted for a locale.
///
/// Units step by 1024 (binary multiples) and keep the familiar KB / MB / GB
/// labels, as file managers do, rather than KiB / MiB / GiB:
/// - below 1024 B → `common.byte_units.b` (`512` → "512 B");
/// - below 1024² B → `common.byte_units.kb` (`1536` → "1.5 KB");
/// - below 1024³ B → `common.byte_units.mb`;
/// - otherwise → `common.byte_units.gb`, the largest unit (2 TiB → "2,048 GB").
///
/// The unit is chosen from the exact byte count, before rounding.
///
/// Each key holds a `{value}` placeholder. Translate with
/// `size.key.tr(namedArgs: size.namedArgs)`.
final class ByteSize {
  /// `common.byte_units.b`, `kb`, `mb` or `gb`.
  final String key;

  /// Number in the unit of [key] with at most one decimal and the locale's
  /// separators (`"1.5"`, `"1,5"`, `"1,023"`…). A whole number has no
  /// trailing decimal (`"1"`, not `"1.0"`).
  final String value;

  const ByteSize._(this.key, this.value);

  static const int _step = 1024;
  static const String _pattern = "#,##0.#";
  static const List<String> _keys = <String>[
    "common.byte_units.b",
    "common.byte_units.kb",
    "common.byte_units.mb",
    "common.byte_units.gb",
  ];

  /// Splits [bytes] (non-negative) for [locale], a BCP 47 tag such as
  /// `"fr-FR"` (`Locale.toLanguageTag()`), a language code (`"fr"`) or an
  /// intl name (`"fr_FR"`). An unknown or null locale falls back to intl's
  /// current locale (`Intl.defaultLocale`, else the system one) without
  /// throwing.
  factory ByteSize.of(int bytes, {String? locale}) {
    assert(bytes >= 0, "bytes must not be negative, got $bytes");
    final NumberFormat format = NumberFormat(_pattern, _verified(locale));
    double amount = bytes.toDouble();
    int unit = 0;
    while (amount >= _step && unit < _keys.length - 1) {
      amount /= _step;
      unit++;
    }
    return ByteSize._(_keys[unit], format.format(amount));
  }

  /// Named args for `key.tr(namedArgs: …)`: `{"value": value}`.
  Map<String, String> get namedArgs => <String, String>{"value": value};

  static String? _verified(String? locale) {
    return Intl.verifiedLocale(locale, NumberFormat.localeExists, onFailure: (String _) => null);
  }
}
