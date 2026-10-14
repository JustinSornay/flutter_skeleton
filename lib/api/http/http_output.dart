// http_output.dart
//
// Thin wrapper around a raw JSON map returned by the API. DTOs receive an
// HttpOutput instance in their .fromOutput() constructor and use the helper
// methods below to extract typed values without scattering null-checks and
// casts across the codebase.
//
// Relationships:
//   - Produced by Http.output / Http.listOutput / Http.input
//   - Consumed by every DTO output class via OutputInterface.fromOutput

import "package:flutter_skeleton/utils/env.dart";
import "package:logger/logger.dart";

/// Typed accessor for a single JSON object returned by the API.
///
/// All access is strict: missing keys or wrong types throw [AssertionError]
/// and log an error when LOGGER_ERROR is enabled, making API contract
/// violations visible at development time rather than silently producing null.
final class HttpOutput {
  final Map<String, dynamic> json;

  const HttpOutput.fromJson(this.json);

  /// Returns the raw value for [key], throwing if the key does not exist.
  dynamic operator [](String key) {
    if (json.containsKey(key)) {
      return json[key];
    }

    _error("Property $key doesn't exist");
    throw AssertionError("Property $key doesn't exist");
  }

  /// Returns the value for [key] cast to [T], throwing if the type does not
  /// match. Use this for primitive fields (String, int, bool, num, List).
  /// Nullable types (`cast<String?>`) accept an explicit JSON `null`, but the
  /// key itself must still be present.
  T cast<T>(String key) {
    final dynamic value = this[key];
    if (value is T) {
      return value;
    }

    _error("Property $key isn't of type $T");
    throw AssertionError("Property $key isn't of type $T");
  }

  void _error(String message) {
    if (Env.flag("LOGGER_ERROR")) {
      Logger().e(message,
        stackTrace: StackTrace.current,
      );
    }
  }

  /// Returns a nested object at [key] as a new [HttpOutput].
  /// Use when the API embeds a child object (e.g. `output.output("author")`).
  HttpOutput output(String key) {
    return HttpOutput.fromJson(cast<Map<String, dynamic>>(key));
  }

  /// Returns a list of nested objects at [key], each wrapped in [HttpOutput].
  /// Use when the API embeds an array of objects (e.g. `output.outputList("items")`).
  List<HttpOutput> outputList(String key) {
    return cast<List<dynamic>>(key)
      .map((dynamic e) => HttpOutput.fromJson(e as Map<String, dynamic>))
      .toList();
  }
}
