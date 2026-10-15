// polygon_wizard_sheet_test.dart
//
// Widget tests for PolygonWizardSheet (lib/widgets/custom/PolygonWizardSheet/):
// the step indicator and its semantics, the name step (Next gating,
// initialName skip), the polygon step (drawing through the composed
// MapPolygonEditor, undo / reset, the PillBadge counter, crossing edges,
// camera fit on return, short sheets, a late map tap after Next),
// suggestion rows (import / clear, un-marked when the polygon empties,
// async load, failure, host rebuilds), the selection step in single mode
// (Loader, EditableValueRow card, centroid, failure cleared by a step
// change) and multi mode (chips, picker State kept, duplicates and
// in-flight picks, removal), the summary card, the submit lifecycle
// (result payload, name fallbacks, double-submit guard, inline error, no
// spinner after success), the lock while submitting (map, tools, chips,
// name field, a racing chip removal), hosting in a modal bottom sheet
// (close on success, vertex drags never drag the sheet, no close from a
// route already closing), reduced motion, tap targets, step-list asserts
// and the dark theme. Tiles come from an in-memory TileProvider, so no
// network is used.

import "dart:async";
import "dart:typed_data";

import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/EditableValueRow/index.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";
import "package:flutter_skeleton/widgets/custom/MapPolygonEditor/index.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";
import "package:flutter_skeleton/widgets/custom/PolygonWizardSheet/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:latlong2/latlong.dart";

import "../../helpers/widget_test_helpers.dart";

const String _kBack = "custom.polygon_wizard_sheet.back";
const String _kNext = "custom.polygon_wizard_sheet.next";
const String _kSubmit = "custom.polygon_wizard_sheet.submit";
const String _kSubmitError = "custom.polygon_wizard_sheet.submit_error";
const String _kUndo = "custom.polygon_wizard_sheet.undo";
const String _kReset = "custom.polygon_wizard_sheet.reset";
const String _kPointsPlaced = "custom.polygon_wizard_sheet.points_placed";
const String _kCrossing = "custom.polygon_wizard_sheet.crossing_edges";
const String _kNameLabel = "custom.polygon_wizard_sheet.name_label";
const String _kDefaultName = "custom.polygon_wizard_sheet.default_name";
const String _kSelectionLabel = "custom.polygon_wizard_sheet.selection_label";
const String _kSelectedCount = "custom.polygon_wizard_sheet.selected_count";
const String _kSelectionError = "custom.polygon_wizard_sheet.selection_error";
const String _kRemoveItem = "custom.polygon_wizard_sheet.remove_item";
const String _kPointsLabel = "custom.polygon_wizard_sheet.points_label";
const String _kPointsCount = "custom.polygon_wizard_sheet.points_count";
const String _kStepSemantics = "custom.polygon_wizard_sheet.step_semantics";
const String _kLoading = "custom.polygon_wizard_sheet.loading";
const String _kVertex = "custom.map_polygon_editor.vertex";

const PolygonWizardStepKind _kName = PolygonWizardStepKind.name;
const PolygonWizardStepKind _kPolygon = PolygonWizardStepKind.polygon;
const PolygonWizardStepKind _kSelection = PolygonWizardStepKind.selection;
const PolygonWizardStepKind _kSummary = PolygonWizardStepKind.summary;

const Size _kSurface = Size(800, 1000);

/// Longer than flutter_map's 250 ms double-tap window and the 220 ms step
/// cross-fade.
const Duration _kSettle = Duration(milliseconds: 400);

/// Tap offsets from the map centre: a triangle whose vertices and edges are
/// far from each other (no snapping between taps).
const List<Offset> _kTriangle = <Offset>[
  Offset(-80, -60),
  Offset(80, -60),
  Offset(0, 80),
];

/// Tap offsets drawing a bow-tie: edges 0–1 and 2–3 cross.
const List<Offset> _kBowTie = <Offset>[
  Offset(-80, -60),
  Offset(80, 80),
  Offset(80, -60),
  Offset(-80, 80),
];

/// A bow-tie flat enough for the map of a short sheet.
const List<Offset> _kFlatBowTie = <Offset>[
  Offset(-80, -40),
  Offset(80, 40),
  Offset(80, -40),
  Offset(-80, 40),
];

/// A small square far from the default camera centre.
const List<LatLng> _kSquare = <LatLng>[
  LatLng(45, 5),
  LatLng(45, 5.01),
  LatLng(45.01, 5.01),
  LatLng(45.01, 5),
];

const PolygonSuggestion _kSquareSuggestion = PolygonSuggestion(
  id: "square",
  label: "Square",
  points: _kSquare,
);

const PolygonSuggestion _kShortSuggestion = PolygonSuggestion(
  id: "short",
  label: "Short",
  points: <LatLng>[LatLng(1, 1), LatLng(2, 2)],
);

const List<PolygonSuggestionGroup> _kRecent = <PolygonSuggestionGroup>[
  PolygonSuggestionGroup(
    title: "Recent",
    suggestions: <PolygonSuggestion>[_kSquareSuggestion, _kShortSuggestion],
  ),
];

/// Two rows of suggestions: the tallest panel above the map.
const List<PolygonSuggestionGroup> _kTwoRows = <PolygonSuggestionGroup>[
  ..._kRecent,
  PolygonSuggestionGroup(
    title: "Previous",
    suggestions: <PolygonSuggestion>[
      PolygonSuggestion(id: "other", label: "Other", points: _kSquare),
    ],
  ),
];

/// 1×1 transparent PNG.
final Uint8List _kTransparentPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// Serves every tile from memory (no network).
final class _MemoryTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(_kTransparentPng);
  }
}

TileLayer _tileLayer() {
  return TileLayer(
    urlTemplate: "https://tiles.example.test/{z}/{x}/{y}.png",
    userAgentPackageName: "com.example.test",
    tileProvider: _MemoryTileProvider(),
  );
}

List<PolygonWizardStep> _steps(List<PolygonWizardStepKind> kinds) {
  return <PolygonWizardStep>[
    for (final PolygonWizardStepKind kind in kinds)
      PolygonWizardStep(
        kind: kind,
        title: "Step ${kind.name}",
        hint: "Hint ${kind.name}",
      ),
  ];
}

PolygonFormSelection _selection(String id) {
  return PolygonFormSelection(
    id: id,
    title: "Title $id",
    subtitle: "Subtitle $id",
    subtitleItalic: true,
  );
}

/// Picker listing "Item a", "Item b" and "Item c"; reports each State it
/// creates through [onInit].
final class _Picker extends StatefulWidget {
  final ValueChanged<String> onPicked;
  final ValueChanged<State<_Picker>> onInit;

  const _Picker({required this.onPicked, required this.onInit});

  @override
  State<_Picker> createState() => _PickerState();
}

final class _PickerState extends State<_Picker> {
  @override
  void initState() {
    super.initState();
    widget.onInit(this);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        for (final String id in <String>["a", "b", "c"])
          ListTile(title: Text("Item $id"), onTap: () => widget.onPicked(id)),
      ],
    );
  }
}

