// api_filter.dart
//
// Represents a single query-string parameter. A filter holds either a single
// scalar value or a list of values for the same key (repeating parameters).
// Used through ApiFilterBuilder — services rarely instantiate it directly.

/// A single query-string parameter with either a scalar or a list value.
///
/// Exactly one of [value] or [valueList] must be non-null — enforced by the
/// constructor assertion. The [toMap] method produces a fragment suitable for
/// passing to [Uri.http]/[Uri.https]. [toString] produces a string fragment
/// for logging.
final class ApiFilter {
  /// The parameter key (e.g. "lang", "status").
  final String key;

  /// A single scalar value, mutually exclusive with [valueList].
  final String? value;

  /// A list of values for repeated parameters (`tag=a&tag=b`), mutually
  /// exclusive with [value].
  final List<String>? valueList;

  ApiFilter({
    required this.key,
    this.value,
    this.valueList,
  }): assert((value != null) != (valueList != null));

  /// Returns the parameter as a map entry suitable for [Uri] query parameters.
  Map<String, dynamic> toMap() {
    if (value != null) {
      return <String, dynamic>{key: value};
    }

    // Pass the list directly so Uri.http produces `key=a&key=b` for each element.
    return <String, dynamic>{key: valueList};
  }

  @override
  String toString() {
    if (value != null) {
      return "$key=$value";
    }

    return valueList!.map((String e) => "$key=$e").join("&");
  }
}
