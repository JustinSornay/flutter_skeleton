// wizard_rules.dart
//
// PolygonWizardRules — the pure rules of PolygonWizardSheet: which step mix
// is valid, where the wizard starts, when a step is complete, which name is
// submitted, the centroid handed to loadSelection and whether two polygon
// edges cross or touch. No widgets, so it is unit-tested on its own.

part of "../index.dart";

/// Pure decisions of [PolygonWizardSheet], kept out of the state.
@visibleForTesting
abstract final class PolygonWizardRules {
  /// Why [steps] cannot drive a wizard, or null when they can: one polygon
  /// step, at most one name and one selection step, and a picker
  /// ([hasPicker]) when there is a selection step.
  static String? stepsProblem(
    List<PolygonWizardStep> steps, {
    required bool hasPicker,
  }) {
    int count(PolygonWizardStepKind kind) =>
        steps.where((PolygonWizardStep step) => step.kind == kind).length;
    if (count(PolygonWizardStepKind.polygon) != 1) {
      return "PolygonWizardSheet.steps needs exactly one polygon step.";
    }
    if (count(PolygonWizardStepKind.name) > 1 ||
        count(PolygonWizardStepKind.selection) > 1) {
      return "PolygonWizardSheet.steps allows one name and one selection step.";
    }
    if (count(PolygonWizardStepKind.selection) == 1 && !hasPicker) {
      return "A selection step needs pickerBuilder and loadSelection.";
    }
    return null;
  }

  /// Index of the first step shown: 1 when the first step is a name step
  /// pre-filled with a non-blank [initialName], else 0.
  static int initialStep(List<PolygonWizardStep> steps, String? initialName) {
    final bool prefilled = (initialName ?? "").trim().isNotEmpty;
    final bool leadingName =
        steps.length > 1 && steps.first.kind == PolygonWizardStepKind.name;
    return prefilled && leadingName ? 1 : 0;
  }

  /// Whether a step of [kind] is complete.
  static bool isComplete(
    PolygonWizardStepKind kind, {
    required String name,
    required bool shapeValid,
    required int selectionCount,
  }) {
    return switch (kind) {
      PolygonWizardStepKind.name => name.trim().isNotEmpty,
      PolygonWizardStepKind.polygon => shapeValid,
      PolygonWizardStepKind.selection => selectionCount > 0,
      PolygonWizardStepKind.summary => true,
    };
  }

  /// Submitted name: the trimmed [typed] text, else the first selection's
  /// title, else [fallback].
  static String resolveName(
    String typed,
    List<PolygonFormSelection> selections,
    String fallback,
  ) {
    final String trimmed = typed.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return selections.isEmpty ? fallback : selections.first.title;
  }

  /// Mean of [points], or [fallback] when there is none.
  static LatLng centroid(List<LatLng> points, LatLng fallback) {
    if (points.isEmpty) return fallback;
    double latitude = 0;
    double longitude = 0;
    for (final LatLng point in points) {
      latitude += point.latitude;
      longitude += point.longitude;
    }
    return LatLng(latitude / points.length, longitude / points.length);
  }

  /// Whether two non-adjacent edges of the closed polygon through [points]
  /// (last vertex joined back to the first) cross or touch, in planar
  /// coordinates (longitude as x). Fewer than 4 points return false.
  static bool hasCrossingEdges(List<LatLng> points) {
    final int count = points.length;
    for (int i = 0; i < count; i++) {
      // Edge i + 1 shares a vertex with edge i; so does the closing edge
      // (count - 1) with edge 0.
      for (int j = i + 2; j < count; j++) {
        if (i == 0 && j == count - 1) continue;
        if (_segmentsTouch(
          points[i],
          points[i + 1],
          points[j],
          points[(j + 1) % count],
        )) {
          return true;
        }
      }
    }
    return false;
  }

  /// Whether the segments [a]–[b] and [c]–[d] cross or share a point.
  static bool _segmentsTouch(LatLng a, LatLng b, LatLng c, LatLng d) {
    final bool crossing =
        _side(c, d, a).sign * _side(c, d, b).sign < 0 &&
        _side(a, b, c).sign * _side(a, b, d).sign < 0;
    return crossing ||
        _liesOn(a, c, d) ||
        _liesOn(b, c, d) ||
        _liesOn(c, a, b) ||
        _liesOn(d, a, b);
  }

  /// Cross product of [b] − [a] and [p] − [a]: positive when [p] is left of
  /// the line [a] → [b], negative when right, zero when on it.
  static double _side(LatLng a, LatLng b, LatLng p) {
    return (b.longitude - a.longitude) * (p.latitude - a.latitude) -
        (b.latitude - a.latitude) * (p.longitude - a.longitude);
  }

  /// Whether [p] lies on the segment [a]–[b].
  static bool _liesOn(LatLng p, LatLng a, LatLng b) {
    return _side(a, b, p) == 0 &&
        p.longitude >= math.min(a.longitude, b.longitude) &&
        p.longitude <= math.max(a.longitude, b.longitude) &&
        p.latitude >= math.min(a.latitude, b.latitude) &&
        p.latitude <= math.max(a.latitude, b.latitude);
  }
}
