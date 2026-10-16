// byte_size_test.dart
//
// Unit tests for ByteSize (utils/formatters/byte_size.dart): unit thresholds
// at 1024 steps up to GB, at most one decimal, locale-aware separators, the
// fallback for an unknown or null locale, the named args, and the contract
// with assets/translations/ (every unit key exists with a {value}
// placeholder in each locale file).

import "dart:convert";
import "dart:io";

import "package:flutter/widgets.dart" show Locale;
import "package:flutter_skeleton/data/locales.dart";
import "package:flutter_skeleton/utils/formatters/byte_size.dart";
import "package:flutter_test/flutter_test.dart";

const String _b = "common.byte_units.b";
const String _kb = "common.byte_units.kb";
const String _mb = "common.byte_units.mb";
const String _gb = "common.byte_units.gb";

const int _kib = 1024;
const int _mib = 1024 * 1024;
const int _gib = 1024 * 1024 * 1024;

/// Expects [bytes] in en-US to give [key] and [value].
void _expectSize(int bytes, String key, String value) {
  final ByteSize size = ByteSize.of(bytes, locale: "en-US");
  expect(size.key, key, reason: "key of $bytes B");
  expect(size.value, value, reason: "value of $bytes B");
}

/// Reads the dotted [key] ("common.byte_units.kb") from a locale file.
String? _translation(String languageCode, String key) {
  final File file = File("${AppLocales.path}/$languageCode.json");
  Object? node = jsonDecode(file.readAsStringSync());
  for (final String segment in key.split(".")) {
    node = node is Map<String, dynamic> ? node[segment] : null;
  }
  return node is String ? node : null;
}

void main() {
  _thresholdTests();
  _roundingTests();
  _localeTests();
  _translationTests();
}

void _thresholdTests() {
  group("unit thresholds", () {
    test("below 1024 bytes uses the bytes key", () {
      _expectSize(0, _b, "0");
      _expectSize(512, _b, "512");
      _expectSize(1023, _b, "1,023");
    });

    test("1024 bytes switches to KB without a trailing decimal", () {
      _expectSize(_kib, _kb, "1");
      _expectSize(1536, _kb, "1.5");
    });

    test("1 MiB switches to MB", () {
      _expectSize(_mib, _mb, "1");
      _expectSize(3 * _mib, _mb, "3");
    });

    test("1 GiB switches to GB", () {
      _expectSize(_gib, _gb, "1");
      _expectSize(2048 * _mib, _gb, "2");
      _expectSize(_gib + 512 * _mib, _gb, "1.5");
    });

    test("GB is the largest unit", () {
      _expectSize(2048 * _gib, _gb, "2,048");
    });

    test("a negative count fails the assert", () {
      expect(() => ByteSize.of(-1), throwsA(isA<AssertionError>()));
    });
  });
}

void _roundingTests() {
  group("rounding", () {
    test("rounds to one decimal", () {
      // 1100 / 1024 = 1.074…
      _expectSize(1100, _kb, "1.1");
    });

    test("picks the unit from the exact count, before rounding", () {
      // 1 MiB - 1 B = 1023.999… KB.
      _expectSize(_mib - 1, _kb, "1,024");
    });
  });
}

void _localeTests() {
  group("locale", () {
    test("uses the French decimal and grouping separators for a BCP 47 tag", () {
      expect(ByteSize.of(1536, locale: "fr-FR").value, "1,5");
      // French groups thousands with a narrow no-break space (U+202F).
      expect(ByteSize.of(1023, locale: "fr-FR").value, "1 023");
    });

    test("accepts a language-only or intl-style locale name", () {
      expect(ByteSize.of(1536, locale: "fr").value, "1,5");
      expect(ByteSize.of(1536, locale: "de_DE").value, "1,5");
      expect(ByteSize.of(1023, locale: "de_DE").value, "1.023");
    });

    test("falls back without throwing for an unknown locale", () {
      expect(() => ByteSize.of(1536, locale: "zz-ZZ"), returnsNormally);
      expect(ByteSize.of(1536, locale: "zz-ZZ").key, _kb);
    });

    test("a null locale uses intl's current locale", () {
      final ByteSize size = ByteSize.of(1536);
      expect(size.key, _kb);
      expect(size.value, isNotEmpty);
    });
  });
}

void _translationTests() {
  group("translations", () {
    test("namedArgs carries the value under {value}", () {
      expect(ByteSize.of(1536, locale: "en-US").namedArgs, <String, String>{"value": "1.5"});
    });

    test("every unit key exists with a {value} placeholder in each locale", () {
      final List<String> keys = <int>[0, _kib, _mib, _gib]
          .map((int bytes) => ByteSize.of(bytes, locale: "en-US").key)
          .toList();
      expect(keys, <String>[_b, _kb, _mb, _gb]);
      for (final Locale locale in AppLocales.supported) {
        for (final String key in keys) {
          expect(
            _translation(locale.languageCode, key),
            contains("{value}"),
            reason: "$key in ${locale.languageCode}.json",
          );
        }
      }
    });
  });
}
