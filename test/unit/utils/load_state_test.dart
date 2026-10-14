// load_state_test.dart
//
// Unit tests for the LoadState sealed class.
// Covers: Idle, Loading, Loaded, LoadError — isLoading, hasError, dataOrNull,
//         message, and switch exhaustiveness.

import "package:flutter_test/flutter_test.dart";
import "package:flutter_skeleton/utils/load_state.dart";

/// Helper that exhaustively switches over all LoadState variants.
/// Presence of this function confirms the sealed class is exhaustive at compile time.
String _describe(LoadState<Object> state) => switch (state) {
  Idle() => "idle",
  Loading() => "loading",
  Loaded(:final data) => "loaded($data)",
  LoadError(:final message) => "error($message)",
};

void main() {
  // ---------------------------------------------------------------------------
  // Idle
  // ---------------------------------------------------------------------------
  group("Idle", () {
    test("isLoading is false", () {
      expect(const Idle<int>().isLoading, isFalse);
    });

    test("hasError is false", () {
      expect(const Idle<int>().hasError, isFalse);
    });

    test("dataOrNull is null", () {
      expect(const Idle<int>().dataOrNull, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------
  group("Loading", () {
    test("isLoading is true", () {
      expect(const Loading<int>().isLoading, isTrue);
    });

    test("hasError is false", () {
      expect(const Loading<int>().hasError, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Loaded
  // ---------------------------------------------------------------------------
  group("Loaded", () {
    test("isLoading is false", () {
      expect(const Loaded<int>(42).isLoading, isFalse);
    });

    test("dataOrNull returns the wrapped int value", () {
      expect(const Loaded<int>(42).dataOrNull, 42);
    });

    test("dataOrNull returns the wrapped string value", () {
      expect(const Loaded<String>("hello").dataOrNull, "hello");
    });
  });

  // ---------------------------------------------------------------------------
  // LoadError
  // ---------------------------------------------------------------------------
  group("LoadError", () {
    test("hasError is true", () {
      expect(const LoadError<int>().hasError, isTrue);
    });

    test("isLoading is false", () {
      expect(const LoadError<int>().isLoading, isFalse);
    });

    test("message is set when provided", () {
      expect(const LoadError<int>("oops").message, "oops");
    });

    test("message is null by default", () {
      expect(const LoadError<int>().message, isNull);
    });

    test("dataOrNull is null", () {
      expect(const LoadError<int>().dataOrNull, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Switch exhaustiveness (compile-time check via _describe helper)
  // ---------------------------------------------------------------------------
  group("Switch exhaustiveness", () {
    test("all variants covered without default", () {
      expect(_describe(const Idle<int>()), "idle");
      expect(_describe(const Loading<int>()), "loading");
      expect(_describe(const Loaded<int>(42)), "loaded(42)");
      expect(_describe(const LoadError<int>("err")), "error(err)");
    });
  });
}
