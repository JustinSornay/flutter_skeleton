// string_parser_test.dart
//
// Unit tests for StringParser — case detection and conversions between
// snake_case, camelCase and PascalCase (used by the code generators).

import "package:flutter_skeleton/utils/parsers/string_parser.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("case detection", () {
    test("isSnake", () {
      expect(StringParser.isSnake("my_entity"), isTrue);
      expect(StringParser.isSnake("MyEntity"), isFalse);
    });

    test("isCamel", () {
      expect(StringParser.isCamel("myEntity"), isTrue);
      expect(StringParser.isCamel("my_entity"), isFalse);
    });

    test("isPascal", () {
      expect(StringParser.isPascal("MyEntity"), isTrue);
      expect(StringParser.isPascal("myEntity"), isFalse);
    });
  });

  group("single-word conversions", () {
    test("Todo → todo / todo", () {
      final StringParser parser = StringParser.fromPascal("Todo");
      expect(parser.toSnake(), "todo");
      expect(parser.toCamel(), "todo");
    });
  });

  group("multi-word conversions", () {
    test("PascalCase → snake_case and camelCase", () {
      final StringParser parser = StringParser.fromPascal("MyLongEntity");
      expect(parser.toSnake(), "my_long_entity");
      expect(parser.toCamel(), "myLongEntity");
      expect(parser.toPascal(), "MyLongEntity");
    });

    test("camelCase → snake_case and PascalCase", () {
      final StringParser parser = StringParser.fromCamel("myLongEntity");
      expect(parser.toSnake(), "my_long_entity");
      expect(parser.toPascal(), "MyLongEntity");
    });

    test("snake_case → camelCase and PascalCase", () {
      final StringParser parser = StringParser.fromSnake("my_long_entity");
      expect(parser.toCamel(), "myLongEntity");
      expect(parser.toPascal(), "MyLongEntity");
    });
  });
}
