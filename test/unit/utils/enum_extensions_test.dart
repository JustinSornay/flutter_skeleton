// enum_extensions_test.dart
//
// Unit tests for EnumIterableExtensions.by.

import "package:flutter_skeleton/utils/extensions/enum_extensions.dart";
import "package:flutter_test/flutter_test.dart";

enum _Fruit { apple, pear, unknown }

void main() {
  test("returns the first matching value", () {
    expect(_Fruit.values.by((_Fruit f) => f.name == "pear"), _Fruit.pear);
  });

  test("returns the first of several matching values", () {
    expect(_Fruit.values.by((_Fruit f) => f != _Fruit.apple), _Fruit.pear);
  });

  test("falls back to orElse when nothing matches", () {
    expect(_Fruit.values.by((_Fruit f) => f.name == "kiwi", orElse: () => _Fruit.unknown), _Fruit.unknown);
  });

  test("throws a StateError without orElse when nothing matches", () {
    expect(() => _Fruit.values.by((_Fruit f) => f.name == "kiwi"), throwsStateError);
  });
}
