// map_polygon_editor_test.dart
//
// Widget tests for MapPolygonEditor (lib/widgets/custom/MapPolygonEditor/):
// tap to add, mouse hover ghost (and its refresh after drags and host edits),
// edge insert (mouse and touch), vertex and handle-corner taps, vertex drag,
// camera fit (initial points, load, controller swap), controller swap and
// dispose, theming and handle states (light and dark), reduced motion and
// accessibility. Tiles come from an in-memory TileProvider, so no network is
// used.

import "dart:typed_data";

import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/MapPolygonEditor/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:latlong2/latlong.dart";

import "../../helpers/widget_test_helpers.dart";

const String _kLabelKey = "custom.map_polygon_editor.label";
const String _kHintKey = "custom.map_polygon_editor.hint";
const String _kVertexKey = "custom.map_polygon_editor.vertex";
const Size _kEditorSize = Size(400, 400);

/// Longer than flutter_map's 250 ms double-tap window, so a tap resolves.
const Duration _kTapSettle = Duration(milliseconds: 400);

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

/// A square of ±[half] degrees around [center].
List<LatLng> _square(LatLng center, double half) {
  return <LatLng>[
    LatLng(center.latitude + half, center.longitude - half),
    LatLng(center.latitude + half, center.longitude + half),
    LatLng(center.latitude - half, center.longitude + half),
    LatLng(center.latitude - half, center.longitude - half),
  ];
}

Widget _editor(MapPolygonEditorController controller) {
  return Center(
    child: SizedBox.fromSize(
      size: _kEditorSize,
      child: MapPolygonEditor(
        controller: controller,
        initialCenter: const LatLng(0, 0),
        tileLayer: TileLayer(
          urlTemplate: "https://tiles.example.test/{z}/{x}/{y}.png",
          userAgentPackageName: "com.example.test",
          tileProvider: _MemoryTileProvider(),
        ),
      ),
    ),
  );
}

/// Pumps the editor and lets the map become ready (post-frame callback).
Future<void> _pumpEditor(
  WidgetTester tester,
  MapPolygonEditorController controller, {
  ThemeData? theme,
  bool reduceMotion = false,
}) async {
  final Widget editor = _editor(controller);
  await pumpApp(
    tester,
    reduceMotion
        ? Builder(
            builder: (BuildContext context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: editor,
            ),
          )
        : editor,
    theme: theme,
  );
  await tester.pump();
  await tester.pump();
}

MapPolygonEditorController _controller([List<LatLng>? initialPoints]) {
  final MapPolygonEditorController controller = MapPolygonEditorController(
    initialPoints: initialPoints,
  );
  addTearDown(controller.dispose);
  return controller;
}

Finder _semanticsWithLabel(String label) {
  return find.byWidgetPredicate(
    (Widget widget) => widget is Semantics && widget.properties.label == label,
  );
}

Finder get _vertices => _semanticsWithLabel(_kVertexKey);

Offset _vertexAt(WidgetTester tester, int index) {
  return tester.getCenter(_vertices.at(index));
}

Rect _editorRect(WidgetTester tester) {
  return tester.getRect(find.byType(MapPolygonEditor));
}

int _markerLayerCount() => find.byType(MarkerLayer).evaluate().length;

/// The animated dot inside the handle of vertex [index].
AnimatedContainer _handleDot(WidgetTester tester, int index) {
  return tester.widget<AnimatedContainer>(
    find.descendant(
      of: _vertices.at(index),
      matching: find.byType(AnimatedContainer),
    ),
  );
}

/// Fill, border and size of the handle dot of vertex [index].
({Color? fill, BoxBorder? border, double size}) _handleStyle(
  WidgetTester tester,
  int index,
) {
  final AnimatedContainer dot = _handleDot(tester, index);
  final BoxDecoration decoration = dot.decoration! as BoxDecoration;
  return (
    fill: decoration.color,
    border: decoration.border,
    size: dot.constraints!.maxWidth,
  );
}

/// A mouse pointer parked outside the editor.
Future<TestGesture> _mouse(WidgetTester tester) async {
  final TestGesture mouse = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  return mouse;
}

