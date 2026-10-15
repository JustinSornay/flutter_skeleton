// strip_analysis.dart
//
// Pure per-period analysis of StatusStrip: the category of a value, the
// categories present in the shown rows (legend), and the divergence of the
// alternative rows at each period (agreement markers). No widgets.

part of "../index.dart";

/// How much the alternative rows differ at one period.
enum _Divergence {
  /// Fewer than two rows, or every row holds the same value: no marker.
  none,

  /// Some rows agree, others differ: corner dot.
  partial,

  /// Every row holds a different value: dashed outline.
  full,
}

/// Divergence of [rows] at [index]. Values are compared with `==`.
_Divergence _divergenceAt<T>(List<List<T>> rows, int index) {
  if (rows.length < 2) return _Divergence.none;
  final List<T> distinct = <T>[];
  for (final List<T> row in rows) {
    final T value = row[index];
    if (!distinct.contains(value)) distinct.add(value);
  }
  if (distinct.length == 1) return _Divergence.none;
  return distinct.length == rows.length ? _Divergence.full : _Divergence.partial;
}

/// Divergence of [rows] at each of the [count] periods; all
/// [_Divergence.none] when [rows] is null.
List<_Divergence> _divergencesOf<T>(List<List<T>>? rows, int count) {
  return List<_Divergence>.generate(
    count,
    (int index) => rows == null ? _Divergence.none : _divergenceAt(rows, index),
    growable: false,
  );
}

/// First category of [categories] whose value equals [value], or null.
StatusStripCategory<T>? _categoryOf<T>(List<StatusStripCategory<T>> categories, T value) {
  for (final StatusStripCategory<T> category in categories) {
    if (category.value == value) return category;
  }
  return null;
}

/// Categories whose value appears in one of [rows], in [categories] order.
List<StatusStripCategory<T>> _presentCategories<T>(
  List<StatusStripCategory<T>> categories,
  List<List<T>> rows,
) {
  return <StatusStripCategory<T>>[
    for (final StatusStripCategory<T> category in categories)
      if (rows.any((List<T> row) => row.contains(category.value))) category,
  ];
}
