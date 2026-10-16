// polygon_form_sheet_test.dart
//
// Widget tests for PolygonFormSheet (lib/widgets/custom/PolygonFormSheet/):
// picker phase and selection loading (success and failure; drawing, name
// and map camera kept and focus dropped across a round trip), drawing
// through the composed MapPolygonEditor (hint, counter, undo / reset,
// vertex semantics, crossing-edge hint, vertex drags
// and map pans that never scroll the form or drag the sheet), forwarded map
// parameters (camera, zoom limits, attribution), label overrides, the name
// field's semantics, submit gating, the submit lifecycle (result payload,
// spinner with the button's name kept, locking, inline error and retry),
// hosting in a modal bottom sheet, tap targets and the dark theme. Tiles
// come from an in-memory TileProvider, so no network is used.

import "dart:async";
import "dart:typed_data";

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/EditableValueRow/index.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";
import "package:flutter_skeleton/widgets/custom/MapPolygonEditor/index.dart";
import "package:flutter_skeleton/widgets/custom/PolygonFormSheet/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:latlong2/latlong.dart";

import "../../helpers/widget_test_helpers.dart";

const String _kClose = "custom.polygon_form_sheet.close";
const String _kSelectionLabel = "custom.polygon_form_sheet.selection_label";
const String _kSelectionError = "custom.polygon_form_sheet.selection_error";
const String _kChangeSelection = "custom.polygon_form_sheet.change_selection";
const String _kDrawLabel = "custom.polygon_form_sheet.draw_label";
const String _kDrawHint = "custom.polygon_form_sheet.draw_hint";
const String _kUndo = "custom.polygon_form_sheet.undo";
const String _kReset = "custom.polygon_form_sheet.reset";
const String _kPointCount = "custom.polygon_form_sheet.point_count";
const String _kNameLabel = "custom.polygon_form_sheet.name_label";
const String _kSubmit = "custom.polygon_form_sheet.submit";
const String _kSubmitError = "custom.polygon_form_sheet.submit_error";
const String _kCrossingEdges = "custom.polygon_form_sheet.crossing_edges";
const String _kVertex = "custom.map_polygon_editor.vertex";

const String _kTitle = "New area";
// Wide enough for the raw i18n keys that pumpApp renders to sit on one line
// (the selection card's edit chip keeps its intrinsic width).
const Size _kSurface = Size(800, 1000);

/// Longer than flutter_map's 250 ms double-tap window, so a tap resolves.
const Duration _kTapSettle = Duration(milliseconds: 400);

