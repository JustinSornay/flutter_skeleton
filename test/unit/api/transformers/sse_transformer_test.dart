// sse_transformer_test.dart
//
// Unit tests for SseTransformer: event framing across chunk boundaries and
// line endings, ignored lines and fields, chunked UTF-8 decoding, FormatException
// stream errors (JSON: keep going; UTF-8: end the stream), and the end-to-end
// path through Http.listen (MockClient).

import "dart:convert";

import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_skeleton/api/http/enums.dart";
import "package:flutter_skeleton/api/http/http.dart";
import "package:flutter_skeleton/api/http/transformers/sse_transformer.dart";
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";

/// Feeds each byte chunk to a fresh [SseTransformer].
Stream<Map<String, dynamic>> _decodeBytes(List<List<int>> chunks) {
  return Stream<List<int>>.fromIterable(chunks).transform(const SseTransformer());
}

/// Feeds each text piece, UTF-8 encoded, as one chunk.
Stream<Map<String, dynamic>> _decode(List<String> pieces) {
  return _decodeBytes(pieces.map(utf8.encode).toList());
}

/// Splits the UTF-8 encoding of [text] into one chunk per byte.
List<List<int>> _byteByByte(String text) {
  return utf8.encode(text).map((int byte) => <int>[byte]).toList();
}

void main() {
  group("framing", _framing);
  group("ignored input", _ignoredInput);
  group("UTF-8", _utf8);
  group("errors", _errors);
  group("with Http.listen", _withHttpListen);
}

void _framing() {
  test("emits one JSON object per event", () async {
    expect(
      await _decode(<String>["data: {\"a\":1}\n\ndata: {\"b\":2}\n\n"]).toList(),
      <Map<String, dynamic>>[<String, dynamic>{"a": 1}, <String, dynamic>{"b": 2}],
    );
  });

  test("reassembles events split anywhere across chunks", () async {
    expect(
      await _decodeBytes(_byteByByte("data: {\"a\":1}\n\ndata: {\"b\":2}\n\n")).toList(),
      <Map<String, dynamic>>[<String, dynamic>{"a": 1}, <String, dynamic>{"b": 2}],
    );
  });

  test("accepts \\r\\n line endings, even with \\r and \\n in separate chunks", () async {
    expect(
      await _decode(<String>["data: {\"a\":1}\r", "\n\r", "\ndata: {\"b\":2}\r\n\r\n"]).toList(),
      <Map<String, dynamic>>[<String, dynamic>{"a": 1}, <String, dynamic>{"b": 2}],
    );
  });

  test("joins the data lines of one event with a newline", () async {
    expect(
      await _decode(<String>["data: {\"a\":\ndata: 1,\ndata: \"b\": [2]}\n\n"]).toList(),
      <Map<String, dynamic>>[<String, dynamic>{"a": 1, "b": <dynamic>[2]}],
    );
  });

  test("keeps the newline between data lines inside a JSON token", () async {
    // "12" + "\n" + "34" is invalid JSON; joining without the newline would
    // silently give {"a": 1234}.
    await expectLater(
      _decode(<String>["data: {\"a\":12\ndata: 34}\n\n"]),
      emitsInOrder(<Object>[emitsError(isFormatException), emitsDone]),
    );
  });

  test("accepts data without the space after the colon", () async {
    expect(
      await _decode(<String>["data:{\"a\":1}\n\n"]).toList(),
      <Map<String, dynamic>>[<String, dynamic>{"a": 1}],
    );
  });

  test("emits an event still pending when the stream closes", () async {
    expect(
      await _decode(<String>["data: {\"a\":1}\n\ndata: {\"b\":2}"]).toList(),
      <Map<String, dynamic>>[<String, dynamic>{"a": 1}, <String, dynamic>{"b": 2}],
    );
  });
}

void _ignoredInput() {
  test("ignores comment lines, alone or inside an event", () async {
    expect(
      await _decode(<String>[": keep-alive\n\n:\n\ndata: {\"a\":1}\n: note\n\n"]).toList(),
      <Map<String, dynamic>>[<String, dynamic>{"a": 1}],
    );
  });

  test("ignores event, id and retry fields next to the data", () async {
    expect(
      await _decode(<String>["event: update\nid: 7\nretry: 1000\ndata: {\"a\":1}\n\n"]).toList(),
      <Map<String, dynamic>>[<String, dynamic>{"a": 1}],
    );
  });

  test("skips events without data or with empty data", () async {
    expect(
      await _decode(<String>["event: ping\n\nid: 3\n\ndata:\n\ndata\n\ndata:   \n\n\n\n"]).toList(),
      isEmpty,
    );
  });

  test("ignores fields whose name only starts with data", () async {
    expect(
      await _decode(<String>["database: {\"x\":0}\ndata: {\"a\":1}\n\n"]).toList(),
      <Map<String, dynamic>>[<String, dynamic>{"a": 1}],
    );
  });
}

