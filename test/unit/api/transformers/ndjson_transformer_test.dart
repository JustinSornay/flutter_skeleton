// ndjson_transformer_test.dart
//
// Unit tests for NdjsonTransformer: line framing across chunk boundaries and
// line endings, blank lines, the unterminated last line, chunked UTF-8
// decoding, FormatException stream errors (JSON: keep going; UTF-8: end the
// stream), and the end-to-end path through Http.listen (MockClient).

import "dart:convert";

import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_skeleton/api/http/enums.dart";
import "package:flutter_skeleton/api/http/http.dart";
import "package:flutter_skeleton/api/http/transformers/ndjson_transformer.dart";
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";

/// Feeds each byte chunk to a fresh [NdjsonTransformer].
Stream<Map<String, dynamic>> _decodeBytes(List<List<int>> chunks) {
  return Stream<List<int>>.fromIterable(chunks).transform(const NdjsonTransformer());
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
  group("UTF-8", _utf8);
  group("errors", _errors);
  group("with Http.listen", _withHttpListen);
}

void _framing() {
  test("emits one JSON object per line", () async {
    expect(
      await _decode(<String>["{\"a\":1}\n{\"b\":2}\n"]).toList(),
      <Map<String, dynamic>>[<String, dynamic>{"a": 1}, <String, dynamic>{"b": 2}],
    );
  });

  test("reassembles lines split anywhere across chunks", () async {
    expect(
      await _decodeBytes(_byteByByte("{\"a\":1}\n{\"b\":2}\n")).toList(),
      <Map<String, dynamic>>[<String, dynamic>{"a": 1}, <String, dynamic>{"b": 2}],
    );
  });

  test("accepts \\r\\n line endings, even with \\r and \\n in separate chunks", () async {
    expect(
      await _decode(<String>["{\"a\":1}\r", "\n{\"b\":2}\r\n"]).toList(),
      <Map<String, dynamic>>[<String, dynamic>{"a": 1}, <String, dynamic>{"b": 2}],
    );
  });

  test("skips blank and whitespace-only lines", () async {
    expect(
      await _decode(<String>["\n{\"a\":1}\n\n   \n\t\r\n{\"b\":2}\n\n"]).toList(),
      <Map<String, dynamic>>[<String, dynamic>{"a": 1}, <String, dynamic>{"b": 2}],
    );
  });

  test("emits a last line without a trailing newline when the stream closes", () async {
    expect(
      await _decode(<String>["{\"a\":1}\n{\"b\"", ":2}"]).toList(),
      <Map<String, dynamic>>[<String, dynamic>{"a": 1}, <String, dynamic>{"b": 2}],
    );
  });
}

void _utf8() {
  test("keeps a 2-byte character split between two chunks intact", () async {
    final List<int> bytes = utf8.encode("{\"name\":\"café\"}\n");
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
      await _decodeBytes(_byteByByte("{\"name\":\"€ \u{1D11E}\"}\n")).toList(),
      <Map<String, dynamic>>[<String, dynamic>{"name": "€ \u{1D11E}"}],
    );
  });
}

void _errors() {
  test("reports a malformed line as a FormatException and keeps going", () async {
    await expectLater(
      _decode(<String>["{\"a\":1}\n{oops\n{\"b\":2}\n"]),
      emitsInOrder(<Object>[
        <String, dynamic>{"a": 1},
        emitsError(isFormatException),
        <String, dynamic>{"b": 2},
        emitsDone,
      ]),
    );
  });

  test("reports a line that is not a JSON object as a FormatException", () async {
    await expectLater(
      _decode(<String>["\"done\"\n"]),
      emitsInOrder(<Object>[emitsError(isFormatException), emitsDone]),
    );
  });

  test("reports an unterminated malformed last line as a FormatException", () async {
    await expectLater(
      _decode(<String>["{\"a\":1}\n{\"b\":"]),
      emitsInOrder(<Object>[<String, dynamic>{"a": 1}, emitsError(isFormatException), emitsDone]),
    );
  });

  test("ends the stream with a FormatException at an invalid UTF-8 byte", () async {
    // A lenient decoder would turn 0xFF into U+FFFD and emit {"b": "x\uFFFD"}.
    await expectLater(
      _decodeBytes(<List<int>>[
        utf8.encode("{\"a\":1}\n"),
        <int>[...utf8.encode("{\"b\":\"x"), 0xFF, ...utf8.encode("\"}\n")],
        utf8.encode("{\"c\":3}\n"),
      ]),
      emitsInOrder(<Object>[<String, dynamic>{"a": 1}, emitsError(isFormatException), emitsDone]),
    );
  });

  test("ends the stream with a FormatException when the body stops inside a character", () async {
    await expectLater(
      _decodeBytes(<List<int>>[utf8.encode("{\"a\":1}\n{\"b\":\"caf"), <int>[0xC3]]),
      emitsInOrder(<Object>[<String, dynamic>{"a": 1}, emitsError(isFormatException), emitsDone]),
    );
  });
}

/// Runs `Http.listen` with [NdjsonTransformer] against a MockClient streaming
/// [pieces] as the body; each decoded object goes to [received].
Future<void> _listen(List<String> pieces, List<Map<String, dynamic>> received) {
  return http.runWithClient(
    () => Http.listen<Map<String, dynamic>>(
      method: HttpMethodEnum.get,
      api: HttpApiEnum.api,
      route: "items",
      transformer: const NdjsonTransformer(),
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

  test("delivers every line to the listener", () async {
    final List<Map<String, dynamic>> received = <Map<String, dynamic>>[];

    await _listen(<String>["{\"a\"", ":1}\n{\"b\":2}"], received);

    expect(received, <Map<String, dynamic>>[<String, dynamic>{"a": 1}, <String, dynamic>{"b": 2}]);
  });

  test("throws the FormatException after the lines before it", () async {
    final List<Map<String, dynamic>> received = <Map<String, dynamic>>[];

    await expectLater(_listen(<String>["{\"a\":1}\noops\n{\"b\":2}\n"], received), throwsFormatException);
    expect(received, <Map<String, dynamic>>[<String, dynamic>{"a": 1}]);
  });
}