/// Tap offsets from the map centre: a triangle whose vertices and edges are
/// far from each other (no snapping between taps).
const List<Offset> _kTriangle = <Offset>[
  Offset(-80, -60),
  Offset(80, -60),
  Offset(0, 80),
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

/// Picker with two items ("Item a", "Item b") reporting ids "a" and "b".
Widget _picker(BuildContext context, ValueChanged<String> onPicked) {
  return ListView(
    key: const ValueKey<String>("picker"),
    children: <Widget>[
      for (final String id in <String>["a", "b"])
        ListTile(title: Text("Item $id"), onTap: () => onPicked(id)),
    ],
  );
}

Future<PolygonFormSelection> _loadNow(String id) async {
  return PolygonFormSelection(
    id: id,
    title: "Title $id",
    subtitle: "Subtitle $id",
    subtitleItalic: true,
  );
}

Future<void> _noopSubmit(PolygonFormResult result) async {}

void _noopClose() {}

PolygonFormSheet _sheet({
  Future<void> Function(PolygonFormResult result) onSubmit = _noopSubmit,
  VoidCallback onClose = _noopClose,
  bool withPicker = false,
  Future<PolygonFormSelection> Function(String id) loadSelection = _loadNow,
  String? submitErrorText,
  String? submitLabel,
}) {
  return PolygonFormSheet(
    title: _kTitle,
    tileLayer: _tileLayer(),
    onSubmit: onSubmit,
    onClose: onClose,
    pickerBuilder: withPicker ? _picker : null,
    loadSelection: withPicker ? loadSelection : null,
    nameHint: "Name hint",
    submitErrorText: submitErrorText,
    submitLabel: submitLabel,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget sheet, {
  ThemeData? theme,
  Size surfaceSize = _kSurface,
}) async {
  await pumpApp(tester, sheet, surfaceSize: surfaceSize, theme: theme);
  await tester.pump();
}

Offset _mapCenter(WidgetTester tester) {
  return tester.getCenter(find.byType(MapPolygonEditor));
}

Future<void> _tapMap(WidgetTester tester, Offset delta) async {
  await tester.tapAt(_mapCenter(tester) + delta);
  await tester.pump(_kTapSettle);
}

Future<void> _drawTriangle(WidgetTester tester) async {
  for (final Offset delta in _kTriangle) {
    await _tapMap(tester, delta);
  }
}

Future<void> _pick(WidgetTester tester, String id) async {
  await tester.tap(find.text("Item $id"));
  await tester.pump();
}

Finder get _submitButton => find.byType(FilledButton);

bool _submitEnabled(WidgetTester tester) {
  return tester.widget<FilledButton>(_submitButton).onPressed != null;
}

Future<void> _tapSubmit(WidgetTester tester) async {
  await tester.ensureVisible(_submitButton);
  await tester.tap(_submitButton);
  await tester.pump();
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

Finder _toolButton(String label) {
  return find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((Widget widget) => widget is TextButton),
  );
}

Finder get _polygonLayer =>
    find.byWidgetPredicate((Widget widget) => widget is PolygonLayer);

List<Offset> _handleCenters(WidgetTester tester) {
  final Finder vertices = find.bySemanticsLabel(_kVertex);
  return <Offset>[
    for (int i = 0; i < vertices.evaluate().length; i++)
      tester.getCenter(vertices.at(i)),
  ];
}

/// Scroll position of the form's list.
ScrollPosition _formScroll(WidgetTester tester) {
  return tester
      .state<ScrollableState>(
        find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      )
      .position;
}

void main() {
  group("picker phase", () {
    testWidgets("shows the title, the close button and the picker, no map", (
      WidgetTester tester,
    ) async {
      int closes = 0;
      await _pump(
        tester,
        _sheet(withPicker: true, onClose: () => closes++),
      );

      expect(find.text(_kTitle), findsOneWidget);
      expect(find.byKey(const ValueKey<String>("picker")), findsOneWidget);
      expect(find.byType(MapPolygonEditor), findsNothing);
      expect(find.text(_kSubmit), findsNothing);

      await tester.tap(find.bySemanticsLabel(_kClose));
      await tester.pump();
      expect(closes, 1);
      // The sheet never pops a route itself.
      expect(find.byType(PolygonFormSheet), findsOneWidget);
    });

    testWidgets("a pick shows a Loader until loadSelection resolves, then the card", (
      WidgetTester tester,
    ) async {
      final Completer<PolygonFormSelection> pending =
          Completer<PolygonFormSelection>();
      final List<String> requested = <String>[];
      await _pump(
        tester,
        _sheet(
          withPicker: true,
          loadSelection: (String id) {
            requested.add(id);
            return pending.future;
          },
        ),
      );

      await _pick(tester, "b");
      expect(requested, <String>["b"]);
      expect(find.byKey(const ValueKey<String>("picker")), findsNothing);
      expect(find.text(_kSelectionLabel.toUpperCase()), findsOneWidget);
      expect(find.byType(Loader), findsOneWidget);
      expect(find.byType(MapPolygonEditor), findsOneWidget);
      expect(find.byType(EditableValueRow), findsNothing);

      pending.complete(
        const PolygonFormSelection(
          id: "b",
          title: "Title b",
          subtitle: "Subtitle b",
          subtitleItalic: true,
        ),
      );
      await tester.pump();

      expect(find.byType(Loader), findsNothing);
      expect(find.text("Title b"), findsOneWidget);
      final Text subtitle = tester.widget<Text>(find.text("Subtitle b"));
      expect(subtitle.style?.fontStyle, FontStyle.italic);
      final EditableValueRow row = tester.widget<EditableValueRow>(
        find.byType(EditableValueRow),
      );
      expect(row.icon, Icons.label_outline_rounded);
      expect(row.semanticsLabel, _kChangeSelection);
    });

    testWidgets("tapping the card returns to the picker and keeps the drawing", (
      WidgetTester tester,
    ) async {
      await _pump(tester, _sheet(withPicker: true));
      await _pick(tester, "a");
      await _drawTriangle(tester);
      expect(find.bySemanticsLabel(_kVertex), findsNWidgets(3));
      await tester.enterText(find.byType(TextField), "North");
      expect(tester.testTextInput.isVisible, isTrue);

      await tester.tap(find.text("Title a"));
      await tester.pump();
      expect(find.byKey(const ValueKey<String>("picker")), findsOneWidget);
      expect(find.byType(MapPolygonEditor), findsNothing);
      // The hidden form gives up the focus: the keyboard closes.
      expect(tester.testTextInput.isVisible, isFalse);

      await _pick(tester, "b");
      expect(find.text("Title b"), findsOneWidget);
      expect(find.bySemanticsLabel(_kVertex), findsNWidgets(3));
      expect(find.text("North"), findsOneWidget);
      expect(_submitEnabled(tester), isTrue);
    });

    testWidgets("a round trip through the picker keeps the map camera", (
      WidgetTester tester,
    ) async {
      await _pump(tester, _sheet(withPicker: true));
      await _pick(tester, "a");
      await tester.timedDrag(
        find.byType(MapPolygonEditor),
        const Offset(150, 0),
        const Duration(milliseconds: 500),
      );
      await tester.pump(const Duration(seconds: 2));
      await _drawTriangle(tester);
      final List<Offset> before = _handleCenters(tester);
      expect(before, hasLength(3));

      await tester.tap(find.text("Title a"));
      await tester.pump();
      await _pick(tester, "b");
      await tester.pump();

      final List<Offset> after = _handleCenters(tester);
      expect(after, hasLength(3));
      for (int i = 0; i < 3; i++) {
        expect((after[i] - before[i]).distance, lessThan(1));
      }
    });

    testWidgets("a failed load goes back to the picker with a live error", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _sheet(
          withPicker: true,
          loadSelection: (String id) async => throw Exception("load failed"),
        ),
      );

      await _pick(tester, "a");
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey<String>("picker")), findsOneWidget);
      expect(find.byType(EditableValueRow), findsNothing);
      expect(find.text(_kSelectionError), findsOneWidget);
      expect(_liveRegionAround(_kSelectionError), findsOneWidget);
    });
  });

  group("form without a picker", () {
    testWidgets("opens on the form with no selection section", (
      WidgetTester tester,
    ) async {
      await _pump(tester, _sheet());

      expect(find.byType(MapPolygonEditor), findsOneWidget);
      expect(find.text(_kSelectionLabel.toUpperCase()), findsNothing);
      expect(find.text(_kDrawLabel.toUpperCase()), findsOneWidget);
      expect(find.text(_kNameLabel.toUpperCase()), findsOneWidget);
      expect(find.text("Name hint"), findsOneWidget);
      expect(find.text(_kSubmit), findsOneWidget);
    });

    testWidgets("drawing shows the hint, then the counter and the tools", (
      WidgetTester tester,
    ) async {
      // Wide enough for both raw-key tool labels to fit on one line.
      await _pump(tester, _sheet(), surfaceSize: const Size(1200, 1000));

      expect(find.text(_kDrawHint), findsOneWidget);
      expect(find.text(_kPointCount), findsNothing);
      expect(find.text(_kUndo), findsNothing);
      expect(find.text(_kReset), findsNothing);
      final double mapTop = tester.getTopLeft(find.byType(MapPolygonEditor)).dy;

      await _tapMap(tester, _kTriangle[0]);
      expect(find.text(_kDrawHint), findsNothing);
      expect(find.text(_kPointCount), findsOneWidget);
      expect(find.text(_kUndo), findsOneWidget);
      expect(find.text(_kReset), findsOneWidget);
      expect(find.bySemanticsLabel(_kVertex), findsOneWidget);
      // The tools row keeps its height: the map does not move.
      expect(tester.getTopLeft(find.byType(MapPolygonEditor)).dy, mapTop);

      await _tapMap(tester, _kTriangle[1]);
      expect(_polygonLayer, findsNothing);
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      await _tapMap(tester, _kTriangle[2]);
      expect(find.bySemanticsLabel(_kVertex), findsNWidgets(3));
      expect(_polygonLayer, findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets("undo removes the last tapped vertex; reset clears them all", (
      WidgetTester tester,
    ) async {
      await _pump(tester, _sheet());
      await _drawTriangle(tester);

      await tester.tap(find.text(_kUndo));
      await tester.pump();
      final Finder vertices = find.bySemanticsLabel(_kVertex);
      expect(vertices, findsNWidgets(2));
      final Offset center = _mapCenter(tester);
      for (int i = 0; i < 2; i++) {
        final Offset handle = tester.getCenter(vertices.at(i));
        expect((handle - (center + _kTriangle[i])).distance, lessThan(1));
      }

      await tester.tap(find.text(_kReset));
      await tester.pump();
      expect(find.bySemanticsLabel(_kVertex), findsNothing);
      expect(find.text(_kDrawHint), findsOneWidget);
      expect(find.text(_kUndo), findsNothing);
    });

    testWidgets("submit needs 3 points", (WidgetTester tester) async {
      await _pump(tester, _sheet());
      expect(_submitEnabled(tester), isFalse);

      await _tapMap(tester, _kTriangle[0]);
      await _tapMap(tester, _kTriangle[1]);
      expect(_submitEnabled(tester), isFalse);

      await _tapMap(tester, _kTriangle[2]);
      expect(_submitEnabled(tester), isTrue);

      await tester.tap(find.text(_kUndo));
      await tester.pump();
      expect(_submitEnabled(tester), isFalse);
    });

    testWidgets("crossing edges disable submit and show a live hint", (
      WidgetTester tester,
    ) async {
      await _pump(tester, _sheet());
      // Corners tapped top-left, bottom-right, bottom-left, top-right: the
      // first and third edges cross (a bow-tie).
      for (final Offset delta in <Offset>[
        const Offset(-80, -60),
        const Offset(80, 60),
        const Offset(-80, 60),
        const Offset(80, -60),
      ]) {
        await _tapMap(tester, delta);
      }

      expect(find.bySemanticsLabel(_kVertex), findsNWidgets(4));
      expect(_submitEnabled(tester), isFalse);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.text(_kCrossingEdges), findsOneWidget);
      expect(_liveRegionAround(_kCrossingEdges), findsOneWidget);

      await tester.tap(find.text(_kUndo));
      await tester.pump();
      expect(find.text(_kCrossingEdges), findsNothing);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(_submitEnabled(tester), isTrue);
    });

    testWidgets("dragging a vertex vertically moves it, not the form", (
      WidgetTester tester,
    ) async {
      // Short enough for the form to scroll.
      await _pump(tester, _sheet(), surfaceSize: const Size(800, 560));
      expect(_formScroll(tester).maxScrollExtent, greaterThan(0));
      await _drawTriangle(tester);

      final Offset start = _mapCenter(tester) + _kTriangle[2];
      final TestGesture gesture = await tester.startGesture(start);
      for (int i = 0; i < 12; i++) {
        await gesture.moveBy(const Offset(0, -5));
        await tester.pump();
      }
      await gesture.up();
      await tester.pump(_kTapSettle);

      expect(_formScroll(tester).pixels, 0);
      final Offset finger = start + const Offset(0, -60);
      expect((_handleCenters(tester)[2] - finger).distance, lessThan(1));
    });

    testWidgets("a vertical drag on the map pans the map, not the form", (
      WidgetTester tester,
    ) async {
      await _pump(tester, _sheet(), surfaceSize: const Size(800, 560));
      await _drawTriangle(tester);
      final List<Offset> before = _handleCenters(tester);

      // Away from the vertices, so the drag pans the map.
      final TestGesture gesture = await tester.startGesture(
        _mapCenter(tester) + const Offset(-200, 0),
      );
      for (int i = 0; i < 12; i++) {
        await gesture.moveBy(const Offset(0, -5));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump(const Duration(seconds: 2));

      expect(_formScroll(tester).pixels, 0);
      final Offset moved = _handleCenters(tester)[0] - before[0];
      expect(moved.dx, closeTo(0, 1));
      expect(moved.dy, lessThan(-30));
    });

    testWidgets("forwards initialCenter, initialZoom and the zoom limits", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        PolygonFormSheet(
          title: _kTitle,
          tileLayer: _tileLayer(),
          onSubmit: _noopSubmit,
          onClose: _noopClose,
          initialCenter: const LatLng(12, 34),
          initialZoom: 7,
        ),
      );

      final MapPolygonEditor editor = tester.widget<MapPolygonEditor>(
        find.byType(MapPolygonEditor),
      );
      expect(editor.initialCenter, const LatLng(12, 34));
      expect(editor.initialZoom, 7);
      expect(editor.minZoom, 2);
      expect(editor.maxZoom, 18);
    });

    testWidgets("renders the attribution on the map", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        PolygonFormSheet(
          title: _kTitle,
          tileLayer: _tileLayer(),
          onSubmit: _noopSubmit,
          onClose: _noopClose,
          attribution: const Align(
            alignment: Alignment.bottomLeft,
            child: Text("Tile credit"),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(MapPolygonEditor),
          matching: find.text("Tile credit"),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<MapPolygonEditor>(find.byType(MapPolygonEditor)).attribution,
        isNotNull,
      );
    });

    testWidgets("selectionLabel, drawLabel and nameLabel replace the defaults", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        PolygonFormSheet(
          title: _kTitle,
          tileLayer: _tileLayer(),
          onSubmit: _noopSubmit,
          onClose: _noopClose,
          pickerBuilder: _picker,
          loadSelection: _loadNow,
          selectionLabel: "Picked item",
          drawLabel: "Outline",
          nameLabel: "Label",
        ),
      );
      await _pick(tester, "a");

      expect(find.text("PICKED ITEM"), findsOneWidget);
      expect(find.text("OUTLINE"), findsOneWidget);
      expect(find.text("LABEL"), findsOneWidget);
      for (final String key in <String>[
        _kSelectionLabel,
        _kDrawLabel,
        _kNameLabel,
      ]) {
        expect(find.text(key.toUpperCase()), findsNothing);
      }
    });

    testWidgets("the name field is announced with its label", (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _pump(tester, _sheet());

      final SemanticsNode field = find.semantics
          .byFlag(SemanticsFlag.isTextField)
          .evaluate()
          .single;
      expect(field.label, contains(_kNameLabel));
      expect(field.label, contains("Name hint"));
      semantics.dispose();
    });

    testWidgets("submits a null selection and an empty name when left blank", (
      WidgetTester tester,
    ) async {
      final List<PolygonFormResult> results = <PolygonFormResult>[];
      await _pump(
        tester,
        _sheet(onSubmit: (PolygonFormResult result) async => results.add(result)),
      );
      await _drawTriangle(tester);
      await _tapSubmit(tester);

      expect(results, hasLength(1));
      expect(results.single.selection, isNull);
      expect(results.single.name, isEmpty);
      expect(results.single.points, hasLength(3));
    });
  });

  group("submit", () {
    testWidgets("is disabled until an item is picked and 3 points exist", (
      WidgetTester tester,
    ) async {
      await _pump(tester, _sheet(withPicker: true));
      await _pick(tester, "a");
      expect(_submitEnabled(tester), isFalse);

      await _drawTriangle(tester);
      expect(_submitEnabled(tester), isTrue);
    });

    testWidgets("is disabled while the picked item loads", (
      WidgetTester tester,
    ) async {
      final Completer<PolygonFormSelection> pending =
          Completer<PolygonFormSelection>();
      await _pump(
        tester,
        _sheet(
          withPicker: true,
          loadSelection: (String id) => pending.future,
        ),
      );
      await _pick(tester, "a");
      await _drawTriangle(tester);
      expect(_submitEnabled(tester), isFalse);

      pending.complete(const PolygonFormSelection(id: "a", title: "Title a"));
      await tester.pump();
      expect(_submitEnabled(tester), isTrue);
    });

    testWidgets("sends the result once, shows a Loader, then calls onClose", (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final Completer<void> pending = Completer<void>();
      final List<PolygonFormResult> results = <PolygonFormResult>[];
      int closes = 0;
      await _pump(
        tester,
        _sheet(
          withPicker: true,
          onSubmit: (PolygonFormResult result) {
            results.add(result);
            return pending.future;
          },
          onClose: () => closes++,
        ),
      );
      await _pick(tester, "a");
      await _drawTriangle(tester);
      await tester.enterText(find.byType(TextField), "  North  ");
      await _tapSubmit(tester);

      expect(results, hasLength(1));
      final PolygonFormResult result = results.single;
      expect(result.selection?.id, "a");
      expect(result.selection?.title, "Title a");
      expect(result.name, "North");
      expect(result.points, hasLength(3));
      // Tap order is kept: two upper vertices left to right, then the lower.
      expect(result.points[0].latitude, closeTo(result.points[1].latitude, 1e-6));
      expect(result.points[0].longitude, lessThan(result.points[1].longitude));
      expect(result.points[2].latitude, lessThan(result.points[0].latitude));
      expect(
        () => result.points.add(const LatLng(0, 0)),
        throwsUnsupportedError,
      );

      expect(
        find.descendant(of: _submitButton, matching: find.byType(Loader)),
        findsOneWidget,
      );
      // The busy button keeps its name for screen readers.
      expect(tester.getSemantics(_submitButton).label, _kSubmit);
      expect(_submitEnabled(tester), isFalse);
      await tester.tap(_submitButton);
      await tester.pump();
      expect(results, hasLength(1));
      expect(closes, 0);

      pending.complete();
      await tester.pump();
      expect(closes, 1);
      // Locked after success: no second submit while the host closes.
      expect(_submitEnabled(tester), isFalse);
      expect(
        find.descendant(of: _submitButton, matching: find.byType(Loader)),
        findsOneWidget,
      );
      await tester.tap(find.text("Title a"));
      await tester.pump();
      expect(find.byKey(const ValueKey<String>("picker")), findsNothing);
      semantics.dispose();
    });

    testWidgets("a failure shows the default live error; a retry clears it", (
      WidgetTester tester,
    ) async {
      int calls = 0;
      int closes = 0;
      await _pump(
        tester,
        _sheet(
          onSubmit: (PolygonFormResult result) async {
            calls++;
            if (calls == 1) throw Exception("save failed");
          },
          onClose: () => closes++,
        ),
      );
      await _drawTriangle(tester);
      await _tapSubmit(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(_kSubmitError), findsOneWidget);
      expect(_liveRegionAround(_kSubmitError), findsOneWidget);
      expect(_submitEnabled(tester), isTrue);
      expect(find.text(_kSubmit), findsOneWidget);
      expect(closes, 0);

      await _tapSubmit(tester);
      expect(calls, 2);
      expect(find.text(_kSubmitError), findsNothing);
      expect(closes, 1);
    });

    testWidgets("submitErrorText and submitLabel replace the defaults", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _sheet(
          submitLabel: "Save area",
          submitErrorText: "Custom failure",
          onSubmit: (PolygonFormResult result) async =>
              throw Exception("save failed"),
        ),
      );
      expect(find.text("Save area"), findsOneWidget);
      expect(find.text(_kSubmit), findsNothing);

      await _drawTriangle(tester);
      await _tapSubmit(tester);
      expect(find.text("Custom failure"), findsOneWidget);
      expect(find.text(_kSubmitError), findsNothing);
    });
  });

  group("modal bottom sheet host", () {
    Future<void> openInSheet(
      WidgetTester tester, {
      required Future<void> Function(PolygonFormResult result) onSubmit,
      required VoidCallback onClosed,
    }) async {
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
                child: PolygonFormSheet(
                  title: _kTitle,
                  tileLayer: _tileLayer(),
                  onSubmit: onSubmit,
                  onClose: () {
                    onClosed();
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

    testWidgets("a successful submit closes the sheet through onClose", (
      WidgetTester tester,
    ) async {
      int closes = 0;
      await openInSheet(
        tester,
        onSubmit: _noopSubmit,
        onClosed: () => closes++,
      );
      await _drawTriangle(tester);
      await _tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(closes, 1);
      expect(find.byType(PolygonFormSheet), findsNothing);
      expect(find.text("open"), findsOneWidget);
    });

    testWidgets("dragging a vertex down moves it, not the sheet", (
      WidgetTester tester,
    ) async {
      await openInSheet(tester, onSubmit: _noopSubmit, onClosed: () {});
      await _drawTriangle(tester);
      final double sheetTop = tester.getTopLeft(
        find.byType(PolygonFormSheet),
      ).dy;

      final Offset start = _mapCenter(tester) + _kTriangle[0];
      final TestGesture gesture = await tester.startGesture(start);
      for (int i = 0; i < 12; i++) {
        await gesture.moveBy(const Offset(0, 5));
        await tester.pump();
      }

      // Checked before the release: a dragged sheet springs back after it.
      expect(tester.getTopLeft(find.byType(PolygonFormSheet)).dy, sheetTop);
      final Offset finger = start + const Offset(0, 60);
      expect((_handleCenters(tester)[0] - finger).distance, lessThan(1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byType(PolygonFormSheet), findsOneWidget);
    });

    testWidgets("a submit ending while the sheet closes skips onClose", (
      WidgetTester tester,
    ) async {
      final Completer<void> pending = Completer<void>();
      int closes = 0;
      await openInSheet(
        tester,
        onSubmit: (PolygonFormResult result) => pending.future,
        onClosed: () => closes++,
      );
      await _drawTriangle(tester);
      await _tapSubmit(tester);

      // Dismissed from outside (scrim, back) while the submit runs.
      Navigator.of(tester.element(find.byType(PolygonFormSheet))).pop();
      await tester.pump();
      pending.complete();
      await tester.pump();
      expect(closes, 0);

      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(PolygonFormSheet), findsNothing);
      // The page under the sheet was not popped.
      expect(find.text("open"), findsOneWidget);
    });
  });

  group("accessibility and theme", () {
    testWidgets("close, undo and reset have 48 dp targets", (
      WidgetTester tester,
    ) async {
      await _pump(tester, _sheet());
      await _tapMap(tester, _kTriangle[0]);

      final Size close = tester.getSize(
        find.ancestor(
          of: find.byIcon(Icons.close_rounded),
          matching: find.byType(InkResponse),
        ),
      );
      expect(close.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(close.height, greaterThanOrEqualTo(kMinTapTarget));
      for (final String label in <String>[_kUndo, _kReset]) {
        final Size size = tester.getSize(_toolButton(label));
        expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
        expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
      }
      expect(tester.getSize(_submitButton).height, greaterThanOrEqualTo(kMinTapTarget));
    });

    testWidgets("narrow width and 2x text: tools stack, nothing overflows", (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
            ),
            child: _sheet(),
          ),
        ),
        surfaceSize: const Size(360, 1000),
      );
      await tester.pump();
      await _drawTriangle(tester);

      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel(_kVertex), findsNWidgets(3));
      final Rect undo = tester.getRect(_toolButton(_kUndo));
      final Rect reset = tester.getRect(_toolButton(_kReset));
      expect(reset.top, greaterThanOrEqualTo(undo.bottom));
      expect(undo.right, lessThanOrEqualTo(360));
      expect(reset.right, lessThanOrEqualTo(360));
    });

    testWidgets("dark theme: overlays and counter use scheme tokens", (
      WidgetTester tester,
    ) async {
      final ThemeData theme = AppTheme.dark();
      final ColorScheme cs = theme.colorScheme;
      await _pump(tester, _sheet(withPicker: true), theme: theme);
      await _pick(tester, "a");

      BoxDecoration decorationAround(String text) {
        final DecoratedBox box = tester.widget<DecoratedBox>(
          find.ancestor(of: find.text(text), matching: find.byType(DecoratedBox)).first,
        );
        return box.decoration as BoxDecoration;
      }

      expect(decorationAround(_kDrawHint).color, cs.inverseSurface);
      await _tapMap(tester, _kTriangle[0]);
      expect(decorationAround(_kPointCount).color, cs.inverseSurface);
      await _tapMap(tester, _kTriangle[1]);
      await _tapMap(tester, _kTriangle[2]);
      expect(decorationAround(_kPointCount).color, cs.primary);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.check_rounded)).color,
        cs.onPrimary,
      );
      final Material card = tester.widget<Material>(
        find.ancestor(
          of: find.byType(EditableValueRow),
          matching: find.byType(Material),
        ).first,
      );
      expect(card.color, cs.surfaceContainerLowest);
      expect(tester.takeException(), isNull);
    });
  });
}
