// json_object.dart
//
// Decodes one JSON text that must be an object. Shared by the line framers of
// the stream transformers (SseTransformer, NdjsonTransformer) so both report a
// bad payload the same way: a FormatException.

import "dart:async";
import "dart:convert";

/// Decodes [source] and returns it when it is a JSON object.
///
/// Throws [FormatException] when [source] is not valid JSON, or is valid JSON
/// of another kind (array, string, number, bool, null).
Map<String, dynamic> decodeJsonObject(String source) {
  final Object? decoded = jsonDecode(source);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  throw FormatException("Expected a JSON object", source);
}

/// Adds the object decoded from [source] to [out], or adds the
/// [FormatException] thrown by [decodeJsonObject] as an error. Never throws.
void addJsonObject(EventSink<Map<String, dynamic>> out, String source) {
  try {
    out.add(decodeJsonObject(source));
  } on FormatException catch (error, stackTrace) {
    out.addError(error, stackTrace);
  }
}