void _expectSamePoint(LatLng actual, LatLng expected) {
  expect(actual.latitude, closeTo(expected.latitude, 0.02));
  expect(actual.longitude, closeTo(expected.longitude, 0.02));
}

void main() {
  group("drawing", () {
    testWidgets("a tap on an empty spot adds a vertex there", (
      WidgetTester tester,
    ) async {
      final MapPolygonEditorController controller = _controller();
      await _pumpEditor(tester, controller);
      expect(find.byType(PolygonLayer), findsNothing);

      await tester.tapAt(_editorRect(tester).center);
      await tester.pump(_kTapSettle);

      expect(controller.length, 1);
      expect(controller.points.single.latitude, closeTo(0, 0.05));
      expect(controller.points.single.longitude, closeTo(0, 0.05));
      expect(_vertices, findsOneWidget);
    });

    testWidgets("three taps close the polygon and draw its fill", (
      WidgetTester tester,
    ) async {
      final MapPolygonEditorController controller = _controller();
      await _pumpEditor(tester, controller);
      final Offset center = _editorRect(tester).center;

      for (final Offset offset in const <Offset>[
        Offset(-100, -80),
        Offset(100, -80),
      ]) {
        await tester.tapAt(center + offset);
        await tester.pump(_kTapSettle);
      }
      expect(controller.isClosedPolygon, isFalse);
      expect(find.byType(PolygonLayer), findsNothing);

      await tester.tapAt(center + const Offset(0, 100));
      await tester.pump(_kTapSettle);

      expect(controller.isClosedPolygon, isTrue);
      expect(find.byType(PolygonLayer), findsOneWidget);
      expect(_vertices, findsNWidgets(3));
    });
  });

  group("hover ghost", () {
    final List<LatLng> twoPoints = <LatLng>[
      const LatLng(1, -1),
      const LatLng(1, 1),
    ];
    // About 80 px apart at the initial zoom: hovering one never snaps to the
    // other.
    final List<LatLng> widePair = <LatLng>[
      const LatLng(0, -1.25),
      const LatLng(0, 1.25),
    ];

    testWidgets("with 2 vertices, hovering shows the ghost triangle and node", (
      WidgetTester tester,
    ) async {
      final MapPolygonEditorController controller = _controller(twoPoints);
      await _pumpEditor(tester, controller);
      expect(find.byType(PolygonLayer), findsNothing);
      expect(_markerLayerCount(), 1);

      final TestGesture mouse = await _mouse(tester);
      await mouse.moveTo(_editorRect(tester).center + const Offset(0, 80));
      await tester.pump();

      expect(find.byType(PolygonLayer), findsOneWidget);
      expect(_markerLayerCount(), 2);

      await mouse.moveTo(Offset.zero);
      await tester.pump();

      expect(find.byType(PolygonLayer), findsNothing);
      expect(_markerLayerCount(), 1);
    });

    testWidgets("the ghost stays hidden while a vertex is dragged", (
      WidgetTester tester,
    ) async {
      final MapPolygonEditorController controller = _controller(twoPoints);
      await _pumpEditor(tester, controller);
      final TestGesture mouse = await _mouse(tester);
      final Offset vertex = _vertexAt(tester, 0);

      await mouse.moveTo(vertex);
      await tester.pump();
      expect(_markerLayerCount(), 2);

      await mouse.down(vertex);
      await tester.pump();
      await mouse.moveBy(const Offset(4, 0));
      await tester.pump();

      expect(find.byType(PolygonLayer), findsNothing);
      expect(_markerLayerCount(), 1);

      await mouse.up();
      await tester.pump(_kTapSettle);
      expect(controller.length, 2);
    });

    testWidgets("with 3 or more vertices, hovering shows no ghost triangle", (
      WidgetTester tester,
    ) async {
      await _pumpEditor(tester, _controller(_square(const LatLng(0, 0), 2)));
      final TestGesture mouse = await _mouse(tester);

      await mouse.moveTo(_editorRect(tester).center);
      await tester.pump();

      expect(_markerLayerCount(), 2);
      expect(find.byType(PolygonLayer), findsOneWidget);
    });

    testWidgets("no ghost is left at a dragged vertex's old position", (
      WidgetTester tester,
    ) async {
      final MapPolygonEditorController controller = _controller(widePair);
      await _pumpEditor(tester, controller);
      final TestGesture mouse = await _mouse(tester);
      final Offset vertex = _vertexAt(tester, 0);
      await mouse.moveTo(vertex);
      await tester.pump();
      expect(find.byType(PolygonLayer), findsOneWidget);
      expect(_markerLayerCount(), 2);

      await mouse.down(vertex);
      await tester.pump();
      await mouse.moveBy(const Offset(0, 4));
      await tester.pump();
      await mouse.moveBy(const Offset(0, 56));
      await tester.pump();
      await mouse.up();
      await tester.pump(_kTapSettle);

      expect(controller.points.first, isNot(widePair.first));
      expect(find.byType(PolygonLayer), findsNothing);
      expect(_markerLayerCount(), 1);
    });

    testWidgets("a host edit while hovering recomputes the snap", (
      WidgetTester tester,
    ) async {
      final MapPolygonEditorController controller = _controller(widePair);
      await _pumpEditor(tester, controller);
      final TestGesture mouse = await _mouse(tester);
      await mouse.moveTo(_vertexAt(tester, 0));
      await tester.pump();
      expect(_handleStyle(tester, 0).size, 18);

      // The hovered vertex moves away from the pointer (e.g. a host command).
      controller.moveVertex(0, const LatLng(-1.25, -1.25));
      await tester.pump();

      expect(_handleStyle(tester, 0).size, 10);
      expect(_markerLayerCount(), 2);
    });
  });

  group("snapping", () {
    final List<LatLng> square = _square(const LatLng(0, 0), 2);

    Future<Offset> pumpSquare(
      WidgetTester tester,
      MapPolygonEditorController controller,
    ) async {
      await _pumpEditor(tester, controller);
      expect(_vertices, findsNWidgets(4));
      return Offset.lerp(_vertexAt(tester, 0), _vertexAt(tester, 1), 0.5)!;
    }

    void expectInsertedAtOne(MapPolygonEditorController controller) {
      final List<LatLng> points = controller.points;
      expect(points, hasLength(5));
      expect(<LatLng>[points[0], ...points.sublist(2)], square);
      _expectSamePoint(points[1], LatLng(square[0].latitude, 0));
    }

    testWidgets("a mouse click on an edge inserts a vertex in winding order", (
      WidgetTester tester,
    ) async {
      final MapPolygonEditorController controller = _controller(square);
      final Offset middle = await pumpSquare(tester, controller);
      final TestGesture mouse = await _mouse(tester);

      await mouse.moveTo(middle);
      await tester.pump();
      await mouse.down(middle);
      await mouse.up();
      await tester.pump(_kTapSettle);

      expectInsertedAtOne(controller);
    });

    testWidgets("a touch tap on an edge inserts a vertex in winding order", (
      WidgetTester tester,
    ) async {
      final MapPolygonEditorController controller = _controller(square);
      final Offset middle = await pumpSquare(tester, controller);

      await tester.tapAt(middle);
      await tester.pump(_kTapSettle);

      expectInsertedAtOne(controller);
    });

    testWidgets("a tap on a vertex never adds a point (touch and mouse)", (
      WidgetTester tester,
    ) async {
      final MapPolygonEditorController controller = _controller(square);
      await pumpSquare(tester, controller);

      await tester.tapAt(_vertexAt(tester, 2));
      await tester.pump(_kTapSettle);
      expect(controller.points, square);

      final TestGesture mouse = await _mouse(tester);
      final Offset vertex = _vertexAt(tester, 3);
      await mouse.moveTo(vertex);
      await tester.pump();
      await mouse.down(vertex);
      await mouse.up();
      await tester.pump(_kTapSettle);
      expect(controller.points, square);
    });

    testWidgets("a touch tap in a handle corner never adds a point", (
      WidgetTester tester,
    ) async {
      final MapPolygonEditorController controller = _controller(square);
      await pumpSquare(tester, controller);

      // Inside the 48 dp handle, about 28 px from its vertex.
      await tester.tapAt(_vertexAt(tester, 2) + const Offset(20, 20));
      await tester.pump(_kTapSettle);

      expect(controller.points, square);
    });

    testWidgets("a mouse click in a handle corner never adds a point", (
      WidgetTester tester,
    ) async {
      final MapPolygonEditorController controller = _controller(square);
      await pumpSquare(tester, controller);
      final TestGesture mouse = await _mouse(tester);
      final Offset corner = _vertexAt(tester, 3) + const Offset(-20, 20);

      await mouse.moveTo(corner);
      await tester.pump();
      await mouse.down(corner);
      await mouse.up();
      await tester.pump(_kTapSettle);

      expect(controller.points, square);
    });
  });

  testWidgets("dragging a vertex moves only that vertex, not the map", (
    WidgetTester tester,
  ) async {
    final List<LatLng> square = _square(const LatLng(0, 0), 2);
    final MapPolygonEditorController controller = _controller(square);
    await _pumpEditor(tester, controller);
    final List<Offset> before = <Offset>[
      for (int i = 0; i < 4; i++) _vertexAt(tester, i),
    ];

    final TestGesture finger = await tester.startGesture(before[0]);
    await tester.pump();
    await finger.moveBy(const Offset(5, 0));
    await tester.pump();
    await finger.moveBy(const Offset(25, 0));
    await tester.pump();
    await finger.up();
    await tester.pump(_kTapSettle);

    expect(controller.length, 4);
    expect(controller.points.sublist(1), square.sublist(1));
    expect(controller.points.first, isNot(square.first));
    final Offset moved = _vertexAt(tester, 0);
    expect(moved.dx, closeTo(before[0].dx + 30, 0.5));
    expect(moved.dy, closeTo(before[0].dy, 0.5));
    for (int i = 1; i < 4; i++) {
      expect(_vertexAt(tester, i), offsetMoreOrLessEquals(before[i]));
    }
  });

  group("camera fit", () {
    final List<LatLng> farSquare = _square(const LatLng(45, 90), 0.5);

    void expectAllVerticesVisible(WidgetTester tester) {
      expect(_vertices, findsNWidgets(4));
      final Rect rect = _editorRect(tester);
      for (int i = 0; i < 4; i++) {
        expect(rect.contains(_vertexAt(tester, i)), isTrue);
      }
    }

    testWidgets("load() fits the camera to the new polygon", (
      WidgetTester tester,
    ) async {
      final MapPolygonEditorController controller = _controller();
      await _pumpEditor(tester, controller);

      controller.load(farSquare);
      await tester.pump();
      await tester.pump();

      expectAllVerticesVisible(tester);
    });

    testWidgets("initialPoints are fitted once the map is ready", (
      WidgetTester tester,
    ) async {
      await _pumpEditor(tester, _controller(farSquare));

      expectAllVerticesVisible(tester);
    });

    testWidgets("a swapped-in controller with 3+ points is fitted", (
      WidgetTester tester,
    ) async {
      await _pumpEditor(tester, _controller());

      await _pumpEditor(tester, _controller(farSquare));

      expectAllVerticesVisible(tester);
    });

    testWidgets("plain edits never move the camera", (
      WidgetTester tester,
    ) async {
      final MapPolygonEditorController controller = _controller(
        _square(const LatLng(0, 0), 2),
      );
      await _pumpEditor(tester, controller);
      final Offset first = _vertexAt(tester, 0);

      controller.addPoint(const LatLng(0, 0));
      await tester.pump();
      await tester.pump();

      expect(_vertexAt(tester, 0), offsetMoreOrLessEquals(first));
    });
  });

  testWidgets("a new controller replaces the old one as the listened one", (
    WidgetTester tester,
  ) async {
    final MapPolygonEditorController first = _controller(<LatLng>[
      const LatLng(0, 0),
    ]);
    final MapPolygonEditorController second = _controller(<LatLng>[
      const LatLng(1, 1),
      const LatLng(-1, -1),
    ]);
    await _pumpEditor(tester, first);
    expect(_vertices, findsOneWidget);

    await _pumpEditor(tester, second);
    expect(_vertices, findsNWidgets(2));
    // Let the swap settle so a later scheduled frame comes from a listener.
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);

    first.addPoint(const LatLng(1, -1));
    expect(tester.binding.hasScheduledFrame, isFalse);

    second.addPoint(const LatLng(1, -1));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    expect(_vertices, findsNWidgets(3));
  });

  testWidgets("disposing the editor removes its controller listener", (
    WidgetTester tester,
  ) async {
    final MapPolygonEditorController controller = _controller();
    await _pumpEditor(tester, controller);
    // ignore: invalid_use_of_protected_member
    expect(controller.hasListeners, isTrue);

    await pumpApp(tester, const SizedBox.shrink());

    // ignore: invalid_use_of_protected_member
    expect(controller.hasListeners, isFalse);
  });

  group("theming", () {
    for (final (String name, ThemeData theme) in <(String, ThemeData)>[
      ("light", AppTheme.light()),
      ("dark", AppTheme.dark()),
    ]) {
      testWidgets("polygon and handles use cs.primary ($name)", (
        WidgetTester tester,
      ) async {
        final MapPolygonEditorController controller = _controller(
          _square(const LatLng(0, 0), 2),
        );
        await _pumpEditor(tester, controller, theme: theme);
        final ColorScheme cs = theme.colorScheme;

        final Polygon polygon = tester
            .widget<PolygonLayer>(find.byType(PolygonLayer))
            .polygons
            .single;
        expect(polygon.borderColor, cs.primary);
        expect(polygon.color, cs.primary.withValues(alpha: 0.18));

        final AnimatedContainer handle = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        expect((handle.decoration! as BoxDecoration).color, cs.primary);
      });

      testWidgets("snap-target and dragged handles change style ($name)", (
        WidgetTester tester,
      ) async {
        final MapPolygonEditorController controller = _controller(<LatLng>[
          const LatLng(0, -1.25),
          const LatLng(0, 1.25),
        ]);
        await _pumpEditor(tester, controller, theme: theme);
        final ColorScheme cs = theme.colorScheme;
        final TestGesture mouse = await _mouse(tester);
        final Offset vertex = _vertexAt(tester, 0);

        await mouse.moveTo(vertex);
        await tester.pump();
        expect(_handleStyle(tester, 0), (
          fill: cs.primary,
          border: Border.all(color: cs.onPrimary, width: 2),
          size: 18.0,
        ));
        expect(_handleStyle(tester, 1), (
          fill: cs.primary,
          border: null,
          size: 10.0,
        ));

        await mouse.down(vertex);
        await tester.pump();
        await mouse.moveBy(const Offset(4, 0));
        await tester.pump();
        expect(_handleStyle(tester, 0), (
          fill: cs.onPrimary,
          border: Border.all(color: cs.primary, width: 2.5),
          size: 22.0,
        ));

        await mouse.up();
        await tester.pump(_kTapSettle);
      });
    }
  });

  group("motion", () {
    testWidgets("handles animate for 150 ms by default", (
      WidgetTester tester,
    ) async {
      await _pumpEditor(tester, _controller(<LatLng>[const LatLng(0, 0)]));

      final AnimatedContainer handle = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(handle.duration, const Duration(milliseconds: 150));
    });

    testWidgets("handles do not animate under reduced motion", (
      WidgetTester tester,
    ) async {
      await _pumpEditor(
        tester,
        _controller(<LatLng>[const LatLng(0, 0)]),
        reduceMotion: true,
      );

      final AnimatedContainer handle = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(handle.duration, Duration.zero);
    });
  });

  testWidgets("exposes an editor label and hint, and 48 dp vertex handles", (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await _pumpEditor(tester, _controller(_square(const LatLng(0, 0), 2)));

    expect(
      tester.getSemantics(_semanticsWithLabel(_kLabelKey)),
      isSemantics(label: _kLabelKey, hint: _kHintKey),
    );
    expect(find.bySemanticsLabel(_kVertexKey), findsNWidgets(4));
    for (int i = 0; i < 4; i++) {
      final Size size = tester.getSize(_vertices.at(i));
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
    }
    semantics.dispose();
  });
}
