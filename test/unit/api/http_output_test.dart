// http_output_test.dart
//
// Unit tests for HttpOutput — the strict typed accessor DTOs read from.

import "package:flutter_skeleton/api/http/http_output.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  const HttpOutput output = HttpOutput.fromJson(<String, dynamic>{
    "id": 1,
    "title": "Write tests",
    "note": null,
    "owner": <String, dynamic>{"id": 9},
    "tags": <dynamic>[
      <String, dynamic>{"label": "a"},
      <String, dynamic>{"label": "b"},
    ],
  });

  test("cast returns typed primitives", () {
    expect(output.cast<int>("id"), 1);
    expect(output.cast<String>("title"), "Write tests");
  });

  test("cast to a nullable type accepts an explicit null", () {
    expect(output.cast<String?>("note"), isNull);
  });

  test("cast throws on a type mismatch", () {
    expect(() => output.cast<String>("id"), throwsA(isA<AssertionError>()));
  });

  test("missing keys throw, even for nullable types", () {
    expect(() => output["missing"], throwsA(isA<AssertionError>()));
    expect(() => output.cast<String?>("missing"), throwsA(isA<AssertionError>()));
  });

  test("output wraps a nested object", () {
    expect(output.output("owner").cast<int>("id"), 9);
  });

  test("outputList wraps each element of a nested array", () {
    expect(
      output.outputList("tags").map((HttpOutput tag) => tag.cast<String>("label")),
      <String>["a", "b"],
    );
  });
}
