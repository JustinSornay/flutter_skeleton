// translations_test.dart
//
// Guards the localization contract: every locale file under
// assets/translations/ exposes exactly the key set of the canonical fr.json,
// and every supported locale has a file.

import "dart:convert";
import "dart:io";

import "package:flutter/widgets.dart";
import "package:flutter_skeleton/data/locales.dart";
import "package:flutter_test/flutter_test.dart";

/// Flattens nested JSON into dotted keys ("todos.title").
Set<String> _keys(Map<String, dynamic> json, [String prefix = ""]) {
  final Set<String> keys = <String>{};
  json.forEach((String key, dynamic value) {
    final String path = prefix.isEmpty ? key : "$prefix.$key";
    if (value is Map<String, dynamic>) {
      keys.addAll(_keys(value, path));
    } else {
      keys.add(path);
    }
  });
  return keys;
}

Set<String> _load(String languageCode) {
  final File file = File("${AppLocales.path}/$languageCode.json");
  return _keys(jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
}

void main() {
  final Set<String> canonical = _load(AppLocales.fallback.languageCode);

  for (final Locale locale in AppLocales.supported) {
    test("${locale.languageCode}.json matches the fr.json key set", () {
      final Set<String> keys = _load(locale.languageCode);
      expect(canonical.difference(keys), isEmpty, reason: "keys missing from ${locale.languageCode}.json");
      expect(keys.difference(canonical), isEmpty, reason: "keys only in ${locale.languageCode}.json");
    });
  }

  test("every translation file belongs to a supported locale", () {
    final Set<String> files = Directory(AppLocales.path)
        .listSync()
        .whereType<File>()
        .map((File f) => f.uri.pathSegments.last.replaceAll(".json", ""))
        .toSet();
    expect(files, AppLocales.supported.map((Locale l) => l.languageCode).toSet());
  });
}
