// wizard_rules.dart
//
// PolygonWizardRules — the pure rules of PolygonWizardSheet: which step mix
// is valid, where the wizard starts, when a step is complete, which name is
// submitted and the centroid handed to loadSelection. The crossing-edge check
// is not here: view_model.dart calls utils/geo/polygon_shape.dart. No
// widgets, so it is unit-tested on its own.

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
}