/// Records what the sheet hands to its picker builder and every picker
/// State created. The picker has no key, so a picker slot that moves in the
/// tree creates a new State.
final class _PickerProbe {
  final List<State<_Picker>> states = <State<_Picker>>[];
  final List<Set<String>> selectedIds = <Set<String>>[];
  final List<List<LatLng>> polygons = <List<LatLng>>[];

  Widget build(
    BuildContext context,
    ValueChanged<String> onPicked,
    Set<String> selectedIds,
    List<LatLng> polygon,
  ) {
    this.selectedIds.add(selectedIds);
    polygons.add(polygon);
    return _Picker(onPicked: onPicked, onInit: states.add);
  }
}

/// loadSelection fake: resolves at once, holds the futures, or throws.
final class _FakeLoad {
  final List<(String, LatLng)> calls = <(String, LatLng)>[];
  final Map<String, Completer<PolygonFormSelection>> pending =
      <String, Completer<PolygonFormSelection>>{};
  bool hold = false;
  Object? error;

  Future<PolygonFormSelection> call(String id, LatLng centroid) {
    calls.add((id, centroid));
    final Object? failure = error;
    if (failure != null) return Future<PolygonFormSelection>.error(failure);
    if (!hold) return Future<PolygonFormSelection>.value(_selection(id));
    final Completer<PolygonFormSelection> completer =
        Completer<PolygonFormSelection>();
    pending[id] = completer;
    return completer.future;
  }
}

/// onSubmit fake: records the calls, optionally holds or throws.
final class _FakeSubmit {
  final List<(PolygonFormResult, List<PolygonFormSelection>)> calls =
      <(PolygonFormResult, List<PolygonFormSelection>)>[];
  Completer<void>? pending;
  Object? error;

  Future<void> call(
    PolygonFormResult result,
    List<PolygonFormSelection> selections,
  ) {
    calls.add((result, selections));
    final Object? failure = error;
    if (failure != null) return Future<void>.error(failure);
    return pending?.future ?? Future<void>.value();
  }
}

/// Rebuilds a polygon-only sheet with the rows of [rows]; its
/// loadSuggestions resolves at once with a "Previous" row.
final class _RebuiltSuggestionsHost extends StatelessWidget {
  final ValueNotifier<List<PolygonSuggestionGroup>> rows;
  final TileLayer tileLayer;

  const _RebuiltSuggestionsHost({required this.rows, required this.tileLayer});