void _utf8() {
  test("keeps a 2-byte character split between two chunks intact", () async {
    final List<int> bytes = utf8.encode("data: {\"name\":\"café\"}\n\n");
    final int cut = bytes.indexOf(0xA9); // second byte of "é" (0xC3 0xA9)
    final List<List<int>> chunks = <List<int>>[bytes.sublist(0, cut), bytes.sublist(cut)];

    // Decoding each chunk on its own (utf8.decode per chunk) corrupts the text.
    final String perChunk = chunks.map((List<int> chunk) => utf8.decode(chunk, allowMalformed: true)).join();
    expect(perChunk, isNot(contains("café")));

    expect(
      await _decodeBytes(chunks).toList(),
      <Map<String, dynamic>>[<String, dynamic>{"name": "café"}],
    );
  });

  test("keeps 3- and 4-byte characters fed one byte at a time intact", () async {
    expect(
      await _decodeBytes(_byteByByte("data: {\"name\":\"€ \u{1D11E}\"}\n\n")).toList(),
      <Map<String, dynamic>>[<String, dynamic>{"name": "€ \u{1D11E}"}],
    );
  });
}

void _errors() {
  test("reports malformed JSON as a FormatException and keeps going", () async {
    await expectLater(
      _decode(<String>["data: {\"a\":1}\n\ndata: {oops\n\ndata: {\"b\":2}\n\n"]),
      emitsInOrder(<Object>[
        <String, dynamic>{"a": 1},
        emitsError(isFormatException),
        <String, dynamic>{"b": 2},
        emitsDone,
      ]),
    );
  });

  test("reports a payload that is not a JSON object as a FormatException", () async {
    await expectLater(
      _decode(<String>["data: [1, 2]\n\n"]),
      emitsInOrder(<Object>[emitsError(isFormatException), emitsDone]),
    );
  });

  test("ends the stream with a FormatException at an invalid UTF-8 byte", () async {
    await expectLater(
      _decodeBytes(<List<int>>[
        utf8.encode("data: {\"a\":1}\n\n"),
        <int>[...utf8.encode("data: {\"b\":\"x"), 0xFF, ...utf8.encode("\"}\n\n")],
        utf8.encode("data: {\"c\":3}\n\n"),
      ]),
      emitsInOrder(<Object>[<String, dynamic>{"a": 1}, emitsError(isFormatException), emitsDone]),
    );
  });

  test("drops the pending event when the body stops inside a character", () async {
    // Without the bad tail, the pending event would be emitted on close.
    await expectLater(
      _decodeBytes(<List<int>>[utf8.encode("data: {\"a\":1}\n"), <int>[0xC3]]),
      emitsInOrder(<Object>[emitsError(isFormatException), emitsDone]),
    );
  });
}

/// Runs `Http.listen` with [SseTransformer] against a MockClient streaming
/// [pieces] as the body; each decoded object goes to [received].
Future<void> _listen(List<String> pieces, List<Map<String, dynamic>> received) {
  return http.runWithClient(
    () => Http.listen<Map<String, dynamic>>(
      method: HttpMethodEnum.get,
      api: HttpApiEnum.api,
      route: "events",
      transformer: const SseTransformer(),
      listener: received.add,
    ),
    () => MockClient.streaming((http.BaseRequest request, http.ByteStream body) async {
      return http.StreamedResponse(Stream<List<int>>.fromIterable(pieces.map(utf8.encode)), 200);
    }),
  );
}

void _withHttpListen() {
  setUp(() {
    dotenv.testLoad(fileInput: "API_API_URL=api.example.test\nAPI_API_SCHEME=https");
  });

  test("delivers every event to the listener", () async {
    final List<Map<String, dynamic>> received = <Map<String, dynamic>>[];

    await _listen(<String>["data: {\"a\"", ":1}\n\nda", "ta: {\"b\":2}\n\n"], received);

    expect(received, <Map<String, dynamic>>[<String, dynamic>{"a": 1}, <String, dynamic>{"b": 2}]);
  });

  test("throws the FormatException after the events before it", () async {
    final List<Map<String, dynamic>> received = <Map<String, dynamic>>[];

    await expectLater(
      _listen(<String>["data: {\"a\":1}\n\ndata: oops\n\ndata: {\"b\":2}\n\n"], received),
      throwsFormatException,
    );
    expect(received, <Map<String, dynamic>>[<String, dynamic>{"a": 1}]);
  });
}
