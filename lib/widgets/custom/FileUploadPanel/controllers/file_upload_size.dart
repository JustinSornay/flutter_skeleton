// file_upload_size.dart
//
// FileUploadSize — pure size formatting of FileUploadPanel: picks the unit
// key (B / KB / MB, 1024 steps) and formats the number for a locale with
// intl's NumberFormat (at most one decimal). The view translates the key
// with the value as a named arg. Unit-tested without widgets.

part of "../index.dart";

/// A byte count split into a unit translation key and a formatted value.
@visibleForTesting
@immutable
final class FileUploadSize {
  /// `custom.file_upload_panel.size_bytes`, `size_kb` or `size_mb`.
  final String key;

  /// Number in the unit of [key], formatted for the locale (`"1.5"`,
  /// `"1,5"`, `"1,024"`…).
  final String value;

  const FileUploadSize._(this.key, this.value);

  static const int _kilo = 1024;
  static const int _mega = 1024 * 1024;
  static const String _pattern = "#,##0.#";

  /// Splits [bytes] for [locale] (a BCP 47 tag such as `"fr-FR"`, or an
  /// intl name such as `"fr_FR"`). An unknown or null locale falls back to
  /// intl's current locale.
  factory FileUploadSize.of(int bytes, {String? locale}) {
    final NumberFormat format = NumberFormat(_pattern, _verified(locale));
    if (bytes < _kilo) {
      return FileUploadSize._("custom.file_upload_panel.size_bytes", format.format(bytes));
    }
    if (bytes < _mega) {
      return FileUploadSize._("custom.file_upload_panel.size_kb", format.format(bytes / _kilo));
    }
    return FileUploadSize._("custom.file_upload_panel.size_mb", format.format(bytes / _mega));
  }

  static String? _verified(String? locale) {
    return Intl.verifiedLocale(locale, NumberFormat.localeExists, onFailure: (String _) => null);
  }
}
