// string_parser.dart
//
// Converts strings between snake_case, camelCase, and PascalCase.
// Used primarily when mapping API field names (snake_case) to Dart
// identifiers (camelCase/PascalCase) and vice-versa.
//
// Construct via a named constructor that declares the input case, then
// call toSnake(), toCamel(), or toPascal() to get the desired output.
//
// Note: inputs with fewer than 2 characters are not supported.

/// Converts a string from one identifier case convention to another.
///
/// The input case must be declared at construction time via
/// [StringParser.fromSnake], [StringParser.fromCamel], or
/// [StringParser.fromPascal]. Each named constructor asserts that the
/// supplied string actually matches the declared convention.
///
/// **/!\ Can't format string contains less than 2 chars**
final class StringParser {
  final String _input;
  final StringParserInputCase _case;

  /// Creates a parser for a snake_case input such as `"crop_score"`.
  StringParser.fromSnake(this._input):
    assert(isSnake(_input)),
    _case = StringParserInputCase.snake;

  /// Creates a parser for a camelCase input such as `"cropScore"`.
  StringParser.fromCamel(this._input):
    assert(isCamel(_input)),
    _case = StringParserInputCase.camel;

  /// Creates a parser for a PascalCase input such as `"CropScore"`.
  StringParser.fromPascal(this._input):
    assert(isPascal(_input)),
    _case = StringParserInputCase.pascal;

  /// Returns true when [input] matches the snake_case pattern
  /// (`lowercase_words_separated_by_underscores`).
  static bool isSnake(String input) {
    return RegExp(r"^[a-z]+(?:_[a-z0-9]+)*$").hasMatch(input);
  }

  /// Returns true when [input] matches the camelCase pattern
  /// (starts lowercase, each subsequent word starts with an uppercase letter).
  static bool isCamel(String input) {
    return RegExp(r"^[a-z]+(?:[A-Z][a-z0-9]*)*$").hasMatch(input);
  }

  /// Returns true when [input] matches the PascalCase pattern
  /// (every word starts with an uppercase letter, no underscores).
  static bool isPascal(String input) {
    return RegExp(r"^[A-Z][a-z0-9]*(?:[A-Z][a-z0-9]*)*$").hasMatch(input);
  }

  String _camelToSnake(String input) {
    return input.replaceAllMapped(RegExp("[A-Z]"), (Match match) => "_${match[0]!.toLowerCase()}");
  }

  String _camelToPascal(String input) {
    return "${input[0].toUpperCase()}${input.substring(1)}";
  }

  String _pascalToSnake(String input) {
    return "${input[0].toLowerCase()}${_camelToSnake(input.substring(1))}";
  }

  String _pascalToCamel(String input) {
    return "${input[0].toLowerCase()}${input.substring(1)}";
  }

  String _snakeToCamel(String input) {
    return input.replaceAllMapped(RegExp("_[a-z0-9]"), (Match match) => match[0]![1].toUpperCase());
  }

  String _snakeToPascal(String input) {
    return "${input[0].toUpperCase()}${_snakeToCamel(input.substring(1))}";
  }

  /// Returns the input converted to snake_case.
  String toSnake() {
    return switch(_case) {
      StringParserInputCase.snake => _input,
      StringParserInputCase.camel => _camelToSnake(_input),
      StringParserInputCase.pascal => _pascalToSnake(_input)
    };
  }

  /// Returns the input converted to camelCase.
  String toCamel() {
    return switch(_case) {
      StringParserInputCase.snake => _snakeToCamel(_input),
      StringParserInputCase.camel => _input,
      StringParserInputCase.pascal => _pascalToCamel(_input)
    };
  }

  /// Returns the input converted to PascalCase.
  String toPascal() {
    return switch(_case) {
      StringParserInputCase.snake => _snakeToPascal(_input),
      StringParserInputCase.camel => _camelToPascal(_input),
      StringParserInputCase.pascal => _input
    };
  }

  @override
  String toString() {
    return _input;
  }
}

/// Declares the case convention of the string supplied to [StringParser].
enum StringParserInputCase {
  snake,
  camel,
  pascal
}
