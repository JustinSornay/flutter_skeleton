// http_test.dart
//
// Unit tests for the Http utility. The network is replaced with a MockClient
// through `runWithClient`, so the real request building, header injection,
// envelope unwrapping, error mapping and 401 retry logic all run — for the
// JSON methods, Http.request (HEAD / DELETE / body-less PATCH), Http.listen
// (streaming), Http.multipart (uploads) and Http.rawBytes (downloads).

import "dart:async";
import "dart:convert";

import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_skeleton/api/dtos/_base/input/abstract_input.dart";
import "package:flutter_skeleton/api/http/api_exception.dart";
import "package:flutter_skeleton/api/http/enums.dart";
import "package:flutter_skeleton/api/http/http.dart";
import "package:flutter_skeleton/api/http/http_file.dart";
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

/// Splits a byte stream into UTF-8 lines.
final StreamTransformer<List<int>, String> _lines = StreamTransformer<List<int>, String>.fromBind(
  (Stream<List<int>> bytes) => bytes.transform(utf8.decoder).transform(const LineSplitter()),
);

/// Opens GET "stream" and collects every decoded line in [received].
Future<void> _listen(List<String> received) {
  return Http.listen<String>(
    method: HttpMethodEnum.get,
    api: HttpApiEnum.api,
    route: "stream",
    transformer: _lines,
    listener: received.add,
  );
}

/// Uploads one CSV file and one text field to POST "uploads".
Future<HttpOutput> _upload() {
  return Http.multipart(
    api: HttpApiEnum.api,
    route: "uploads",
    files: <HttpFile>[HttpFile(field: "file", bytes: utf8.encode("id,value\n1,42"), filename: "data.csv")],
    fields: <String, String>{"label": "quarterly"},
  );
}

/// Sets a token that becomes "fresh" after one refresh.
void _expiringToken() {
  String token = "expired";
  Http.setTokenProvider(() => token);
  Http.setTokenRefreshCallback(() async => token = "fresh");
}

/// Answers 200 with [success] to the refreshed token, 401 otherwise.
Future<http.Response> Function(http.Request request) _acceptFreshToken(http.Response success) {
  return (http.Request request) async => request.headers["Authorization"] == "Bearer fresh"
      ? success
      : _json(<String, dynamic>{"detail": "token expired"}, 401);
}

/// MockClient that counts how many times Http disposes it.
final class _CountingClient extends MockClient {
  int closeCalls = 0;

  _CountingClient(super.fn);

  @override
  void close() => closeCalls++;
}

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: "API_API_URL=api.example.test\nAPI_API_SCHEME=https");
  });

  tearDown(Http.resetAuthHooks);

  group("request building", _requestBuildingTests);
  group("envelope unwrapping", _envelopeTests);
  group("error mapping", _errorMappingTests);
  group("401 handling", _unauthorizedTests);
  group("Http.request", _requestTests);
  group("Http.listen", _listenTests);
  group("Http.multipart", _multipartTests);
  group("Http.rawBytes", _rawBytesTests);
}

void _requestBuildingTests() {
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
}

void _envelopeTests() {
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
}

void _errorMappingTests() {
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
}

void _unauthorizedTests() {
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

  test("neither retries nor signs out when the refresh yields no token", () async {
    int unauthorizedCalls = 0;
    Http.setTokenProvider(() => "token");
    Http.setTokenRefreshCallback(() async => null);
    Http.setOnUnauthorizedCallback(() => unauthorizedCalls++);
    int sent = 0;

    await expectLater(
      _withMock((_) async {
        sent++;
        return _json(<String, dynamic>{}, 401);
      }, () => Http.output(api: HttpApiEnum.api, route: "me")),
      throwsA(isA<ApiException>().having((ApiException e) => e.status, "status", 401)),
    );
    expect(sent, 1);
    expect(unauthorizedCalls, 0);
  });
}


void _requestTests() {
  test("sends a body-less PATCH and accepts 204", () async {
    final List<http.Request> requests = await _withMock(
      (_) async => http.Response("", 204),
      () => Http.request(method: HttpMethodEnum.patch, api: HttpApiEnum.api, route: "items/1/archive"),
    );

    expect(requests.single.method, "PATCH");
    expect(requests.single.url.toString(), "https://api.example.test/items/1/archive");
    expect(requests.single.bodyBytes, isEmpty);
  });

  test("PATCH surfaces the body detail of an HTTP error", () async {
    await expectLater(
      _withMock(
        (_) async => _json(<String, dynamic>{"detail": "Already archived"}, 409),
        () => Http.request(method: HttpMethodEnum.patch, api: HttpApiEnum.api, route: "items/1/archive"),
      ),
      throwsA(isA<ApiException>()
        .having((ApiException e) => e.status, "status", 409)
        .having((ApiException e) => e.detail, "detail", "Already archived")),
    );
  });
}

