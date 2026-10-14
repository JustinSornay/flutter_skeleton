// api_filter_builder.dart
//
// Fluent builder that accumulates query-string parameters and serializes them
// into the map format expected by Http.output / Http.listOutput. Services
// construct one builder per request, add parameters with addParam(), then
// pass the builder to the Http method.

import "package:flutter_skeleton/api/services/_base/apiFilterBuilder/api_filter.dart";

/// Accumulates query-string parameters for an API request.
///
/// Usage pattern in services:
/// ```dart
/// final ApiFilterBuilder filter = ApiFilterBuilder()
///   ..addParam("page", page)
///   ..addParam("lang", lang);
/// await Http.listOutput(api: HttpApiEnum.api, route: "items", queryBuilder: filter);
/// ```
///
/// [addParam] silently ignores null values so callers can pass optional
/// parameters without null-checking them first.
final class ApiFilterBuilder {
  final List<ApiFilter> _filterList = <ApiFilter>[];

  /// Adds a pre-constructed [ApiFilter] (scalar or list).
  void add(ApiFilter filter) {
    _filterList.add(filter);
  }

  /// Adds a scalar query parameter, converting [value] to a string.
  /// No-ops when [value] is null, allowing optional parameters to be passed
  /// unconditionally.
  void addParam(String key, Object? value) {
    if (value == null) return;
    _filterList.add(ApiFilter(key: key, value: value.toString()));
  }

  /// Returns all accumulated parameters as a map for use with [Uri.http] /
  /// [Uri.https].
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{};
    for (final ApiFilter filter in _filterList) {
      map.addAll(filter.toMap());
    }
    return map;
  }

  /// Returns the query string with a leading `?`, or an empty string when
  /// no parameters have been added.
  @override
  String toString() {
    if (_filterList.isEmpty) return "";
    return "?${_filterList.map((ApiFilter e) => e.toString()).join("&")}";
  }
}