  static Future<List<PolygonSuggestionGroup>> _load() async {
    return const <PolygonSuggestionGroup>[
      PolygonSuggestionGroup(
        title: "Previous",
        suggestions: <PolygonSuggestion>[
          PolygonSuggestion(id: "old", label: "Old", points: _kSquare),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<PolygonSuggestionGroup>>(
      valueListenable: rows,
      builder:
          (
            BuildContext context,
            List<PolygonSuggestionGroup> groups,
            Widget? child,
          ) => PolygonWizardSheet(
            steps: _steps(<PolygonWizardStepKind>[_kPolygon]),
            tileLayer: tileLayer,
            onSubmit: _FakeSubmit().call,
            suggestions: groups,
            loadSuggestions: _load,
          ),
    );
  }
}

/// One sheet configuration plus its fakes.
final class _Wizard {
  final List<PolygonWizardStepKind> kinds;
  final bool multiple;
  final String? initialName;
  final String? fallbackName;
  final String? submitLabel;
  final String? submitErrorText;
  final String? nameLabel;
  final String? selectionLabel;
  final LatLng initialCenter;
  final List<PolygonSuggestionGroup> suggestions;
  final Future<List<PolygonSuggestionGroup>> Function()? loadSuggestions;

  final _FakeLoad load = _FakeLoad();
  final _FakeSubmit submit = _FakeSubmit();
  final _PickerProbe picker = _PickerProbe();
  int submitted = 0;

  _Wizard(
    this.kinds, {
    this.multiple = false,
    this.initialName,
    this.fallbackName,
    this.submitLabel,
    this.submitErrorText,
    this.nameLabel,
    this.selectionLabel,
    this.initialCenter = const LatLng(0, 0),
    this.suggestions = _kRecent,
    this.loadSuggestions,
  });

  PolygonWizardSheet build() {
    final bool withPicker = kinds.contains(_kSelection);
    return PolygonWizardSheet(
      steps: _steps(kinds),
      tileLayer: _tileLayer(),
      onSubmit: submit.call,
      onSubmitted: () => submitted++,
      submitLabel: submitLabel,
      submitErrorText: submitErrorText,
      initialName: initialName,
      nameLabel: nameLabel,
      fallbackName: fallbackName,
      initialCenter: initialCenter,
      suggestions: suggestions,
      loadSuggestions: loadSuggestions,
      pickerBuilder: withPicker ? picker.build : null,
      loadSelection: withPicker ? load.call : null,
      allowMultipleSelections: multiple,
      selectionLabel: selectionLabel,
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Wizard wizard, {
  ThemeData? theme,
  Size surfaceSize = _kSurface,
}) async {
  await pumpApp(tester, wizard.build(), surfaceSize: surfaceSize, theme: theme);
  await tester.pump();
}

/// Pumps [wizard] with the platform asking to reduce motion.
Future<void> _pumpReducedMotion(WidgetTester tester, _Wizard wizard) async {
  await pumpApp(
    tester,
    Builder(
      builder: (BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: wizard.build(),
      ),
    ),
    surfaceSize: _kSurface,
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(_kSettle);
}

Finder get _nextButton => find.byType(FilledButton);

Finder get _backButton => find.widgetWithText(TextButton, _kBack);

bool _nextEnabled(WidgetTester tester) {
  return tester.widget<FilledButton>(_nextButton).onPressed != null;
}

Future<void> _tapNext(WidgetTester tester) async {
  await tester.tap(_nextButton);
  await _settle(tester);
}

Future<void> _tapBack(WidgetTester tester) async {
  await tester.tap(_backButton);
  await _settle(tester);
}

Future<void> _typeName(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

Future<void> _tapMap(WidgetTester tester, Offset delta) async {
  await tester.tapAt(tester.getCenter(find.byType(MapPolygonEditor)) + delta);
  await tester.pump(_kSettle);
}

Future<void> _draw(WidgetTester tester, List<Offset> offsets) async {
  for (final Offset delta in offsets) {
    await _tapMap(tester, delta);
  }
}

Future<void> _importSquare(WidgetTester tester) async {
  await tester.tap(find.text("Square"));
  await _settle(tester);
}

Future<void> _pick(WidgetTester tester, String id) async {
  await tester.tap(find.text("Item $id"));
  await tester.pump();
}

int _vertexCount() => find.bySemanticsLabel(_kVertex).evaluate().length;

TextButton _tool(WidgetTester tester, String label) {
  return tester.widget<TextButton>(find.widgetWithText(TextButton, label));
}

PillBadge _counter(WidgetTester tester) {
  return tester.widget<PillBadge>(find.byType(PillBadge));
}

Finder _liveRegionAround(String text) {
  return find.ancestor(
    of: find.text(text),
    matching: find.byWidgetPredicate(
      (Widget widget) =>
          widget is Semantics && (widget.properties.liveRegion ?? false),
    ),
  );
}

/// Colours of the indicator segments, in step order.
List<Color?> _segmentColors(WidgetTester tester) {
  return tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(TweenAnimationBuilder<Color?>),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((DecoratedBox box) => (box.decoration as BoxDecoration).color)
      .toList();
}

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(PolygonWizardSheet))).colorScheme;
}

/// Whether [finder] lies whole inside its scroll view and above the map.
bool _shownAboveMap(WidgetTester tester, Finder finder) {
  final Rect rect = tester.getRect(finder);
  final Rect viewport = tester.getRect(
    find.ancestor(of: finder, matching: find.byType(Scrollable)).first,
  );
  final double mapTop = tester.getRect(find.byType(MapPolygonEditor)).top;
  return rect.top >= viewport.top &&
      rect.bottom <= viewport.bottom &&
      rect.bottom <= mapTop;
}

/// Name "  North  ", the square, item "a": lands on the summary of a
/// [name, polygon, selection, summary] wizard.
Future<void> _walkToSummary(WidgetTester tester) async {
  await _typeName(tester, "  North  ");
  await _tapNext(tester);
  await _importSquare(tester);
  await _tapNext(tester);
  await _pick(tester, "a");
  await tester.pump();
  await _tapNext(tester);
}

void main() {
  _indicatorTests();
  _nameStepTests();
  _polygonStepTests();
  _suggestionTests();
  _singleSelectionTests();
  _multiSelectionTests();
  _summaryTests();
  _submitTests();
  _lockTests();
  _modalHostTests();
  _motionAndAccessibilityTests();
  _assertTests();
}

void _indicatorTests() {
  group("step indicator", () {
    testWidgets("one labelled segment per step, the first body, no Back", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[
          _kName,
          _kPolygon,
          _kSelection,
          _kSummary,
        ]),
      );
      await tester.pump(_kSettle);

      // The active title shows in the indicator and the step header.
      expect(find.text("Step name"), findsNWidgets(2));
      expect(find.text("Step polygon"), findsOneWidget);
      expect(find.text("Step selection"), findsOneWidget);
      expect(find.text("Step summary"), findsOneWidget);
      expect(find.text("Hint name"), findsOneWidget);
      expect(_backButton, findsNothing);
      expect(find.bySemanticsLabel(_kStepSemantics), findsOneWidget);

      final ColorScheme cs = _scheme(tester);
      expect(_segmentColors(tester), <Color?>[
        cs.primary,
        cs.outlineVariant,
        cs.outlineVariant,
        cs.outlineVariant,
      ]);
    });

    testWidgets("Next marks the step done and the next one active", (
      WidgetTester tester,
    ) async {
      await _pump(tester, _Wizard(<PolygonWizardStepKind>[_kName, _kPolygon]));
      await _typeName(tester, "North");
      await _tapNext(tester);

      final ColorScheme cs = _scheme(tester);
      expect(_segmentColors(tester), <Color?>[
        cs.primary.withValues(alpha: 0.55),
        cs.primary,
      ]);
      expect(find.text("Step polygon"), findsNWidgets(2));
    });
  });
}

void _nameStepTests() {
  group("name step", () {
    testWidgets("Next stays disabled while the name is blank", (
      WidgetTester tester,
    ) async {
      await _pump(tester, _Wizard(<PolygonWizardStepKind>[_kName, _kPolygon]));
      expect(find.text(_kNext), findsOneWidget);
      expect(_nextEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField), "   ");
      await tester.pump();
      expect(_nextEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField), "North");
      await tester.pump();
      expect(_nextEnabled(tester), isTrue);

      await _tapNext(tester);
      expect(find.text("Hint polygon"), findsOneWidget);
      expect(find.byType(MapPolygonEditor), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(_backButton, findsOneWidget);
    });

    testWidgets("nameLabel replaces the field placeholder", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[_kName, _kPolygon], nameLabel: "Label"),
      );
      final TextField field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.hintText, "Label");
    });

    testWidgets("a non-blank initialName skips a leading name step", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[
          _kName,
          _kPolygon,
        ], initialName: "Preset"),
      );
      expect(find.text("Hint polygon"), findsOneWidget);
      expect(_backButton, findsOneWidget);

      await _tapBack(tester);
      expect(find.text("Hint name"), findsOneWidget);
      expect(find.text("Preset"), findsOneWidget);
      expect(_nextEnabled(tester), isTrue);
    });

    testWidgets("initialName pre-fills without skipping otherwise", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[
          _kPolygon,
          _kName,
        ], initialName: "Preset"),
      );
      expect(find.text("Hint polygon"), findsOneWidget);
      await _importSquare(tester);
      await _tapNext(tester);
      expect(find.text("Preset"), findsOneWidget);
    });

    testWidgets("a blank initialName does not skip the name step", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[_kName, _kPolygon], initialName: "  "),
      );
      expect(find.text("Hint name"), findsOneWidget);
      expect(_nextEnabled(tester), isFalse);
    });
  });
}

