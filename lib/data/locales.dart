// locales.dart
//
// Localization configuration shared by main.dart and the test helpers.
// fr.json is the canonical translation file: every other locale must expose
// exactly the same key set (enforced by test/unit/translations_test.dart).

import "package:flutter/widgets.dart";

/// Supported locales and translation asset location.
abstract final class AppLocales {
  static const List<Locale> supported = <Locale>[Locale("fr"), Locale("en")];

  static const Locale fallback = Locale("fr");

  static const String path = "assets/translations";
}