void _listenTests() {
  test("pipes every streamed chunk with the auth headers", () async {
    Http.setTokenProvider(() => "secret");
    final List<String> received = <String>[];
    final List<http.BaseRequest> requests = <http.BaseRequest>[];

    await http.runWithClient(
      () => _listen(received),
      () => MockClient.streaming((http.BaseRequest request, http.ByteStream _) async {
        requests.add(request);
        return http.StreamedResponse(Stream<List<int>>.fromIterable(<List<int>>[utf8.encode("a\nb"), utf8.encode("\nc\n")]), 200);
      }),
    );

    expect(received, <String>["a", "b", "c"]);
    expect(requests.single.headers["Authorization"], "Bearer secret");
    expect(requests.single.headers["Content-Type"], startsWith("application/json"));
  });

  test("HTTP 4xx throws ApiException with the body detail, listener not called", () async {
    final List<String> received = <String>[];

    await expectLater(
      _withMock((_) async => _json(<String, dynamic>{"title": "Quota exceeded"}, 429), () => _listen(received)),
      throwsA(isA<ApiException>()
        .having((ApiException e) => e.status, "status", 429)
        .having((ApiException e) => e.detail, "detail", "Quota exceeded")),
    );
    expect(received, isEmpty);
  });

  test("non-JSON error body falls back to the status text and closes the client once", () async {
    final _CountingClient client = _CountingClient((_) async => http.Response("oops", 503));

    await expectLater(
      http.runWithClient(() => _listen(<String>[]), () => client),
      throwsA(isA<ApiException>().having((ApiException e) => e.detail, "detail", "Service Unavailable")),
    );
    expect(client.closeCalls, 1);
  });

  test("refreshes the token once after a 401 and re-opens the stream", () async {
    _expiringToken();
    final List<String> received = <String>[];

    final List<http.Request> requests = await _withMock(
      _acceptFreshToken(http.Response("a\nb\n", 200)),
      () => _listen(received),
    );

    expect(requests.map((http.Request r) => r.headers["Authorization"]), <String>["Bearer expired", "Bearer fresh"]);
    expect(received, <String>["a", "b"]);
  });

  test("calls onUnauthorized when the re-opened stream is rejected as well", () async {
    int unauthorizedCalls = 0;
    final List<String> received = <String>[];
    Http.setTokenProvider(() => "token");
    Http.setTokenRefreshCallback(() async => "still-bad");
    Http.setOnUnauthorizedCallback(() => unauthorizedCalls++);

    await expectLater(
      _withMock((_) async => _json(<String, dynamic>{"detail": "Session expired"}, 401), () => _listen(received)),
      throwsA(isA<ApiException>()
        .having((ApiException e) => e.status, "status", 401)
        .having((ApiException e) => e.detail, "detail", "Session expired")),
    );
    expect(unauthorizedCalls, 1);
    expect(received, isEmpty);
  });
}

void _multipartTests() {
  test("sends the files and fields as multipart/form-data with the bearer token", () async {
    Http.setTokenProvider(() => "secret");
    late HttpOutput output;

    final List<http.Request> requests = await _withMock(
      (_) async => _json(<String, dynamic>{"id": "u1"}, 201),
      () async => output = await _upload(),
    );

    final http.Request request = requests.single;
    final String body = utf8.decode(request.bodyBytes);
    expect(request.method, "POST");
    expect(request.url.toString(), "https://api.example.test/uploads");
    expect(request.headers["Authorization"], "Bearer secret");
    expect(request.headers["content-type"], startsWith("multipart/form-data; boundary="));
    expect(body, contains("name=\"label\"\r\n\r\nquarterly\r\n"));
    expect(body, contains("name=\"file\"; filename=\"data.csv\""));
    expect(body, contains("id,value\n1,42"));
    expect(output.cast<String>("id"), "u1");
  });

  test("re-sends fresh parts after a 401 and a token refresh", () async {
    _expiringToken();
    late HttpOutput output;

    final List<http.Request> requests = await _withMock(
      _acceptFreshToken(_json(<String, dynamic>{"id": "u2"})),
      () async => output = await _upload(),
    );

    expect(requests.map((http.Request r) => r.headers["Authorization"]), <String>["Bearer expired", "Bearer fresh"]);
    for (final http.Request request in requests) {
      final String body = utf8.decode(request.bodyBytes);
      expect(body, contains("filename=\"data.csv\""));
      expect(body, contains("id,value\n1,42"));
      expect(body, contains("quarterly"));
    }
    expect(output.cast<String>("id"), "u2");
  });

  test("HTTP 4xx throws ApiException with the body detail", () async {
    await expectLater(
      _withMock((_) async => _json(<String, dynamic>{"error": "File too large"}, 413), _upload),
      throwsA(isA<ApiException>()
        .having((ApiException e) => e.status, "status", 413)
        .having((ApiException e) => e.detail, "detail", "File too large")),
    );
  });
}

void _rawBytesTests() {
  test("returns the body bytes untouched with the bearer token and query", () async {
    final List<int> payload = <int>[0, 255, 1, 128, 10];
    Http.setTokenProvider(() => "secret");
    late List<int> bytes;

    final List<http.Request> requests = await _withMock(
      (_) async => http.Response.bytes(payload, 200),
      () async => bytes = await Http.rawBytes(
        api: HttpApiEnum.api,
        route: "exports/1",
        queryBuilder: ApiFilterBuilder()..addParam("format", "pdf"),
      ),
    );

    expect(bytes, payload);
    expect(requests.single.method, "GET");
    expect(requests.single.url.toString(), "https://api.example.test/exports/1?format=pdf");
    expect(requests.single.headers["Authorization"], "Bearer secret");
  });

  test("HTTP 4xx throws ApiException with the body detail", () async {
    await expectLater(
      _withMock(
        (_) async => _json(<String, dynamic>{"detail": "Export not found"}, 404),
        () => Http.rawBytes(api: HttpApiEnum.api, route: "exports/9"),
      ),
      throwsA(isA<ApiException>()
        .having((ApiException e) => e.status, "status", 404)
        .having((ApiException e) => e.detail, "detail", "Export not found")),
    );
  });

  test("refreshes the token once after a 401 and retries", () async {
    _expiringToken();
    late List<int> bytes;

    final List<http.Request> requests = await _withMock(
      _acceptFreshToken(http.Response.bytes(<int>[1, 2, 3], 200)),
      () async => bytes = await Http.rawBytes(api: HttpApiEnum.api, route: "exports/1"),
    );

    expect(requests, hasLength(2));
    expect(bytes, <int>[1, 2, 3]);
  });
}