void _polygonStepTests() {
  group("polygon step", () {
    testWidgets("Next, undo, reset and the counter follow the drawing", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[_kPolygon, _kSummary]),
      );
      final ColorScheme cs = _scheme(tester);
      expect(_nextEnabled(tester), isFalse);
      expect(_tool(tester, _kUndo).onPressed, isNull);
      expect(_tool(tester, _kReset).onPressed, isNull);
      expect(_counter(tester).label, _kPointsPlaced);
      expect(_counter(tester).dense, isTrue);
      expect(_counter(tester).backgroundColor, cs.inverseSurface);
      expect(_counter(tester).icon, isNull);
      expect(_liveRegionAround(_kPointsPlaced), findsOneWidget);

      await _draw(tester, _kTriangle);
      expect(_vertexCount(), 3);
      expect(_nextEnabled(tester), isTrue);
      expect(_counter(tester).backgroundColor, cs.primary);
      expect(_counter(tester).color, cs.onPrimary);
      expect(_counter(tester).icon, Icons.check_rounded);

      await tester.tap(find.text(_kUndo));
      await tester.pump();
      expect(_vertexCount(), 2);
      expect(_nextEnabled(tester), isFalse);
      expect(_tool(tester, _kReset).onPressed, isNotNull);

      await tester.tap(find.text(_kReset));
      await tester.pump();
      expect(_vertexCount(), 0);
      expect(_tool(tester, _kUndo).onPressed, isNull);
    });

    testWidgets("crossing edges block Next and show a live hint", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[_kPolygon, _kSummary]),
      );
      await _draw(tester, _kBowTie);
      expect(_vertexCount(), 4);
      expect(_nextEnabled(tester), isFalse);
      expect(_liveRegionAround(_kCrossing), findsOneWidget);
      expect(_counter(tester).icon, isNull);

      await tester.tap(find.text(_kUndo));
      await tester.pump();
      expect(find.text(_kCrossing), findsNothing);
      expect(_nextEnabled(tester), isTrue);
    });

    testWidgets("forwards the camera, the zoom limits and the attribution", (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        PolygonWizardSheet(
          steps: _steps(<PolygonWizardStepKind>[_kPolygon]),
          tileLayer: _tileLayer(),
          onSubmit: _FakeSubmit().call,
          initialCenter: const LatLng(12, 34),
          initialZoom: 7,
          attribution: const SizedBox(key: ValueKey<String>("credit")),
        ),
        surfaceSize: _kSurface,
      );
      final MapPolygonEditor editor = tester.widget<MapPolygonEditor>(
        find.byType(MapPolygonEditor),
      );
      expect(editor.initialCenter, const LatLng(12, 34));
      expect(editor.initialZoom, 7);
      expect(editor.minZoom, 2);
      expect(editor.maxZoom, 18);
      expect(find.byKey(const ValueKey<String>("credit")), findsOneWidget);
    });

    testWidgets("coming back to the step fits the camera to the polygon", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[_kPolygon, _kSummary]),
      );
      await _importSquare(tester);
      await _tapNext(tester);
      expect(find.byType(MapPolygonEditor), findsNothing);

      await _tapBack(tester);
      await tester.pump(_kSettle);
      final Finder handles = find.bySemanticsLabel(_kVertex);
      expect(handles, findsNWidgets(4));
      final Rect map = tester.getRect(find.byType(MapPolygonEditor));
      final Offset first = tester.getCenter(handles.at(0));
      final Offset third = tester.getCenter(handles.at(2));
      // At the initial zoom the 0.01° square would collapse to one point.
      expect((first - third).distance, greaterThan(100));
      expect(map.contains(first) && map.contains(third), isTrue);
    });

    testWidgets("on a short sheet the rows scroll and the map keeps its room", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[
          _kPolygon,
          _kSummary,
        ], suggestions: _kTwoRows),
        surfaceSize: const Size(700, 420),
      );
      expect(tester.takeException(), isNull);
      // The step is about 300 dp tall: half of it goes to the map.
      expect(
        tester.getSize(find.byType(MapPolygonEditor)).height,
        greaterThanOrEqualTo(140),
      );

      // A flatter triangle that fits the short map.
      await _draw(tester, const <Offset>[
        Offset(-80, -40),
        Offset(80, -40),
        Offset(0, 40),
      ]);
      expect(_vertexCount(), 3);
      // The rows scroll; the tools stay pinned above the map.
      expect(_shownAboveMap(tester, find.text(_kUndo)), isTrue);
      await tester.tap(find.text(_kUndo));
      await tester.pump();
      expect(_vertexCount(), 2);
    });

    testWidgets("on a short sheet the crossing hint and the tools stay shown", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[
          _kPolygon,
          _kSummary,
        ], suggestions: _kTwoRows),
        surfaceSize: const Size(700, 600),
      );
      await _draw(tester, _kFlatBowTie);
      expect(_vertexCount(), 4);
      expect(_nextEnabled(tester), isFalse);
      expect(_shownAboveMap(tester, find.text(_kCrossing)), isTrue);
      expect(_shownAboveMap(tester, find.text(_kUndo)), isTrue);
      // The header stays next to the tools; the rows give way first.
      expect(_shownAboveMap(tester, find.text("Hint polygon")), isTrue);

      await tester.tap(find.text(_kUndo));
      await tester.pump();
      expect(_vertexCount(), 3);
      expect(find.text(_kCrossing), findsNothing);
      expect(_nextEnabled(tester), isTrue);
    });

    testWidgets("on a tiny sheet the crossing hint stays above the map", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[
          _kPolygon,
          _kSummary,
        ], suggestions: _kTwoRows),
        surfaceSize: const Size(700, 330),
      );
      await _draw(tester, _kFlatBowTie);
      expect(tester.takeException(), isNull);
      expect(_vertexCount(), 4);
      // The tools alone exceed the room: they scroll, the hint stays.
      expect(_shownAboveMap(tester, find.text(_kCrossing)), isTrue);
    });

    testWidgets("a map tap landing after Next left the step is undone", (
      WidgetTester tester,
    ) async {
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[
        _kPolygon,
        _kSummary,
      ]);
      await _pump(tester, wizard);
      await _draw(tester, _kTriangle);

      // flutter_map delivers this crossing 4th vertex 250 ms after the finger
      // lifts: after Next, to the editor the step cross-fade still shows.
      await tester.tapAt(
        tester.getCenter(find.byType(MapPolygonEditor)) + const Offset(0, -110),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await _tapNext(tester);
      expect(find.byType(MapPolygonEditor), findsNothing);
      expect(_nextEnabled(tester), isTrue);

      await _tapBack(tester);
      expect(_vertexCount(), 3);
      expect(find.text(_kCrossing), findsNothing);
      await _tapNext(tester);
      await _tapNext(tester);
      expect(wizard.submit.calls.single.$1.points, hasLength(3));
    });
  });
}

