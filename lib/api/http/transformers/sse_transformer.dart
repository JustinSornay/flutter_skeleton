// sse_transformer.dart
//
// Generic Server-Sent Events framing for Http.listen: raw response bytes →
// one JSON object per event. Entity-agnostic — the calling service maps each
// object to its DTO through HttpOutput.
//
// Relationships:
//   - Passed as `transformer:` to Http.listen (api/http/http.dart)
//   - Bytes → lines through frameUtf8Lines (utf8_lines.dart); payloads →
//     objects through addJsonObject (json_object.dart), like
//     NdjsonTransformer (ndjson_transformer.dart)

import "dart:async";

import "package:flutter_skeleton/api/http/transformers/json_object.dart";
import "package:flutter_skeleton/api/http/transformers/utf8_lines.dart";

/// Decodes a `text/event-stream` body into one JSON object per event.
///
/// Framing (WHATWG Server-Sent Events):
/// - lines end with `\n`, `\r\n` or `\r`; a blank line ends an event;
/// - the `data:` lines of one event are joined with `\n` and the result is
///   JSON-decoded; one space after the colon is stripped;
/// - lines starting with `:` are comments (keep-alives) and are ignored;
/// - every other field (`event:`, `id:`, `retry:`) is ignored — put a `type`
///   key in the JSON payload when the client must tell events apart;
/// - an event without data (or with empty data) is skipped;
/// - an event still pending when the body ends is emitted (the spec drops it;
///   a server that closes right after its last `data:` line loses nothing).
///
/// Bytes go through a chunked UTF-8 decoder, so a multibyte character split
/// across two network chunks stays intact.
///
/// Errors are never swallowed:
/// - a payload that is not valid JSON, or not a JSON object, is emitted as a
///   [FormatException] error, and the following events still flow to a
///   listener that keeps going;
/// - invalid UTF-8 (including a body that ends inside a character) is emitted
///   as a [FormatException] error and ends the stream: nothing after it is
///   emitted, not even the pending event, because the decoder discards the
///   whole chunk that holds the bad byte;
/// - `Http.listen` cancels on the first error, so its future throws the
///   [FormatException].
///
/// ```dart
/// static Future<void> watch(void Function(EntityEventOutput event) onEvent) async {
///   try {
///     await Http.listen<Map<String, dynamic>>(
///       method: HttpMethodEnum.get,
///       api: HttpApiEnum.api,
///       route: "entities/events",
///       transformer: const SseTransformer(),
///       listener: (Map<String, dynamic> json) =>
///         onEvent(EntityEventOutput.fromOutput(HttpOutput.fromJson(json))),
///     );
///   } catch (e) {
///     Logger().e("EntityService.watch: $e");
///     rethrow;
///   }
/// }
/// ```
final class SseTransformer extends StreamTransformerBase<List<int>, Map<String, dynamic>> {
  const SseTransformer();

  @override
  Stream<Map<String, dynamic>> bind(Stream<List<int>> stream) {
    return frameUtf8Lines(stream, _SseEventSink.new);
  }
}

/// Groups lines into events and forwards each event's JSON payload.
/// One instance per subscription, so the pending data never leaks between
/// streams.
final class _SseEventSink implements Sink<String> {
  final EventSink<Map<String, dynamic>> _out;
  final List<String> _data = <String>[];

  _SseEventSink(this._out);

  @override
  void add(String line) {
    if (line.isEmpty) {
      _dispatch();
    } else if (!line.startsWith(":")) {
      _readField(line);
    }
  }

  @override
  void close() {
    _dispatch();
    _out.close();
  }

  /// Keeps the value of a `data` field; every other field is ignored.
  /// A line without a colon is a field name with an empty value.
  void _readField(String line) {
    final int colon = line.indexOf(":");
    final String field = colon == -1 ? line : line.substring(0, colon);
    if (field != "data") {
      return;
    }
    final String value = colon == -1 ? "" : line.substring(colon + 1);
    _data.add(value.startsWith(" ") ? value.substring(1) : value);
  }

  /// Emits the pending event's payload, then starts a new event.
  void _dispatch() {
    final String payload = _data.join("\n");
    _data.clear();
    if (payload.trim().isNotEmpty) {
      addJsonObject(_out, payload);
    }
  }
}
