// http_test.dart
//
// Unit tests for the Http utility. The network is replaced with a MockClient
// through `runWithClient`, so the real request building, header injection,
// envelope unwrapping, error mapping and 401 retry logic all run.

import "dart:convert";

import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_skeleton/api/dtos/_base/input/abstract_input.dart";
import "package:flutter_skeleton/api/http/api_exception.dart";
import "package:flutter_skeleton/api/http/enums.dart";
import "package:flutter_skeleton/api/http/http.dart";
import "package:flutter_skeleton/api/http/http_output.dart";
import "package:flutter_skeleton/api/services/_base/apiFilterBuilder/api_filter_builder.dart";
import "package:flutter_test/flutter_test.dart";
import "package:http/http.dart" as http;
import "package:http/testing.dart";

final class _NameInput extends AbstractInput {
  final String name;
  const _NameInput(this.name);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{"name": name};
}

http.Response _json(Object body, [int status = 200]) {
  return http.Response(jsonEncode(body), status, headers: <String, String>{"content-type": "application/json"});
}

/// Runs [body] with every `Client()` replaced by a MockClient answering with
/// [handler]. Returns the requests that were sent.
Future<List<http.Request>> _withMock(
  Future<http.Response> Function(http.Request request) handler,
  Future<void> Function() body,
) async {
  final List<http.Request> requests = <http.Request>[];
  await http.runWithClient(body, () => MockClient((http.Request request) {
    requests.add(request);
    return handler(request);
  }));
  return requests;
}

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: "API_API_URL=api.example.test\nAPI_API_SCHEME=https");
  });

  tearDown(Http.resetAuthHooks);

  group("request building", () {
    test("builds the URI from env vars, route and query builder", () async {
      final List<http.Request> requests = await _withMock(
        (_) async => _json(<dynamic>[]),
        () => Http.listOutput(
          api: HttpApiEnum.api,
          route: "todos",
          queryBuilder: ApiFilterBuilder()..addParam("_page", 2)..addParam("missing", null),
        ),
      );

      expect(requests.single.method, "GET");
      expect(requests.single.url.toString(), "https://api.example.test/todos?_page=2");
    });

    test("uses http when <KEY>_API_SCHEME=http", () async {
      dotenv.testLoad(fileInput: "API_API_URL=localhost:8080\nAPI_API_SCHEME=http");
      final List<http.Request> requests = await _withMock(
        (_) async => _json(<String, dynamic>{}),
        () => Http.output(api: HttpApiEnum.api, route: "health"),
      );

      expect(requests.single.url.toString(), "http://localhost:8080/health");
    });

    test("sends JSON content type and the bearer token when available", () async {
      Http.setTokenProvider(() => "secret");
      final List<http.Request> requests = await _withMock(
        (_) async => _json(<String, dynamic>{"id": 1}),
        () => Http.input(
          method: HttpMethodEnum.post,
          api: HttpApiEnum.api,
          route: "items",
          body: const _NameInput("demo"),
        ),
      );

      final http.Request request = requests.single;
      expect(request.method, "POST");
      expect(request.headers["Authorization"], "Bearer secret");
      expect(request.headers["Content-Type"], startsWith("application/json"));
      expect(jsonDecode(request.body), <String, dynamic>{"name": "demo"});
      expect(Http.hasToken, isTrue);
    });

    test("omits Authorization when no token is set", () async {
      final List<http.Request> requests = await _withMock(
        (_) async => _json(<String, dynamic>{}),
        () => Http.output(api: HttpApiEnum.api, route: "public"),
      );

      expect(requests.single.headers.containsKey("Authorization"), isFalse);
      expect(Http.hasToken, isFalse);
    });

    test("throws StateError when the API host is not configured", () async {
      dotenv.testLoad(fileInput: "OTHER=1");
      await expectLater(
        _withMock((_) async => _json(<String, dynamic>{}), () => Http.output(api: HttpApiEnum.api, route: "x")),
        throwsStateError,
      );
    });
  });

  group("envelope unwrapping", () {
    test("output unwraps a `data` object", () async {
      late HttpOutput output;
      await _withMock(
        (_) async => _json(<String, dynamic>{"data": <String, dynamic>{"id": 7}}),
        () async => output = await Http.output(api: HttpApiEnum.api, route: "items/7"),
      );
      expect(output.cast<int>("id"), 7);
    });

    test("output keeps an object whose `data` is a list next to siblings", () async {
      late HttpOutput output;
      await _withMock(
        (_) async => _json(<String, dynamic>{"data": <int>[1, 2], "total": 2}),
        () async => output = await Http.output(api: HttpApiEnum.api, route: "items"),
      );
      expect(output.cast<int>("total"), 2);
    });

    test("listOutput accepts a bare array and a `data` envelope", () async {
      late List<HttpOutput> bare;
      late List<HttpOutput> wrapped;
      await _withMock(
        (_) async => _json(<Map<String, int>>[<String, int>{"id": 1}, <String, int>{"id": 2}]),
        () async => bare = await Http.listOutput(api: HttpApiEnum.api, route: "items"),
      );
      await _withMock(
        (_) async => _json(<String, dynamic>{"data": <Map<String, int>>[<String, int>{"id": 3}]}),
        () async => wrapped = await Http.listOutput(api: HttpApiEnum.api, route: "items"),
      );

      expect(bare.map((HttpOutput o) => o.cast<int>("id")), <int>[1, 2]);
      expect(wrapped.single.cast<int>("id"), 3);
    });
  });

  group("error mapping", () {
    test("HTTP 400+ throws ApiException with the body detail", () async {
      await expectLater(
        _withMock(
          (_) async => _json(<String, dynamic>{"detail": "Todo not found"}, 404),
          () => Http.output(api: HttpApiEnum.api, route: "todos/999"),
        ),
        throwsA(isA<ApiException>()
          .having((ApiException e) => e.status, "status", 404)
          .having((ApiException e) => e.detail, "detail", "Todo not found")),
      );
    });

    test("non-JSON error body falls back to the status text", () async {
      await expectLater(
        _withMock(
          (_) async => http.Response("<html>oops</html>", 502),
          () => Http.listOutput(api: HttpApiEnum.api, route: "todos"),
        ),
        throwsA(isA<ApiException>().having((ApiException e) => e.detail, "detail", "Bad Gateway")),
      );
    });

    test("request (DELETE) surfaces HTTP errors too", () async {
      await expectLater(
        _withMock(
          (_) async => http.Response("", 500),
          () => Http.request(method: HttpMethodEnum.delete, api: HttpApiEnum.api, route: "todos/1"),
        ),
        throwsA(isA<ApiException>().having((ApiException e) => e.status, "status", 500)),
      );
    });
  });

  group("401 handling", () {
    test("refreshes the token once and retries", () async {
      String token = "expired";
      Http.setTokenProvider(() => token);
      Http.setTokenRefreshCallback(() async => token = "fresh");

      late HttpOutput output;
      final List<http.Request> requests = await _withMock(
        (http.Request request) async => request.headers["Authorization"] == "Bearer fresh"
            ? _json(<String, dynamic>{"ok": true})
            : _json(<String, dynamic>{}, 401),
        () async => output = await Http.output(api: HttpApiEnum.api, route: "me"),
      );

      expect(requests, hasLength(2));
      expect(output.cast<bool>("ok"), isTrue);
    });

    test("calls onUnauthorized when the retry is rejected as well", () async {
      int unauthorizedCalls = 0;
      Http.setTokenProvider(() => "token");
      Http.setTokenRefreshCallback(() async => "still-bad");
      Http.setOnUnauthorizedCallback(() => unauthorizedCalls++);

      await expectLater(
        _withMock((_) async => _json(<String, dynamic>{}, 401), () => Http.output(api: HttpApiEnum.api, route: "me")),
        throwsA(isA<ApiException>().having((ApiException e) => e.status, "status", 401)),
      );
      expect(unauthorizedCalls, 1);
    });
  });
}