void _suggestionTests() {
  group("suggestions", () {
    testWidgets("a chip imports its polygon, a second tap clears it", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[_kPolygon, _kSummary]),
      );
      expect(find.text("Recent"), findsOneWidget);

      await _importSquare(tester);
      expect(_vertexCount(), 4);
      expect(_nextEnabled(tester), isTrue);
      expect(
        tester.getSemantics(find.text("Square")),
        matchesSemantics(
          label: "Square",
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      await _importSquare(tester);
      expect(_vertexCount(), 0);
      expect(_nextEnabled(tester), isFalse);
    });

    testWidgets("emptying the polygon un-marks the imported chip", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[_kPolygon, _kSummary]),
      );
      await _importSquare(tester);
      expect(
        tester.getSemantics(find.text("Square")),
        isSemantics(label: "Square", isSelected: true),
      );

      await tester.tap(find.text(_kReset));
      await tester.pump();
      expect(_vertexCount(), 0);
      expect(
        tester.getSemantics(find.text("Square")),
        isSemantics(label: "Square", isSelected: false),
      );

      // The chip imports again instead of clearing an empty polygon.
      await _importSquare(tester);
      expect(_vertexCount(), 4);
    });

    testWidgets("a suggestion with fewer than 3 points is disabled", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[_kPolygon, _kSummary]),
      );
      expect(
        tester.getSemantics(find.text("Short")),
        isSemantics(
          label: "Short",
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      final Text label = tester.widget<Text>(find.text("Short"));
      expect(
        label.style?.color,
        _scheme(tester).onSurface.withValues(alpha: 0.38),
      );

      await tester.tap(find.text("Short"));
      await _settle(tester);
      expect(_vertexCount(), 0);
      expect(_nextEnabled(tester), isFalse);
    });

    testWidgets("the rows are hidden when there is nothing to suggest", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[
          _kPolygon,
          _kSummary,
        ], suggestions: const <PolygonSuggestionGroup>[]),
      );
      expect(find.byIcon(Icons.pentagon_outlined), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets("loaded rows show a progress bar, then follow the given rows", (
      WidgetTester tester,
    ) async {
      final Completer<List<PolygonSuggestionGroup>> loading =
          Completer<List<PolygonSuggestionGroup>>();
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[
          _kPolygon,
          _kSummary,
        ], loadSuggestions: () => loading.future),
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel(_kLoading), findsOneWidget);
      expect(find.text("Recent"), findsOneWidget);

      loading.complete(const <PolygonSuggestionGroup>[
        PolygonSuggestionGroup(
          title: "Previous",
          suggestions: <PolygonSuggestion>[
            PolygonSuggestion(id: "old", label: "Old", points: _kSquare),
          ],
        ),
      ]);
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(
        tester.getTopLeft(find.text("Previous")).dy,
        greaterThan(tester.getTopLeft(find.text("Recent")).dy),
      );

      await tester.tap(find.text("Old"));
      await _settle(tester);
      expect(_vertexCount(), 4);
    });

    testWidgets("a failing loadSuggestions hides the bar and throws nothing", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[
          _kPolygon,
          _kSummary,
        ], loadSuggestions: () async => throw StateError("offline")),
      );
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text("Recent"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("a rebuild with other rows shows them before the loaded ones", (
      WidgetTester tester,
    ) async {
      final ValueNotifier<List<PolygonSuggestionGroup>> rows =
          ValueNotifier<List<PolygonSuggestionGroup>>(_kRecent);
      addTearDown(rows.dispose);
      await pumpApp(
        tester,
        _RebuiltSuggestionsHost(rows: rows, tileLayer: _tileLayer()),
        surfaceSize: _kSurface,
      );
      await tester.pump();
      expect(find.text("Recent"), findsOneWidget);
      expect(find.text("Previous"), findsOneWidget);

      rows.value = const <PolygonSuggestionGroup>[
        PolygonSuggestionGroup(
          title: "Later",
          suggestions: <PolygonSuggestion>[
            PolygonSuggestion(id: "late", label: "Late", points: _kSquare),
          ],
        ),
      ];
      await tester.pump();
      expect(find.text("Recent"), findsNothing);
      expect(
        tester.getTopLeft(find.text("Previous")).dy,
        greaterThan(tester.getTopLeft(find.text("Later")).dy),
      );

      await tester.tap(find.text("Late"));
      await _settle(tester);
      expect(_vertexCount(), 4);
    });
  });
}

void _singleSelectionTests() {
  group("selection step, single", () {
    testWidgets(
      "a pick resolves with initialCenter, shows a Loader, then the card",
      (WidgetTester tester) async {
        final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[
          _kSelection,
          _kPolygon,
        ], initialCenter: const LatLng(10, 20))..load.hold = true;
        await _pump(tester, wizard);
        expect(find.text("Hint selection"), findsOneWidget);
        expect(wizard.picker.polygons.last, isEmpty);
        expect(wizard.picker.selectedIds.last, isEmpty);
        expect(_nextEnabled(tester), isFalse);

        await _pick(tester, "a");
        expect(wizard.load.calls, <(String, LatLng)>[
          ("a", const LatLng(10, 20)),
        ]);
        expect(find.byType(Loader), findsOneWidget);
        expect(find.text("Item a"), findsNothing);
        // The header stays above the indicator.
        expect(find.text("Hint selection"), findsOneWidget);
        expect(_nextEnabled(tester), isFalse);

        wizard.load.pending["a"]!.complete(_selection("a"));
        await tester.pump();
        expect(find.byType(Loader), findsNothing);
        final EditableValueRow row = tester.widget<EditableValueRow>(
          find.byType(EditableValueRow),
        );
        expect(row.title, "Title a");
        expect(row.subtitle, "Subtitle a");
        expect(row.subtitleItalic, isTrue);
        expect(row.icon, Icons.check_circle_outline);
        expect(_nextEnabled(tester), isTrue);
      },
    );

    testWidgets("after drawing, the picker and loadSelection get the polygon", (
      WidgetTester tester,
    ) async {
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[
        _kPolygon,
        _kSelection,
      ]);
      await _pump(tester, wizard);
      await _importSquare(tester);
      await _tapNext(tester);
      expect(wizard.picker.polygons.last, _kSquare);

      await _pick(tester, "b");
      final LatLng centroid = wizard.load.calls.single.$2;
      expect(centroid.latitude, closeTo(45.005, 1e-9));
      expect(centroid.longitude, closeTo(5.005, 1e-9));
    });

    testWidgets("tapping the card shows the picker again", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[_kSelection, _kPolygon]),
      );
      await _pick(tester, "a");
      await tester.pump();
      expect(_nextEnabled(tester), isTrue);

      await tester.tap(find.text("Title a"));
      await tester.pump();
      expect(find.byType(EditableValueRow), findsNothing);
      expect(find.text("Item a"), findsOneWidget);
      expect(_nextEnabled(tester), isFalse);

      await _pick(tester, "b");
      await tester.pump();
      expect(find.text("Title b"), findsOneWidget);
    });

    testWidgets("a failing pick adds nothing and shows a live error", (
      WidgetTester tester,
    ) async {
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[
        _kSelection,
        _kPolygon,
      ])..load.error = StateError("down");
      await _pump(tester, wizard);
      await _pick(tester, "a");
      await tester.pump();

      expect(find.byType(EditableValueRow), findsNothing);
      expect(find.byType(Loader), findsNothing);
      expect(find.text("Item a"), findsOneWidget);
      expect(_liveRegionAround(_kSelectionError), findsOneWidget);
      expect(_nextEnabled(tester), isFalse);

      wizard.load.error = null;
      await _pick(tester, "a");
      await tester.pump();
      expect(find.text(_kSelectionError), findsNothing);
      expect(find.text("Title a"), findsOneWidget);
    });

    testWidgets("leaving the step clears the failed-pick error", (
      WidgetTester tester,
    ) async {
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[
        _kPolygon,
        _kSelection,
      ])..load.error = StateError("down");
      await _pump(tester, wizard);
      await _importSquare(tester);
      await _tapNext(tester);
      await _pick(tester, "a");
      await tester.pump();
      expect(find.text(_kSelectionError), findsOneWidget);

      await _tapBack(tester);
      await _tapNext(tester);
      expect(find.text("Hint selection"), findsOneWidget);
      expect(find.text(_kSelectionError), findsNothing);
    });
  });
}

