// json_object_test.dart
//
// Unit tests for decodeJsonObject (objects pass through, invalid JSON and JSON
// of another kind throw FormatException) and addJsonObject (the same outcome
// as a data or error event on a sink).

import "dart:async";

import "package:flutter_skeleton/api/http/transformers/json_object.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("decodeJsonObject", _decodeJsonObject);
  group("addJsonObject", _addJsonObject);
}

void _decodeJsonObject() {
  test("returns a decoded JSON object", () {
    expect(decodeJsonObject(" {\"a\": [1, {\"b\": null}]} "), <String, dynamic>{
      "a": <dynamic>[1, <String, dynamic>{"b": null}],
    });
  });

  test("throws FormatException on invalid JSON", () {
    expect(() => decodeJsonObject("{oops"), throwsFormatException);
    expect(() => decodeJsonObject(""), throwsFormatException);
  });

  test("throws FormatException on JSON that is not an object", () {
    for (final String source in <String>["[1]", "\"text\"", "42", "true", "null"]) {
      expect(() => decodeJsonObject(source), throwsFormatException, reason: source);
    }
  });
}

void _addJsonObject() {
  test("adds the object, or the FormatException as an error, without throwing", () async {
    final StreamController<Map<String, dynamic>> controller = StreamController<Map<String, dynamic>>();
    final Future<void> expectation = expectLater(
      controller.stream,
      emitsInOrder(<Object>[
        <String, dynamic>{"a": 1},
        emitsError(isFormatException),
        emitsError(isFormatException),
        emitsDone,
      ]),
    );

    addJsonObject(controller.sink, "{\"a\":1}");
    addJsonObject(controller.sink, "{oops");
    addJsonObject(controller.sink, "[1]");
    await controller.close();
    await expectation;
  });
}
