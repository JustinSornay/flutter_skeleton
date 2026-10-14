// env_test.dart
//
// Unit tests for the Env helpers over flutter_dotenv.

import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_skeleton/utils/env.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: """
FLAG_TRUE=true
FLAG_ONE=1
FLAG_FALSE=false
EMPTY=
PAGE=50
NOT_A_NUMBER=abc
""");
  });

  test("get returns null for missing and empty values", () {
    expect(Env.get("PAGE"), "50");
    expect(Env.get("EMPTY"), isNull);
    expect(Env.get("MISSING"), isNull);
  });

  test("flag is true only for true / 1", () {
    expect(Env.flag("FLAG_TRUE"), isTrue);
    expect(Env.flag("FLAG_ONE"), isTrue);
    expect(Env.flag("FLAG_FALSE"), isFalse);
    expect(Env.flag("EMPTY"), isFalse);
    expect(Env.flag("MISSING"), isFalse);
  });

  test("intOr parses or falls back", () {
    expect(Env.intOr("PAGE", 20), 50);
    expect(Env.intOr("NOT_A_NUMBER", 20), 20);
    expect(Env.intOr("MISSING", 20), 20);
  });
}
