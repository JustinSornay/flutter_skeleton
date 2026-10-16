// utf8_lines.dart
//
// Shared front end of the stream transformers: response bytes → UTF-8 text
// (chunked decoder, so a character split across network chunks survives) →
// lines → a per-subscription line framer that emits JSON objects. Invalid
// UTF-8 ends the stream.
//
// Relationships:
//   - Used by SseTransformer (sse_transformer.dart) and NdjsonTransformer
//     (ndjson_transformer.dart), whose framers emit through addJsonObject
//     (json_object.dart)

import "dart:async";
import "dart:convert";

/// Builds the line framer of one subscription.
///
/// The framer gets every line, without its terminator, through [Sink.add],
/// then [Sink.close] when a well-formed body ends. It writes JSON objects (or
/// [FormatException] errors) to `out`, closes `out` when it is closed, and
/// never throws.
typedef LineFramerBuilder = Sink<String> Function(EventSink<Map<String, dynamic>> out);

/// Decodes [bytes] as UTF-8 with a chunked decoder, splits the text into lines
/// (ended by `\n`, `\r\n` or `\r`) and feeds them to a framer built by
/// [buildFramer] for each subscription.
///
/// Errors of [bytes] are forwarded. Invalid UTF-8, including a body that ends
/// inside a character, adds one [FormatException] and then ends the stream:
/// the decoder discards the whole chunk that holds the bad byte, so nothing
/// after it can be framed reliably. The framer is not closed, so the line or
/// event it still holds is dropped, and the subscription to [bytes] is
/// cancelled.
Stream<Map<String, dynamic>> frameUtf8Lines(Stream<List<int>> bytes, LineFramerBuilder buildFramer) {
  return Stream<Map<String, dynamic>>.eventTransformed(
    bytes,
    (EventSink<Map<String, dynamic>> out) => _Utf8LineSink(out, buildFramer(out)),
  );
}

/// Pushes byte chunks through the chunked UTF-8 decoder and the line splitter
/// into the framer; on a decoding error, reports it and ends the output.
final class _Utf8LineSink implements EventSink<List<int>> {
  final EventSink<Map<String, dynamic>> _out;
  final ByteConversionSink _decoder;

  _Utf8LineSink(this._out, Sink<String> framer)
    : _decoder = utf8.decoder.startChunkedConversion(const LineSplitter().startChunkedConversion(framer));

  @override
  void add(List<int> chunk) {
    try {
      _decoder.add(chunk);
    } on FormatException catch (error, stackTrace) {
      _end(error, stackTrace);
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _out.addError(error, stackTrace);
  }

  @override
  void close() {
    try {
      // Flushes the last line into the framer, which then closes _out.
      _decoder.close();
    } on FormatException catch (error, stackTrace) {
      _end(error, stackTrace);
    }
  }

  /// Reports a decoding error and ends the output without closing the framer.
  /// Closing the output cancels the subscription to the bytes, so no event
  /// reaches this sink afterwards.
  void _end(FormatException error, StackTrace stackTrace) {
    _out
      ..addError(error, stackTrace)
      ..close();
  }
}
