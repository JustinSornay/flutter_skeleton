// polygon_wizard_sheet_rules_test.dart
//
// Unit tests for PolygonWizardRules (lib/widgets/custom/PolygonWizardSheet/
// controllers/wizard_rules.dart): valid step mixes, the first step shown,
// step completeness, the submitted name, the centroid and the crossing-edge
// check.

import "package:flutter_skeleton/widgets/custom/PolygonWizardSheet/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:latlong2/latlong.dart";

const PolygonWizardStepKind _kName = PolygonWizardStepKind.name;
const PolygonWizardStepKind _kPolygon = PolygonWizardStepKind.polygon;
const PolygonWizardStepKind _kSelection = PolygonWizardStepKind.selection;
const PolygonWizardStepKind _kSummary = PolygonWizardStepKind.summary;

List<PolygonWizardStep> _steps(List<PolygonWizardStepKind> kinds) {
  return <PolygonWizardStep>[
    for (final PolygonWizardStepKind kind in kinds)
      PolygonWizardStep(kind: kind, title: kind.name, hint: ""),
  ];
}

String? _problem(List<PolygonWizardStepKind> kinds, {bool hasPicker = true}) {
  return PolygonWizardRules.stepsProblem(_steps(kinds), hasPicker: hasPicker);
}

void main() {
  _stepsProblemTests();
  _initialStepTests();
  _isCompleteTests();
  _resolveNameTests();
  _centroidTests();
  _crossingTests();
}

void _stepsProblemTests() {
  group("stepsProblem", () {
    test(
      "accepts one polygon step with optional name, selection, summaries",
      () {
        expect(_problem(<PolygonWizardStepKind>[_kPolygon]), isNull);
        expect(
          _problem(<PolygonWizardStepKind>[
            _kName,
            _kPolygon,
            _kSelection,
            _kSummary,
          ]),
          isNull,
        );
        expect(
          _problem(<PolygonWizardStepKind>[_kSummary, _kPolygon, _kSummary]),
          isNull,
        );
      },
    );

    test("needs exactly one polygon step", () {
      expect(_problem(<PolygonWizardStepKind>[]), isNotNull);
      expect(_problem(<PolygonWizardStepKind>[_kName, _kSummary]), isNotNull);
      expect(
        _problem(<PolygonWizardStepKind>[_kPolygon, _kPolygon]),
        isNotNull,
      );
    });

    test("allows one name and one selection step", () {
      expect(
        _problem(<PolygonWizardStepKind>[_kName, _kName, _kPolygon]),
        isNotNull,
      );
      expect(
        _problem(<PolygonWizardStepKind>[_kSelection, _kPolygon, _kSelection]),
        isNotNull,
      );
    });

    test("a selection step needs a picker", () {
      expect(
        _problem(<PolygonWizardStepKind>[
          _kSelection,
          _kPolygon,
        ], hasPicker: false),
        isNotNull,
      );
      expect(
        _problem(<PolygonWizardStepKind>[_kName, _kPolygon], hasPicker: false),
        isNull,
      );
    });
  });
}

void _initialStepTests() {
  group("initialStep", () {
    final List<PolygonWizardStep> leadingName = _steps(<PolygonWizardStepKind>[
      _kName,
      _kPolygon,
    ]);

    test("skips a leading name step pre-filled with a non-blank name", () {
      expect(PolygonWizardRules.initialStep(leadingName, "North"), 1);
    });

    test("starts at 0 for a null or blank name", () {
      expect(PolygonWizardRules.initialStep(leadingName, null), 0);
      expect(PolygonWizardRules.initialStep(leadingName, "   "), 0);
    });

    test("starts at 0 when the name step is not first or is alone", () {
      expect(
        PolygonWizardRules.initialStep(
          _steps(<PolygonWizardStepKind>[_kPolygon, _kName]),
          "North",
        ),
        0,
      );
      expect(
        PolygonWizardRules.initialStep(
          _steps(<PolygonWizardStepKind>[_kName]),
          "North",
        ),
        0,
      );
    });
  });
}

