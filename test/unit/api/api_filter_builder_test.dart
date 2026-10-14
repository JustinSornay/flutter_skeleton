// api_filter_builder_test.dart
//
// Unit tests for ApiFilterBuilder / ApiFilter query-string serialization.

import "package:flutter_skeleton/api/services/_base/apiFilterBuilder/api_filter.dart";
import "package:flutter_skeleton/api/services/_base/apiFilterBuilder/api_filter_builder.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("addParam stringifies values and skips nulls", () {
    final ApiFilterBuilder builder = ApiFilterBuilder()
      ..addParam("page", 2)
      ..addParam("done", true)
      ..addParam("query", null);

    expect(builder.toMap(), <String, dynamic>{"page": "2", "done": "true"});
    expect(builder.toString(), "?page=2&done=true");
  });

  test("an empty builder serializes to an empty string", () {
    expect(ApiFilterBuilder().toString(), "");
    expect(ApiFilterBuilder().toMap(), isEmpty);
  });

  test("list filters repeat the key", () {
    final ApiFilterBuilder builder = ApiFilterBuilder()
      ..add(ApiFilter(key: "tag", valueList: <String>["a", "b"]));

    expect(builder.toMap(), <String, dynamic>{"tag": <String>["a", "b"]});
    expect(builder.toString(), "?tag=a&tag=b");
    expect(
      Uri.https("example.test", "items", builder.toMap()).query,
      "tag=a&tag=b",
    );
  });

  test("ApiFilter requires exactly one of value / valueList", () {
    expect(() => ApiFilter(key: "k"), throwsA(isA<AssertionError>()));
    expect(
      () => ApiFilter(key: "k", value: "v", valueList: <String>["v"]),
      throwsA(isA<AssertionError>()),
    );
  });
}
