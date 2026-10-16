// http.dart
//
// Central HTTP utility for all backend communication. Services never touch
// the http package directly — they call one of the static factory methods
// (output, listOutput, input, request, listen, multipart, rawBytes) which
// handle request construction, auth headers, response parsing, error mapping,
// and logging. Every one of them goes through the same send path (_open):
// Bearer header, one token refresh + retry on 401, ApiException for 400+.
//
// Configuration is read from .env.local at runtime using the HttpApiEnum key
// as a prefix (e.g. API_API_URL, API_API_SCHEME).
//
// Relationships:
//   - Used by every class in api/services/
//   - Produces HttpOutput instances consumed by DTO .fromOutput() constructors
//   - Sends HttpFile parts for multipart uploads (http_file.dart)
//   - Throws ApiException for any HTTP 400+ response

import "dart:async";
import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter_skeleton/api/dtos/_base/input/abstract_input.dart";
import "package:flutter_skeleton/api/http/api_exception.dart";
import "package:flutter_skeleton/api/http/enums.dart";
import "package:flutter_skeleton/api/http/http_file.dart";
import "package:flutter_skeleton/api/http/http_output.dart";
import "package:flutter_skeleton/api/services/_base/apiFilterBuilder/api_filter_builder.dart";
import "package:flutter_skeleton/utils/env.dart";
import "package:http/http.dart";
import "package:logger/logger.dart";

/// Low-level HTTP client wrapper. Instantiated internally — callers use the
/// static factory methods rather than constructing this class directly.
///
/// Tests replace the network with `runWithClient(() => ..., () => MockClient(...))`
/// from `package:http`: the [Client] created here picks up the zone override.
final class Http {
  final Client _client = Client();
  final HttpMethodEnum method;
  final HttpApiEnum api;
  final String route;
  final ApiFilterBuilder? queryBuilder;
  final AbstractInput? body;
  /// File parts of a multipart/form-data request ([Http.multipart]); null for
  /// a JSON request. Fresh parts are built from them on every attempt.
  final List<HttpFile>? files;
  /// Text fields of a multipart/form-data request ([Http.multipart]).
  final Map<String, String> fields;

  static String? Function()? _tokenProvider;
  static Future<String?> Function()? _tokenRefreshCallback;
  // Called once when a 401 persists after token refresh — signals the app to force sign-out.
  static void Function()? _onUnauthorizedCallback;

  /// Registers a dynamic token provider (typically called by an auth provider
  /// on init). The returned token is sent as `Authorization: Bearer <token>`.
  static void setTokenProvider(String? Function()? provider) {
    _tokenProvider = provider;
  }

  /// Registers an async callback that force-refreshes the token.
  /// Used to retry a request once after a 401 response.
  static void setTokenRefreshCallback(Future<String?> Function()? callback) {
    _tokenRefreshCallback = callback;
  }

  /// Registers the callback invoked when authentication fails irrecoverably
  /// (401 again after a token refresh). Last-write-wins.
  static void setOnUnauthorizedCallback(void Function()? callback) {
    _onUnauthorizedCallback = callback;
  }

  /// Clears every auth hook. Call from `tearDown` in tests that set them.
  @visibleForTesting
  static void resetAuthHooks() {
    _tokenProvider = null;
    _tokenRefreshCallback = null;
    _onUnauthorizedCallback = null;
  }

  /// Returns true when a non-empty token is currently available.
  /// Use this as a proactive guard before calling auth-gated endpoints.
  static bool get hasToken {
    final String? token = _tokenProvider?.call();
    return token != null && token.isNotEmpty;
  }

  /// Builds the Authorization and Content-Type headers.
  /// When no token is available, no Authorization header is sent —
  /// public API routes work without a token. Multipart requests set their own
  /// Content-Type (with the part boundary).
  Map<String, String> get _headers {
    final Map<String, String> headers = <String, String>{
      if (files == null) "Content-Type": "application/json",
    };

    final String? token = _tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }

