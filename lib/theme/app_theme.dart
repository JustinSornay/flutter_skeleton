// app_theme.dart
//
// Material 3 light and dark themes derived from a single brand seed colour.
// Shared by main.dart and the widget test helpers so tests render with the
// exact production theme.
//
// Widgets never hardcode colours: they read ColorScheme tokens
// (cs.primary, cs.surface, cs.outlineVariant, cs.error…) and the StatusTones
// extension (status_tones.dart) so both brightnesses stay consistent.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";

/// Builds the application [ThemeData] for each brightness.
abstract final class AppTheme {
  /// Brand seed colour — the whole ColorScheme is derived from it.
  static const Color seed = Color(0xFF3B7054);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant, space: 1),
      extensions: <ThemeExtension<dynamic>>[StatusTones.fromScheme(colorScheme)],
    );
  }
}
