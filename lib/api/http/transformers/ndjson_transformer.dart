// ndjson_transformer.dart
//
// Generic newline-delimited JSON framing for Http.listen: raw response bytes →
// one JSON object per line. Entity-agnostic — the calling service maps each
// object to its DTO through HttpOutput.
//
// Relationships:
//   - Passed as `transformer:` to Http.listen (api/http/http.dart)
//   - Bytes → lines through frameUtf8Lines (utf8_lines.dart); lines → objects
//     through addJsonObject (json_object.dart), like SseTransformer
//     (sse_transformer.dart)

import "dart:async";

import "package:flutter_skeleton/api/http/transformers/json_object.dart";
import "package:flutter_skeleton/api/http/transformers/utf8_lines.dart";

/// Decodes an NDJSON body (`application/x-ndjson`) into one JSON object per
/// line.
///
/// Framing:
/// - lines end with `\n` or `\r\n` (a lone `\r` also ends a line);
/// - blank and whitespace-only lines are skipped;
/// - a last line without a trailing newline is emitted when the body ends.
///
/// Bytes go through a chunked UTF-8 decoder, so a multibyte character split
/// across two network chunks stays intact.
///
/// Errors are never swallowed:
/// - a line that is not valid JSON, or not a JSON object, is emitted as a
///   [FormatException] error, and the following lines still flow to a
///   listener that keeps going;
/// - invalid UTF-8 (including a body that ends inside a character) is emitted
///   as a [FormatException] error and ends the stream: nothing after it is
///   emitted, not even the line in progress, because the decoder discards the
///   whole chunk that holds the bad byte;
/// - `Http.listen` cancels on the first error, so its future throws the
///   [FormatException].
///
/// ```dart
/// static Future<void> export(void Function(EntityListOutput item) onItem) async {
///   try {
///     await Http.listen<Map<String, dynamic>>(
///       method: HttpMethodEnum.get,
///       api: HttpApiEnum.api,
///       route: "entities/export",
///       transformer: const NdjsonTransformer(),
///       listener: (Map<String, dynamic> json) =>
///         onItem(EntityListOutput.fromOutput(HttpOutput.fromJson(json))),
///     );
///   } catch (e) {
///     Logger().e("EntityService.export: $e");
///     rethrow;
///   }
/// }
/// ```
final class NdjsonTransformer extends StreamTransformerBase<List<int>, Map<String, dynamic>> {
  const NdjsonTransformer();

  @override
  Stream<Map<String, dynamic>> bind(Stream<List<int>> stream) {
    return frameUtf8Lines(stream, _NdjsonLineSink.new);
  }
}

/// Emits each non-blank line as a JSON object (or a FormatException error).
final class _NdjsonLineSink implements Sink<String> {
  final EventSink<Map<String, dynamic>> _out;

  _NdjsonLineSink(this._out);

  @override
  void add(String line) {
    if (line.trim().isNotEmpty) {
      addJsonObject(_out, line);
    }
  }

  @override
  void close() {
    _out.close();
  }
}