void _multiSelectionTests() {
  group("selection step, multiple", () {
    testWidgets("picks become chips while the picker keeps its State", (
      WidgetTester tester,
    ) async {
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[
        _kSelection,
        _kPolygon,
      ], multiple: true)..load.hold = true;
      await _pump(tester, wizard);
      expect(wizard.picker.states, hasLength(1));

      await _pick(tester, "a");
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text("Item a"), findsOneWidget);
      expect(wizard.picker.states, hasLength(1));
      expect(_nextEnabled(tester), isFalse);

      wizard.load.pending["a"]!.complete(_selection("a"));
      await _settle(tester);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text("Title a"), findsOneWidget);
      expect(find.text(_kSelectedCount), findsOneWidget);
      expect(wizard.picker.selectedIds.last, <String>{"a"});
      expect(_nextEnabled(tester), isTrue);

      await _pick(tester, "b");
      wizard.load.pending["b"]!.complete(_selection("b"));
      await _settle(tester);
      expect(find.text("Title a"), findsOneWidget);
      expect(find.text("Title b"), findsOneWidget);
      expect(wizard.picker.selectedIds.last, <String>{"a", "b"});
      expect(wizard.picker.states, hasLength(1));
    });

    testWidgets("an id still resolving is not resolved twice; Next waits", (
      WidgetTester tester,
    ) async {
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[
        _kSelection,
        _kPolygon,
      ], multiple: true)..load.hold = true;
      await _pump(tester, wizard);
      await _pick(tester, "a");
      wizard.load.pending["a"]!.complete(_selection("a"));
      await _settle(tester);
      expect(_nextEnabled(tester), isTrue);

      await _pick(tester, "b");
      await _pick(tester, "b");
      expect(
        wizard.load.calls.map(((String, LatLng) call) => call.$1),
        <String>["a", "b"],
      );
      // One selection is enough, but a pick is still resolving.
      expect(_nextEnabled(tester), isFalse);

      wizard.load.pending["b"]!.complete(_selection("b"));
      await _settle(tester);
      expect(find.text("Title b"), findsOneWidget);
      expect(_nextEnabled(tester), isTrue);
    });

    testWidgets("a selected id is not resolved again; a chip can be removed", (
      WidgetTester tester,
    ) async {
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[
        _kSelection,
        _kPolygon,
      ], multiple: true);
      await _pump(tester, wizard);
      await _pick(tester, "a");
      await _settle(tester);
      await _pick(tester, "a");
      await _settle(tester);
      expect(wizard.load.calls, hasLength(1));
      expect(find.text("Title a"), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(_kRemoveItem));
      await _settle(tester);
      expect(find.text("Title a"), findsNothing);
      expect(wizard.picker.selectedIds.last, isEmpty);
      expect(_nextEnabled(tester), isFalse);
    });
  });
}

void _summaryTests() {
  group("summary step", () {
    testWidgets("lists the typed name, the selections and the vertex count", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[
          _kName,
          _kPolygon,
          _kSelection,
          _kSummary,
        ]),
      );
      await _walkToSummary(tester);

      expect(find.text("Hint summary"), findsOneWidget);
      expect(find.text(_kNameLabel), findsOneWidget);
      expect(find.text("North"), findsOneWidget);
      expect(find.text(_kSelectionLabel), findsOneWidget);
      expect(find.text("Title a"), findsOneWidget);
      expect(find.text(_kPointsLabel), findsOneWidget);
      expect(find.text(_kPointsCount), findsOneWidget);
    });

    testWidgets("custom labels replace the defaults; titles are joined", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(
          <PolygonWizardStepKind>[_kName, _kPolygon, _kSelection, _kSummary],
          multiple: true,
          nameLabel: "Label N",
          selectionLabel: "Label S",
        ),
      );
      await _typeName(tester, "North");
      await _tapNext(tester);
      await _importSquare(tester);
      await _tapNext(tester);
      await _pick(tester, "a");
      await _pick(tester, "b");
      await _settle(tester);
      await _tapNext(tester);

      expect(find.text("Label N"), findsOneWidget);
      expect(find.text("Label S"), findsOneWidget);
      expect(find.text("Title a, Title b"), findsOneWidget);
    });

    testWidgets("a long label is ellipsized instead of overflowing", (
      WidgetTester tester,
    ) async {
      const String long = "A rather long name label that a host might pass in";
      await _pump(
        tester,
        _Wizard(
          <PolygonWizardStepKind>[_kPolygon, _kSummary],
          initialName: "North",
          nameLabel: long,
        ),
        surfaceSize: const Size(360, 800),
      );
      await _importSquare(tester);
      await _tapNext(tester);

      expect(tester.takeException(), isNull);
      expect(find.text("North"), findsOneWidget);
      final Text label = tester.widget<Text>(find.text(long));
      expect(label.maxLines, 1);
      expect(label.overflow, TextOverflow.ellipsis);
      expect(tester.getSize(find.text(long)).width, lessThan(360 * 0.4));
    });

    testWidgets("leaves out the rows without data", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[_kPolygon, _kSummary]),
      );
      await _importSquare(tester);
      await _tapNext(tester);
      expect(find.text(_kNameLabel), findsNothing);
      expect(find.text(_kSelectionLabel), findsNothing);
      expect(find.text(_kPointsLabel), findsOneWidget);
    });
  });
}

void _submitTests() {
  group("submit", () {
    testWidgets("submits once with the name, points and selections", (
      WidgetTester tester,
    ) async {
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[
        _kName,
        _kPolygon,
        _kSelection,
        _kSummary,
      ]);
      wizard.submit.pending = Completer<void>();
      await _pump(tester, wizard);
      await _walkToSummary(tester);
      expect(find.text(_kSubmit), findsOneWidget);

      await tester.tap(_nextButton);
      await tester.pump();
      await tester.tap(_nextButton);
      await tester.pump();
      expect(wizard.submit.calls, hasLength(1));
      expect(
        find.descendant(of: _nextButton, matching: find.byType(Loader)),
        findsOneWidget,
      );
      expect(tester.widget<TextButton>(_backButton).onPressed, isNull);

      final (PolygonFormResult result, List<PolygonFormSelection> picked) =
          wizard.submit.calls.single;
      expect(result.name, "North");
      expect(result.points, _kSquare);
      expect(result.selection?.id, "a");
      expect(picked.map((PolygonFormSelection s) => s.id), <String>["a"]);

      wizard.submit.pending!.complete();
      await tester.pump();
      expect(wizard.submitted, 1);
      // The sheet never pops a route itself and stays locked.
      expect(find.byType(PolygonWizardSheet), findsOneWidget);
      expect(_nextEnabled(tester), isFalse);
    });

    testWidgets("without a typed name, the first selection names the result", (
      WidgetTester tester,
    ) async {
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[
        _kPolygon,
        _kSelection,
        _kSummary,
      ]);
      await _pump(tester, wizard);
      await _importSquare(tester);
      await _tapNext(tester);
      await _pick(tester, "b");
      await tester.pump();
      await _tapNext(tester);
      await _tapNext(tester);
      expect(wizard.submit.calls.single.$1.name, "Title b");
    });

    testWidgets("then fallbackName; submitLabel names the button", (
      WidgetTester tester,
    ) async {
      final _Wizard named = _Wizard(
        <PolygonWizardStepKind>[_kPolygon],
        fallbackName: "Fallback",
        submitLabel: "Save",
      );
      await _pump(tester, named);
      await _importSquare(tester);
      expect(find.text("Save"), findsOneWidget);
      await _tapNext(tester);
      expect(named.submit.calls.single.$1.name, "Fallback");
      expect(named.submit.calls.single.$1.selection, isNull);
      expect(named.submit.calls.single.$2, isEmpty);
    });

    testWidgets("without fallbackName, the default_name key", (
      WidgetTester tester,
    ) async {
      final _Wizard unnamed = _Wizard(<PolygonWizardStepKind>[_kPolygon]);
      await _pump(tester, unnamed);
      await _importSquare(tester);
      await _tapNext(tester);
      expect(unnamed.submit.calls.single.$1.name, _kDefaultName);
    });

    testWidgets("a failure shows a live error and enables the button again", (
      WidgetTester tester,
    ) async {
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[
        _kPolygon,
        _kSummary,
      ], submitErrorText: "Oops")..submit.error = StateError("down");
      await _pump(tester, wizard);
      await _importSquare(tester);
      await _tapNext(tester);
      await _tapNext(tester);

      expect(_liveRegionAround("Oops"), findsOneWidget);
      expect(find.text("Hint summary"), findsOneWidget);
      expect(_nextEnabled(tester), isTrue);
      expect(wizard.submitted, 0);

      wizard.submit.error = null;
      await _tapNext(tester);
      expect(find.text("Oops"), findsNothing);
      expect(wizard.submitted, 1);
    });

    testWidgets("after success the button shows its label, not a spinner", (
      WidgetTester tester,
    ) async {
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[_kPolygon]);
      await _pump(tester, wizard);
      await _importSquare(tester);
      await tester.tap(_nextButton);
      await tester.pump();
      expect(wizard.submitted, 1);

      await tester.pump(const Duration(seconds: 1));
      expect(
        find.descendant(of: _nextButton, matching: find.text(_kSubmit)),
        findsOneWidget,
      );
      expect(find.byType(Loader), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_nextEnabled(tester), isFalse);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets("the default error text is the submit_error key", (
      WidgetTester tester,
    ) async {
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[_kPolygon])
        ..submit.error = StateError("down");
      await _pump(tester, wizard);
      await _importSquare(tester);
      await _tapNext(tester);
      expect(find.text(_kSubmitError), findsOneWidget);
    });
  });
}

