// env.dart
//
// Crash-free accessors over flutter_dotenv. The raw dotenv getters throw when
// the file is not loaded yet (unit tests, cold start) or when a value is empty;
// these helpers return null / false / the fallback instead so logging flags and
// tuning values never take the app down.

import "package:flutter_dotenv/flutter_dotenv.dart";

/// Typed read-only access to the variables loaded from `.env.local`.
abstract final class Env {
  /// Returns the raw value for [name], or null when missing or not loaded.
  static String? get(String name) {
    if (!dotenv.isInitialized) return null;
    final String? value = dotenv.maybeGet(name);
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Returns true only when [name] is set to `true` or `1`.
  static bool flag(String name) {
    return <String>["true", "1"].contains(get(name)?.toLowerCase());
  }

  /// Returns [name] parsed as an int, or [fallback] when missing or invalid.
  static int intOr(String name, int fallback) {
    return int.tryParse(get(name) ?? "") ?? fallback;
  }
}
