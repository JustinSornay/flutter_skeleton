// enum_extensions.dart
//
// Extension methods on Iterable<Enum> for concise enum lookups, instead of
// firstWhere() calls scattered across the codebase.

/// Lookup helpers on enum value lists (`MyEnum.values.by(...)`).
extension EnumIterableExtensions<E extends Enum> on Iterable<E> {
  /// The first value that satisfies [test].
  ///
  /// When none does, returns [orElse]'s result, or throws a [StateError] if
  /// [orElse] is omitted. Example: `Status.values.by((Status s) => s.name == raw,
  /// orElse: () => Status.unknown)`.
  E by(bool Function(E value) test, {E Function()? orElse}) {
    return firstWhere(test, orElse: orElse);
  }
}