/// Taps the imported "Square" chip and the map: neither may change the
/// 4 vertices of the imported square while the sheet is locked.
Future<void> _expectDrawingLocked(WidgetTester tester) async {
  await _importSquare(tester);
  await _tapMap(tester, _kTriangle[0]);
  expect(_vertexCount(), 4);
}

void _lockTests() {
  group("locked while submitting", () {
    testWidgets("tools, chips and the map ignore input during and after", (
      WidgetTester tester,
    ) async {
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[_kPolygon])
        ..submit.pending = Completer<void>();
      await _pump(tester, wizard);
      await _importSquare(tester);
      await tester.tap(_nextButton);
      await tester.pump();

      expect(_tool(tester, _kUndo).onPressed, isNull);
      expect(_tool(tester, _kReset).onPressed, isNull);
      expect(
        tester.getSemantics(find.text("Square")),
        isSemantics(label: "Square", isEnabled: false, isSelected: true),
      );
      await _expectDrawingLocked(tester);

      wizard.submit.pending!.complete();
      await tester.pump();
      expect(wizard.submitted, 1);
      await _expectDrawingLocked(tester);
      expect(wizard.submit.calls.single.$1.points, _kSquare);
    });

    testWidgets("the name field is disabled while submitting", (
      WidgetTester tester,
    ) async {
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[_kPolygon, _kName])
        ..submit.pending = Completer<void>();
      await _pump(tester, wizard);
      await _importSquare(tester);
      await _tapNext(tester);
      await _typeName(tester, "North");
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);

      await tester.tap(_nextButton);
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });

    testWidgets("a chip removal racing the submit tap is ignored", (
      WidgetTester tester,
    ) async {
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[
        _kPolygon,
        _kSelection,
      ], multiple: true)..submit.pending = Completer<void>();
      await _pump(tester, wizard);
      await _importSquare(tester);
      await _tapNext(tester);
      await _pick(tester, "a");
      await _settle(tester);

      // Two fingers; both lift before the next frame, so the chip still holds
      // its remove callback when the submit has already started.
      final TestGesture remove = await tester.startGesture(
        tester.getCenter(find.bySemanticsLabel(_kRemoveItem)),
      );
      final TestGesture submit = await tester.startGesture(
        tester.getCenter(_nextButton),
      );
      await submit.up();
      await remove.up();
      await tester.pump();

      expect(wizard.submit.calls, hasLength(1));
      expect(find.text("Title a"), findsOneWidget);
    });

    testWidgets("an undo racing the submit tap is ignored", (
      WidgetTester tester,
    ) async {
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[_kPolygon])
        ..submit.pending = Completer<void>();
      await _pump(tester, wizard);
      await _importSquare(tester);

      // Two fingers lifted in the same frame: undo still holds its callback.
      final TestGesture undo = await tester.startGesture(
        tester.getCenter(find.text(_kUndo)),
      );
      final TestGesture submit = await tester.startGesture(
        tester.getCenter(_nextButton),
      );
      await submit.up();
      await undo.up();
      await _settle(tester);

      expect(wizard.submit.calls.single.$1.points, _kSquare);
      expect(_vertexCount(), 4);
    });

    testWidgets("a map tap landing after the submit is undone", (
      WidgetTester tester,
    ) async {
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[_kPolygon])
        ..submit.pending = Completer<void>();
      await _pump(tester, wizard);
      await _draw(tester, _kTriangle);

      // flutter_map delivers a map tap 250 ms after the finger lifts, so this
      // vertex arrives after the submit below has captured the triangle.
      await tester.tapAt(
        tester.getCenter(find.byType(MapPolygonEditor)) +
            const Offset(-100, 60),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(_nextButton);
      await _settle(tester);

      expect(wizard.submit.calls.single.$1.points, hasLength(3));
      expect(_vertexCount(), 3);
    });
  });
}

List<Offset> _handleCenters(WidgetTester tester) {
  final Finder handles = find.bySemanticsLabel(_kVertex);
  return <Offset>[
    for (int i = 0; i < handles.evaluate().length; i++)
      tester.getCenter(handles.at(i)),
  ];
}

/// Opens a one-step (polygon) wizard in a modal bottom sheet whose
/// onSubmitted pops it.
Future<void> _openInSheet(
  WidgetTester tester,
  _FakeSubmit submit,
  VoidCallback onSubmitted,
) async {
  await pumpApp(
    tester,
    Builder(
      builder: (BuildContext context) => TextButton(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (BuildContext sheetContext) => FractionallySizedBox(
            heightFactor: 0.92,
            child: PolygonWizardSheet(
              steps: _steps(<PolygonWizardStepKind>[_kPolygon]),
              tileLayer: _tileLayer(),
              onSubmit: submit.call,
              onSubmitted: () {
                onSubmitted();
                Navigator.of(sheetContext).pop();
              },
            ),
          ),
        ),
        child: const Text("open"),
      ),
    ),
    surfaceSize: _kSurface,
  );
  await tester.tap(find.text("open"));
  await tester.pumpAndSettle();
}

