// enums.dart
//
// HTTP-layer enumerations shared across the entire API layer.
//
// HttpMethodEnum maps the standard HTTP verbs to their string representations
// so they can be passed directly to the http package and logged.
// HttpApiEnum identifies which backend configuration to use; the key is used
// as a prefix when reading environment variables (e.g. "API" → API_API_URL).

/// Standard HTTP method verbs.
///
/// The [key] matches the wire format expected by the http package and is
/// returned by [toString], so the enum can be interpolated directly in log
/// messages and request builders.
enum HttpMethodEnum {
  get(key: "GET"),
  head(key: "HEAD"),
  post(key: "POST"),
  put(key: "PUT"),
  patch(key: "PATCH"),
  delete(key: "DELETE");

  final String key;

  const HttpMethodEnum({
    required this.key,
  });

  @override
  String toString() {
    return key;
  }
}

/// Identifies a registered backend API.
///
/// The [key] is used as the prefix for `.env.local` variable lookup:
/// `${key}_API_SCHEME` and `${key}_API_URL`.
/// Add new entries here when a second backend is introduced.
enum HttpApiEnum {
  api(key: "API");

  final String key;

  const HttpApiEnum({
    required this.key,
  });

  @override
  String toString() {
    return key;
  }
}