    return headers;
  }

  /// Assembles the full request URI from env vars and the optional query builder.
  /// Scheme is read from `<KEY>_API_SCHEME` (defaults to "https").
  Uri get uri {
    final String? host = Env.get("${api.key}_API_URL");
    if (host == null) {
      throw StateError("${api.key}_API_URL is missing from .env.local");
    }
    final String scheme = Env.get("${api.key}_API_SCHEME") ?? "https";
    final Uri Function(String, [String, Map<String, dynamic>?]) factory =
        scheme == "http" ? Uri.http : Uri.https;
    return factory(host, route, queryBuilder?.toMap());
  }

  Http._internal({
    required this.method,
    required this.route,
    required this.api,
    this.queryBuilder,
    this.body,
    this.files,
    this.fields = const <String, String>{},
  }):
    // A JSON body or multipart parts are required for POST / PUT (PATCH may be
    // body-less, see [request]); never both; routes must not start with a slash.
    assert(body != null || files != null || <HttpMethodEnum>[HttpMethodEnum.get, HttpMethodEnum.delete, HttpMethodEnum.head, HttpMethodEnum.patch].contains(method)),
    assert(body == null || files == null),
    assert(!route.startsWith("/"));

  /// Decodes the response body as UTF-8 JSON.
  dynamic parse(Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  /// Builds a new request for every attempt: a request (and a multipart file
  /// part) can be sent only once, and the 401 retry needs the fresh token.
  BaseRequest _buildRequest() {
    final List<HttpFile>? files = this.files;
    if (files != null) {
      return MultipartRequest(method.key, uri)
        ..headers.addAll(_headers)
        ..fields.addAll(fields)
        ..files.addAll(files.map((HttpFile file) => MultipartFile.fromBytes(
          file.field,
          file.bytes,
          filename: file.filename,
          contentType: _mediaType(file.contentType),
        )));
    }
    final Request request = Request(method.key, uri)..headers.addAll(_headers);
    if (body != null) {
      request.body = jsonEncode(body!.toJson());
    }
    return request;
  }

  /// Parses an [HttpFile.contentType]; null keeps the octet-stream default.
  /// Throws [FormatException] for an invalid MIME type.
  static MediaType? _mediaType(String? contentType) {
    return contentType == null ? null : MediaType.parse(contentType);
  }


  /// Sends one attempt of the request and returns the [StreamedResponse]
  /// (body not read yet). Logs transport failures when LOGGER_ERROR is enabled.
  Future<StreamedResponse> stream() async {
    try {
      return await _client.send(_buildRequest());
    } catch (error) {
      if (Env.flag("LOGGER_ERROR")) {
        Logger().e("Fail to call $method $uri");
      }
      rethrow;
    }
  }

  /// Releases the underlying HTTP client. Called automatically by all static
  /// factory methods after the response is processed.
  void dispose() {
    _client.close();
  }

  /// Maps HTTP status codes to human-readable descriptions.
  static String statusCodeToString(int code) {
    return switch (code) {
      400 => "Bad Request",
      401 => "Authentication required",
      403 => "Forbidden",
      404 => "Not Found",
      409 => "Conflict",
      422 => "Unprocessable Entity",
      429 => "Too Many Requests",
      500 => "Internal Server Error",
      502 => "Bad Gateway",
      503 => "Service Unavailable",
      _ => "HTTP Error $code",
    };
  }

  /// The single send path of every factory method: opens [http] and returns
  /// the response (body not read yet) once it is known to be successful.
  ///
  /// On 401 it refreshes the token once and retries with a freshly built
  /// request; a 401 after that refresh calls the onUnauthorized callback.
  /// Any HTTP 400+ response throws [ApiException] (see [_errorDetail]).
  static Future<StreamedResponse> _open(Http http, {bool isRetry = false}) async {
    final StreamedResponse streamed = await http.stream();
    if (streamed.statusCode < 400) {
      return streamed;
    }
    // Read the error body: frees the connection and carries the detail.
    final Response response = await Response.fromStream(streamed);

    if (response.statusCode == 401 && !isRetry && _tokenRefreshCallback != null) {
      final String? freshToken = await _tokenRefreshCallback!();
      if (freshToken != null) {
        return _open(http, isRetry: true);
      }
    }
    // 401 after a successful refresh — the session is irrecoverably expired.
    if (response.statusCode == 401 && isRetry) {
      _onUnauthorizedCallback?.call();
    }

    final String detail = _errorDetail(http, response);
    if (Env.flag("LOGGER_ERROR")) {
      Logger().e("${http.method} ${http.uri} → ${response.statusCode}: $detail");
    }
    throw ApiException(
      status: response.statusCode,
      detail: detail,
    );
  }

  /// Error message of an HTTP 400+ [response]: the body's `detail`, `title`
  /// or `error` field, else the HTTP status text.
  static String _errorDetail(Http http, Response response) {
    final String fallback = statusCodeToString(response.statusCode);
    try {
      final Map<String, dynamic> error = http.parse(response) as Map<String, dynamic>;
      return error["detail"] as String? ?? error["title"] as String? ?? error["error"] as String? ?? fallback;
    } catch (_) {
      // Empty or non-JSON error body — keep the HTTP status text.
      return fallback;
    }
  }

  /// Sends [http] through [_open] and reads the whole successful response.
  static Future<Response> _send(Http http) async {
    final Response response = await Response.fromStream(await _open(http));
    if (Env.flag("LOGGER_VERBOSE")) {
      Logger().t("Success to call ${http.method} ${http.uri}");
    }
    return response;
  }

  /// Runs [action] against a fresh [Http] and always disposes its client.
  static Future<T> _run<T>(Http http, Future<T> Function(Http http) action) async {
    try {
      return await action(http);
    } finally {
      http.dispose();
    }
  }

  /// GET a single resource. Unwraps the `data` envelope when present.
  ///
  /// Use this for endpoints that return a single JSON object.
  /// [route] must not start with a slash (e.g. `"todos/123"`).
  static Future<HttpOutput> output({
    required HttpApiEnum api,
    required String route,
    ApiFilterBuilder? queryBuilder,
  }) {
    final Http http = Http._internal(
      method: HttpMethodEnum.get,
      api: api,
      route: route,
      queryBuilder: queryBuilder,
    );

    return _run(http, (Http http) async {
      final dynamic parsed = http.parse(await _send(http));
      if (parsed is Map<String, dynamic> && parsed["data"] is Map<String, dynamic>) {
        // Object wrapped in a `data` envelope → unwrap the inner object.
        return HttpOutput.fromJson(parsed["data"] as Map<String, dynamic>);
      }
      // Bare object, or an object whose `data` is a list next to sibling
      // fields (e.g. {data: [...], total: 42}) → return it whole.
      return HttpOutput.fromJson(parsed as Map<String, dynamic>);
    });
  }

  /// GET a collection. Unwraps the `data` envelope when present.
  ///
  /// Use this for endpoints that return a JSON array. Each item is wrapped
  /// in its own [HttpOutput] instance.
  static Future<List<HttpOutput>> listOutput({
    required HttpApiEnum api,
    required String route,
    ApiFilterBuilder? queryBuilder,
  }) {
    final Http http = Http._internal(
      method: HttpMethodEnum.get,
      api: api,
      route: route,
      queryBuilder: queryBuilder,
    );

    return _run(http, (Http http) async {
      final dynamic parsed = http.parse(await _send(http));
      final List<dynamic> items = parsed is Map<String, dynamic> && parsed.containsKey("data")
          ? parsed["data"] as List<dynamic>
          : parsed as List<dynamic>;
      return items
        .map((dynamic item) => HttpOutput.fromJson(item as Map<String, dynamic>))
        .toList();
    });
  }

  /// POST / PUT / PATCH with a request body. Returns the response as [HttpOutput].
  ///
  /// [method] must be one of post, put, or patch — enforced by assertion.
  /// [body] is serialized to JSON via [AbstractInput.toJson].
  static Future<HttpOutput> input({
    required HttpMethodEnum method,
    required HttpApiEnum api,
    required String route,
    required AbstractInput body,
    ApiFilterBuilder? queryBuilder,
  }) {
    assert(<HttpMethodEnum>[HttpMethodEnum.post, HttpMethodEnum.put, HttpMethodEnum.patch].contains(method));

    final Http http = Http._internal(
      method: method,
      api: api,
      route: route,
      body: body,
      queryBuilder: queryBuilder,
    );

    return _run(http, (Http http) async {
      return HttpOutput.fromJson(http.parse(await _send(http)) as Map<String, dynamic>);
    });
  }

  /// HEAD, DELETE or PATCH request sent without a body; the response body
  /// (if any, e.g. none on 204) is ignored.
  ///
  /// Use for side-effect-only operations (e.g. deleting an entry, or a state
  /// transition such as `PATCH items/1/archive` → 204). A PATCH that carries
  /// data goes through [input] instead: this method never sends a body.
  /// [method] must be head, delete or patch — enforced by assertion.
  /// Throws [ApiException] for HTTP 400+ responses like every other method.
  static Future<void> request({
    required HttpMethodEnum method,
    required HttpApiEnum api,
    required String route,
  }) {
    assert(<HttpMethodEnum>[HttpMethodEnum.head, HttpMethodEnum.delete, HttpMethodEnum.patch].contains(method));

    final Http http = Http._internal(
      method: method,
      api: api,
      route: route,
    );

    return _run(http, _send);
  }

  /// Opens a streaming connection and pipes each decoded chunk to [listener].
  ///
  /// [transformer] converts raw bytes to [T] (e.g. an SSE decoder). The
  /// returned future completes when the stream closes or throws on the first
  /// error (cancelOnError is always true). Same auth and error contract as
  /// every other method: one token refresh + re-open on 401, [ApiException]
  /// (detail from the body) when the server answers with HTTP 400+ before
  /// streaming — [listener] is not called then.
  static Future<void> listen<T>({
    required HttpMethodEnum method,
    required HttpApiEnum api,
    required String route,
    required void Function(T) listener,
    required StreamTransformer<List<int>, T> transformer,
    AbstractInput? body,
    ApiFilterBuilder? queryBuilder,
  }) {
    assert(<HttpMethodEnum>[HttpMethodEnum.get, HttpMethodEnum.post, HttpMethodEnum.put, HttpMethodEnum.patch].contains(method));

    final Http http = Http._internal(
      method: method,
      api: api,
      route: route,
      body: body,
      queryBuilder: queryBuilder,
    );

    return _run(http, (Http http) async {
      final StreamedResponse response = await _open(http);
      await response.stream.transform(transformer).forEach(listener);
      if (Env.flag("LOGGER_VERBOSE")) {
        Logger().t("Success to listen stream $method ${http.uri}");
      }
    });
  }

  /// POST multipart/form-data: [files] as file parts, [fields] as text fields.
  /// Returns the JSON response as [HttpOutput], like [input].
  ///
  /// Same auth and error contract as every other method (Bearer header, one
  /// token refresh + retry on 401 that re-sends fresh copies of the parts,
  /// [ApiException] for HTTP 400+).
  static Future<HttpOutput> multipart({
    required HttpApiEnum api,
    required String route,
    required List<HttpFile> files,
    Map<String, String> fields = const <String, String>{},
  }) {
    final Http http = Http._internal(
      method: HttpMethodEnum.post,
      api: api,
      route: route,
      files: files,
      fields: fields,
    );

    return _run(http, (Http http) async {
      return HttpOutput.fromJson(http.parse(await _send(http)) as Map<String, dynamic>);
    });
  }

  /// GET the raw response body. Use for binary downloads (file exports,
  /// images). Same auth and error contract as every other method.
  static Future<Uint8List> rawBytes({
    required HttpApiEnum api,
    required String route,
    ApiFilterBuilder? queryBuilder,
  }) {
    final Http http = Http._internal(
      method: HttpMethodEnum.get,
      api: api,
      route: route,
      queryBuilder: queryBuilder,
    );

    return _run(http, (Http http) async => (await _send(http)).bodyBytes);
  }
}