void _modalHostTests() {
  group("modal bottom sheet host", () {
    testWidgets("a successful submit closes the sheet through onSubmitted", (
      WidgetTester tester,
    ) async {
      int closes = 0;
      await _openInSheet(tester, _FakeSubmit(), () => closes++);
      await _draw(tester, _kTriangle);
      await tester.tap(_nextButton);
      await tester.pumpAndSettle();

      expect(closes, 1);
      expect(find.byType(PolygonWizardSheet), findsNothing);
      expect(find.text("open"), findsOneWidget);
    });

    testWidgets("dragging a vertex down moves it, not the sheet", (
      WidgetTester tester,
    ) async {
      await _openInSheet(tester, _FakeSubmit(), () {});
      await _draw(tester, _kTriangle);
      final double sheetTop = tester
          .getTopLeft(find.byType(PolygonWizardSheet))
          .dy;

      final Offset start =
          tester.getCenter(find.byType(MapPolygonEditor)) + _kTriangle[0];
      final TestGesture gesture = await tester.startGesture(start);
      for (int i = 0; i < 12; i++) {
        await gesture.moveBy(const Offset(0, 5));
        await tester.pump();
      }

      // Checked before the release: a dragged sheet springs back after it.
      expect(tester.getTopLeft(find.byType(PolygonWizardSheet)).dy, sheetTop);
      final Offset finger = start + const Offset(0, 60);
      expect((_handleCenters(tester)[0] - finger).distance, lessThan(1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byType(PolygonWizardSheet), findsOneWidget);
    });

    testWidgets("a submit ending while the sheet closes skips onSubmitted", (
      WidgetTester tester,
    ) async {
      final _FakeSubmit submit = _FakeSubmit()..pending = Completer<void>();
      int closes = 0;
      await _openInSheet(tester, submit, () => closes++);
      await _draw(tester, _kTriangle);
      await tester.tap(_nextButton);
      await tester.pump();

      // Dismissed from outside (scrim, back) while the submit runs.
      Navigator.of(tester.element(find.byType(PolygonWizardSheet))).pop();
      await tester.pump();
      submit.pending!.complete();
      await tester.pump();
      expect(closes, 0);

      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(PolygonWizardSheet), findsNothing);
      // The page under the sheet was not popped.
      expect(find.text("open"), findsOneWidget);
    });
  });
}

void _motionAndAccessibilityTests() {
  group("motion and accessibility", () {
    testWidgets("with reduced motion a step change needs a single frame", (
      WidgetTester tester,
    ) async {
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[
        _kName,
        _kPolygon,
      ]);
      await _pumpReducedMotion(tester, wizard);
      await tester.enterText(find.byType(TextField), "North");
      await tester.pump();
      await tester.tap(_nextButton);
      await tester.pump();

      expect(find.text("Hint polygon"), findsOneWidget);
      expect(find.text("Hint name"), findsNothing);
      final ColorScheme cs = _scheme(tester);
      expect(_segmentColors(tester).last, cs.primary);
    });

    testWidgets("with reduced motion the loading line does not animate", (
      WidgetTester tester,
    ) async {
      final Completer<List<PolygonSuggestionGroup>> loading =
          Completer<List<PolygonSuggestionGroup>>();
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[
        _kPolygon,
        _kSummary,
      ], loadSuggestions: () => loading.future);
      await _pumpReducedMotion(tester, wizard);
      // Once the map tiles have faded in, nothing animates any more.
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.bySemanticsLabel(_kLoading), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);

      loading.complete(const <PolygonSuggestionGroup>[]);
      await _settle(tester);
      expect(find.bySemanticsLabel(_kLoading), findsNothing);
    });

    testWidgets("with reduced motion the busy indicators are static", (
      WidgetTester tester,
    ) async {
      final _Wizard wizard = _Wizard(<PolygonWizardStepKind>[
        _kSelection,
        _kPolygon,
      ])..load.hold = true;
      wizard.submit.pending = Completer<void>();
      await _pumpReducedMotion(tester, wizard);
      await _pick(tester, "a");
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.bySemanticsLabel(_kLoading), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);

      wizard.load.pending["a"]!.complete(_selection("a"));
      // Nothing animates, so no frame is scheduled: the first pump only runs
      // the pick's completion, the second draws it.
      await _settle(tester);
      await _tapNext(tester);
      await _importSquare(tester);
      await tester.tap(_nextButton);
      await tester.pump();
      // Once the button's ink and state changes are over, nothing animates.
      await tester.pump(const Duration(seconds: 1));
      expect(wizard.submit.calls, hasLength(1));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.descendant(
          of: _nextButton,
          matching: find.byIcon(Icons.hourglass_empty_rounded),
        ),
        findsOneWidget,
      );
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets("buttons, chips and remove targets are at least 48 dp", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[
          _kPolygon,
          _kSelection,
        ], multiple: true),
      );
      void expectTarget(Finder finder) {
        final Size size = tester.getSize(finder);
        expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
        expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
      }

      expectTarget(
        find.ancestor(of: find.text("Square"), matching: find.byType(InkWell)),
      );
      await _importSquare(tester);
      expectTarget(find.widgetWithText(TextButton, _kUndo));
      expectTarget(find.widgetWithText(TextButton, _kReset));
      expectTarget(_nextButton);

      await _tapNext(tester);
      await _pick(tester, "a");
      await _settle(tester);
      expectTarget(_backButton);
      expectTarget(find.bySemanticsLabel(_kRemoveItem));
    });

    testWidgets("dark theme: renders every step with dark tokens", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _Wizard(<PolygonWizardStepKind>[
          _kName,
          _kPolygon,
          _kSelection,
          _kSummary,
        ]),
        theme: AppTheme.dark(),
      );
      final ColorScheme dark = AppTheme.dark().colorScheme;
      await _typeName(tester, "North");
      await _tapNext(tester);
      expect(_counter(tester).backgroundColor, dark.inverseSurface);
      await _importSquare(tester);
      expect(_counter(tester).backgroundColor, dark.primary);
      await _tapNext(tester);
      await _pick(tester, "a");
      await _settle(tester);
      await _tapNext(tester);
      expect(find.text("North"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

void _assertTests() {
  group("asserts", () {
    testWidgets("a selection step without a picker asserts", (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        PolygonWizardSheet(
          steps: _steps(<PolygonWizardStepKind>[_kSelection, _kPolygon]),
          tileLayer: _tileLayer(),
          onSubmit: _FakeSubmit().call,
        ),
      );
      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets("steps without exactly one polygon step assert", (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        PolygonWizardSheet(
          steps: _steps(<PolygonWizardStepKind>[_kName, _kSummary]),
          tileLayer: _tileLayer(),
          onSubmit: _FakeSubmit().call,
        ),
      );
      expect(tester.takeException(), isA<AssertionError>());
    });

    test("pickerBuilder without loadSelection asserts", () {
      expect(
        () => PolygonWizardSheet(
          steps: _steps(<PolygonWizardStepKind>[_kSelection, _kPolygon]),
          tileLayer: _tileLayer(),
          onSubmit: _FakeSubmit().call,
          pickerBuilder: _PickerProbe().build,
        ),
        throwsAssertionError,
      );
    });
  });
}
