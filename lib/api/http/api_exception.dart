// api_exception.dart
//
// Typed exception thrown by the Http utility whenever the backend returns an
// HTTP 400+ response. Services catch and rethrow this so callers can
// distinguish API-level errors from network failures.

/// Represents a non-2xx response from the backend API.
///
/// [status] carries the raw HTTP status code (e.g. 404, 422, 500).
/// [detail] is the human-readable message extracted from the response body
/// (`detail`, `title` or `error` field), used for logging and UI error display.
final class ApiException implements Exception {
  final int status;
  final String detail;

  const ApiException({
    required this.status,
    required this.detail,
  });

  @override
  String toString() => "ApiException($status): $detail";
}
