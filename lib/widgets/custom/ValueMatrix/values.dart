// values.dart
//
// Value classes of ValueMatrix: ValueMatrixRow (one row id + label) and
// ValueMatrixColumn (one column id + header label + optional caption). No UI
// here.

part of "index.dart";

/// One row of a [ValueMatrix].
@immutable
final class ValueMatrixRow {
  /// Key of the row in the maps returned by [ValueMatrix.loadColumn].
  final String id;

  /// Row-label cell and CSV text, already localised.
  final String label;

  const ValueMatrixRow({required this.id, required this.label});
}

/// One column of a [ValueMatrix].
@immutable
final class ValueMatrixColumn {
  /// Id passed to [ValueMatrix.loadColumn] and used as the sort key.
  final String id;

  /// Main header text, already localised.
  final String label;

  /// Optional second header line (a unit, a delta, a period…); hidden when
  /// null or empty.
  final String? caption;

  const ValueMatrixColumn({required this.id, required this.label, this.caption});

  /// [label] followed by [caption] when present: the CSV header and the
  /// header semantics label.
  String get fullLabel {
    final String? extra = caption;
    return extra == null || extra.isEmpty ? label : "$label $extra";
  }
}