void _isCompleteTests() {
  group("isComplete", () {
    bool complete(
      PolygonWizardStepKind kind, {
      String name = "",
      bool shapeValid = false,
      int selectionCount = 0,
    }) {
      return PolygonWizardRules.isComplete(
        kind,
        name: name,
        shapeValid: shapeValid,
        selectionCount: selectionCount,
      );
    }

    test("name needs non-blank text", () {
      expect(complete(_kName), isFalse);
      expect(complete(_kName, name: "  "), isFalse);
      expect(complete(_kName, name: " a "), isTrue);
    });

    test("polygon needs a valid shape", () {
      expect(complete(_kPolygon), isFalse);
      expect(complete(_kPolygon, shapeValid: true), isTrue);
    });

    test("selection needs one selection", () {
      expect(complete(_kSelection), isFalse);
      expect(complete(_kSelection, selectionCount: 1), isTrue);
    });

    test("summary is always complete", () {
      expect(complete(_kSummary), isTrue);
    });
  });
}

void _resolveNameTests() {
  group("resolveName", () {
    const List<PolygonFormSelection> picked = <PolygonFormSelection>[
      PolygonFormSelection(id: "a", title: "First"),
      PolygonFormSelection(id: "b", title: "Second"),
    ];

    test("prefers the trimmed typed name", () {
      expect(PolygonWizardRules.resolveName("  North ", picked, "F"), "North");
    });

    test("then the first selection's title, then the fallback", () {
      expect(PolygonWizardRules.resolveName("  ", picked, "F"), "First");
      expect(
        PolygonWizardRules.resolveName("", const <PolygonFormSelection>[], "F"),
        "F",
      );
    });
  });
}

void _centroidTests() {
  group("centroid", () {
    test("is the mean of the points", () {
      final LatLng centre = PolygonWizardRules.centroid(const <LatLng>[
        LatLng(0, 0),
        LatLng(0, 2),
        LatLng(2, 2),
        LatLng(2, 0),
      ], const LatLng(9, 9));
      expect(centre, const LatLng(1, 1));
    });

    test("falls back without points", () {
      expect(
        PolygonWizardRules.centroid(const <LatLng>[], const LatLng(9, 9)),
        const LatLng(9, 9),
      );
    });
  });
}

void _crossingTests() {
  group("hasCrossingEdges", () {
    test("simple shapes do not cross", () {
      expect(PolygonWizardRules.hasCrossingEdges(const <LatLng>[]), isFalse);
      expect(
        PolygonWizardRules.hasCrossingEdges(const <LatLng>[
          LatLng(0, 0),
          LatLng(0, 1),
          LatLng(1, 0),
        ]),
        isFalse,
      );
      expect(
        PolygonWizardRules.hasCrossingEdges(const <LatLng>[
          LatLng(0, 0),
          LatLng(0, 2),
          LatLng(2, 2),
          LatLng(1, 1),
          LatLng(2, 0),
        ]),
        isFalse,
      );
    });

    test("a bow-tie crosses", () {
      expect(
        PolygonWizardRules.hasCrossingEdges(const <LatLng>[
          LatLng(0, 0),
          LatLng(1, 1),
          LatLng(0, 1),
          LatLng(1, 0),
        ]),
        isTrue,
      );
    });

    test("a crossing on the closing edge counts", () {
      expect(
        PolygonWizardRules.hasCrossingEdges(const <LatLng>[
          LatLng(0, 0),
          LatLng(0, 2),
          LatLng(2, 2),
          // The closing edge back to (0, 0) cuts the edge (0, 2)–(2, 2).
          LatLng(1, 3),
        ]),
        isTrue,
      );
    });

    test("a vertex on a non-adjacent edge touches", () {
      expect(
        PolygonWizardRules.hasCrossingEdges(const <LatLng>[
          LatLng(0, 0),
          LatLng(0, 2),
          LatLng(2, 2),
          LatLng(0, 1),
        ]),
        isTrue,
      );
    });
  });
}
