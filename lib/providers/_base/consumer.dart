// consumer.dart
//
// Provides thin helpers that wrap provider package widgets so call-sites
// don't need to repeat the verbose builder signatures throughout the tree.
//
// Usage:
//   renderConsumer<MyProvider>((p) => MyWidget(data: p.data))
//   renderSelector<MyProvider, String>((p) => p.userName, (name) => Text(name))

import "package:flutter/material.dart";
import "package:provider/provider.dart";

/// Builds a [Consumer] for provider type [T], exposing only the provider
/// instance to [builder] and discarding the unused child parameter.
///
/// This keeps widget code concise — callers supply a single-argument lambda
/// instead of the full `(context, provider, child)` signature.
Consumer<T> renderConsumer<T extends ChangeNotifier>(Widget Function(T) builder) {
  return Consumer<T>(builder: (context, provider, _) => builder(provider));
}

/// Builds a [Selector] for provider type [T] that rebuilds only when the
/// projected value of type [S] changes (by `==`).
///
/// Use when a widget cares about only a subset of a provider's state. Prefer
/// this over `renderConsumer` when the provider has frequent `notifyListeners`
/// calls but the widget only depends on one or two fields.
///
/// If [S] is a compound value (tuple, record), the projection is compared by
/// value equality — Dart records implement `==` structurally.
Selector<T, S> renderSelector<T extends ChangeNotifier, S>(
  S Function(T) selector,
  Widget Function(S value) builder,
) {
  return Selector<T, S>(
    selector: (_, provider) => selector(provider),
    builder: (context, value, _) => builder(value),
  );
}
