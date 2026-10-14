// load_state.dart
//
// Generic async lifecycle sealed class. Replaces ad-hoc
// bool isLoading / bool _hasLoadError / T? data triples.

/// Represents the lifecycle of an async data fetch.
sealed class LoadState<T> {
  const LoadState();

  /// True when in [Loading] state.
  bool get isLoading => this is Loading<T>;

  /// True when in [LoadError] state.
  bool get hasError => this is LoadError<T>;

  /// Returns data if in [Loaded] state, null otherwise.
  T? get dataOrNull => switch (this) {
    Loaded<T>(:final data) => data,
    _ => null,
  };
}

/// No fetch attempted yet.
final class Idle<T> extends LoadState<T> {
  const Idle();
}

/// Fetch in progress.
final class Loading<T> extends LoadState<T> {
  const Loading();
}

/// Fetch succeeded.
final class Loaded<T> extends LoadState<T> {
  final T data;
  const Loaded(this.data);
}

/// Fetch failed.
final class LoadError<T> extends LoadState<T> {
  final String? message;
  const LoadError([this.message]);
}
