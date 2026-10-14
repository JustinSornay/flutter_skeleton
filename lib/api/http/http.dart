// http.dart
//
// Central HTTP utility for all backend communication. Services never touch
// the http package directly — they call one of the five static factory methods
// (output, listOutput, input, request, listen) which handle request
// construction, auth headers, response parsing, error mapping, and logging.
//
// Configuration is read from .env.local at runtime using the HttpApiEnum key
// as a prefix (e.g. API_API_URL, API_API_SCHEME).
//
// Relationships:
//   - Used by every class in api/services/
//   - Produces HttpOutput instances consumed by DTO .fromOutput() constructors
//   - Throws ApiException for any HTTP 400+ response

import "dart:async";
import "dart:convert";

import "package:flutter/foundation.dart";
import "package:flutter_skeleton/api/dtos/_base/input/abstract_input.dart";
import "package:flutter_skeleton/api/http/api_exception.dart";
import "package:flutter_skeleton/api/http/enums.dart";
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
  /// public API routes work without a token.
  Map<String, String> get _headers {
    final Map<String, String> headers = <String, String>{"Content-Type": "application/json"};

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
  }):
    // Body is required for write methods; routes must not start with a slash.
    assert(body != null || <HttpMethodEnum>[HttpMethodEnum.get, HttpMethodEnum.delete, HttpMethodEnum.head].contains(method)),
    assert(!route.startsWith("/"));

  /// Decodes the response body as UTF-8 JSON.
  dynamic parse(Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Request _buildRequest() {
    final Request request = Request(method.key, uri)..headers.addAll(_headers);
    if (body != null) {
      request.body = jsonEncode(body!.toJson());
    }
    return request;
  }

  /// Executes the request and returns the raw [Response].
  /// Logs errors when LOGGER_ERROR is enabled and verbose success when
  /// LOGGER_VERBOSE is enabled.
  Future<Response> call() async {
    final Response response;

    try {
      response = await Response.fromStream(await _client.send(_buildRequest()));
    } catch (error) {
      if (Env.flag("LOGGER_ERROR")) {
        Logger().e("Fail to call $method $uri");
      }
      rethrow;
    }

    if (response.statusCode < 400 && Env.flag("LOGGER_VERBOSE")) {
      Logger().t("Success to call $method $uri");
    }

    return response;
  }

  /// Opens a streaming request and returns the [StreamedResponse].
  /// Used by [Http.listen] for server-sent events or chunked responses.
  Future<StreamedResponse> stream() async {
    try {
      return await _client.send(_buildRequest());
    } catch (error) {
      if (Env.flag("LOGGER_ERROR")) {
        Logger().e("Fail to open stream $method $uri");
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

  /// Sends [http], retries once after a token refresh on 401, and throws
  /// [ApiException] for any HTTP 400+ response.
  static Future<Response> _send(Http http, {bool isRetry = false}) async {
    final Response response = await http.call();

    if (response.statusCode == 401 && !isRetry && _tokenRefreshCallback != null) {
      final String? freshToken = await _tokenRefreshCallback!();
      if (freshToken != null) {
        return _send(http, isRetry: true);
      }
    }
    // 401 after a successful refresh — the session is irrecoverably expired.
    if (response.statusCode == 401 && isRetry) {
      _onUnauthorizedCallback?.call();
    }

    if (response.statusCode >= 400) {
      String detail = statusCodeToString(response.statusCode);
      try {
        final Map<String, dynamic> error = http.parse(response) as Map<String, dynamic>;
        detail = error["detail"] as String? ?? error["title"] as String? ?? error["error"] as String? ?? detail;
      } catch (_) {
        // Empty or non-JSON error body — keep the HTTP status text.
      }
      if (Env.flag("LOGGER_ERROR")) {
        Logger().e("${http.method} ${http.uri} → ${response.statusCode}: $detail");
      }
      throw ApiException(
        status: response.statusCode,
        detail: detail,
      );
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

  /// HEAD or DELETE request that returns no body.
  ///
  /// Use for side-effect-only operations (e.g. deleting an entry).
  /// [method] must be head or delete — enforced by assertion.
  /// Throws [ApiException] for HTTP 400+ responses like every other method.
  static Future<void> request({
    required HttpMethodEnum method,
    required HttpApiEnum api,
    required String route,
  }) {
    assert(<HttpMethodEnum>[HttpMethodEnum.head, HttpMethodEnum.delete].contains(method));

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
  /// error (cancelOnError is always true). Throws [ApiException] when the
  /// server answers with HTTP 400+ before streaming.
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
      final StreamedResponse response = await http.stream();
      if (response.statusCode >= 400) {
        await response.stream.drain<void>();
        throw ApiException(
          status: response.statusCode,
          detail: statusCodeToString(response.statusCode),
        );
      }

      await response.stream.transform(transformer).forEach(listener);
      if (Env.flag("LOGGER_VERBOSE")) {
        Logger().t("Success to listen stream $method ${http.uri}");
      }
    });
  }
}
