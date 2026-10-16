// map_polygon_editor_controller_test.dart
//
// Unit tests for the pure parts of MapPolygonEditor
// (lib/widgets/custom/MapPolygonEditor/): MapPolygonEditorController (vertex
// commands and notifications) and MapPolygonSnapController (screen-space
// vertex / edge snapping maths).

import "package:flutter_skeleton/widgets/custom/MapPolygonEditor/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:latlong2/latlong.dart";

const LatLng _a = LatLng(0, 0);
const LatLng _b = LatLng(0, 1);
const LatLng _c = LatLng(1, 1);
const LatLng _d = LatLng(1, 0);

/// Builds a controller and counts its notifications.
({MapPolygonEditorController controller, List<int> notified}) _counted([
  List<LatLng>? initialPoints,
]) {
  final MapPolygonEditorController controller = MapPolygonEditorController(
    initialPoints: initialPoints,
  );
  final List<int> notified = <int>[0];
  controller.addListener(() => notified[0]++);
  addTearDown(controller.dispose);
  return (controller: controller, notified: notified);
}

void main() {
  group("MapPolygonEditorController", () {
    test("starts empty, or with a copy of initialPoints", () {
      expect(MapPolygonEditorController().isEmpty, isTrue);
      final List<LatLng> source = <LatLng>[_a, _b];
      final MapPolygonEditorController controller = MapPolygonEditorController(
        initialPoints: source,
      );
      source.add(_c);
      expect(controller.points, <LatLng>[_a, _b]);
      expect(controller.length, 2);
    });

    test("addPoint appends in order and notifies once each", () {
      final (:MapPolygonEditorController controller, :List<int> notified) =
          _counted();
      controller
        ..addPoint(_a)
        ..addPoint(_b);
      expect(controller.points, <LatLng>[_a, _b]);
      expect(notified.single, 2);
    });

    test("insertPoint inserts at the index and notifies", () {
      final (:MapPolygonEditorController controller, :List<int> notified) =
          _counted(<LatLng>[_a, _c]);
      controller.insertPoint(1, _b);
      expect(controller.points, <LatLng>[_a, _b, _c]);
      expect(notified.single, 1);
    });

    test("moveVertex replaces one vertex; out of range is a no-op", () {
      final (:MapPolygonEditorController controller, :List<int> notified) =
          _counted(<LatLng>[_a, _b]);
      controller.moveVertex(1, _c);
      expect(controller.points, <LatLng>[_a, _c]);
      expect(notified.single, 1);

      controller
        ..moveVertex(-1, _d)
        ..moveVertex(2, _d);
      expect(controller.points, <LatLng>[_a, _c]);
      expect(notified.single, 1);
    });

    test("undo removes the last vertex; no notification when empty", () {
      final (:MapPolygonEditorController controller, :List<int> notified) =
          _counted(<LatLng>[_a, _b]);
      controller.undo();
      expect(controller.points, <LatLng>[_a]);
      controller
        ..undo()
        ..undo();
      expect(controller.isEmpty, isTrue);
      expect(notified.single, 2);
    });

    test("reset clears every vertex; no notification when empty", () {
      final (:MapPolygonEditorController controller, :List<int> notified) =
          _counted(<LatLng>[_a, _b, _c]);
      controller
        ..reset()
        ..reset();
      expect(controller.isEmpty, isTrue);
      expect(notified.single, 1);
    });

    test("load replaces with a copy of its input and notifies", () {
      final (:MapPolygonEditorController controller, :List<int> notified) =
          _counted(<LatLng>[_a]);
      final List<LatLng> source = <LatLng>[_b, _c, _d];
      controller.load(source);
      source.clear();
      expect(controller.points, <LatLng>[_b, _c, _d]);
      expect(notified.single, 1);
    });

    test("points is unmodifiable", () {
      final MapPolygonEditorController controller = MapPolygonEditorController(
        initialPoints: <LatLng>[_a],
      );
      expect(() => controller.points.add(_b), throwsUnsupportedError);
    });

    test("isClosedPolygon flips at 3 vertices", () {
      final MapPolygonEditorController controller = MapPolygonEditorController(
        initialPoints: <LatLng>[_a, _b],
      );
      expect(controller.isClosedPolygon, isFalse);
      controller.addPoint(_c);
      expect(controller.isClosedPolygon, isTrue);
      controller.undo();
      expect(controller.isClosedPolygon, isFalse);
    });
  });

  group("MapPolygonSnapController", () {
    const MapPolygonSnapController snapper = MapPolygonSnapController(
      vertexRadius: 24,
      edgeRadius: 12,
    );
    const List<Offset> square = <Offset>[
      Offset.zero,
      Offset(100, 0),
      Offset(100, 100),
      Offset(0, 100),
    ];

    test("no vertex: never snaps", () {
      expect(snapper.snap(Offset.zero, const <Offset>[]), isNull);
    });

    test("snaps to a vertex within the vertex radius", () {
      expect(
        snapper.snap(const Offset(110, 15), square),
        const MapPolygonSnap.vertex(1, Offset(100, 0)),
      );
      expect(snapper.snap(const Offset(130, 0), square), isNull);
    });

    test("a vertex wins over an edge", () {
      final MapPolygonSnap? snap = snapper.snap(const Offset(20, 2), square);
      expect(snap?.kind, MapPolygonSnapKind.vertex);
      expect(snap?.index, 0);
    });

    test("snaps to the closest edge within the edge radius", () {
      const MapPolygonSnap expected = MapPolygonSnap.edge(1, Offset(100, 50));
      expect(snapper.snap(const Offset(108, 50), square), expected);
      expect(expected.insertIndex, 2);
      expect(snapper.snap(const Offset(50, 50), square), isNull);
    });

    test("the closing edge (last → first) inserts at the end", () {
      final MapPolygonSnap? snap = snapper.snap(const Offset(-5, 50), square);
      expect(snap, const MapPolygonSnap.edge(3, Offset(0, 50)));
      expect(snap?.insertIndex, 4);
    });

    test("two vertices make a single edge, without a closing edge", () {
      const List<Offset> segment = <Offset>[Offset.zero, Offset(100, 0)];
      expect(
        snapper.snap(const Offset(50, 6), segment),
        const MapPolygonSnap.edge(0, Offset(50, 0)),
      );
      final MapPolygonSnap? single = snapper.snap(
        const Offset(50, 6),
        const <Offset>[Offset.zero],
      );
      expect(single, isNull);
    });

    test("closestPointOnSegment clamps to the ends", () {
      const Offset a = Offset.zero;
      const Offset b = Offset(10, 0);
      expect(
        MapPolygonSnapController.closestPointOnSegment(
          const Offset(5, 3),
          a,
          b,
        ),
        const Offset(5, 0),
      );
      expect(
        MapPolygonSnapController.closestPointOnSegment(
          const Offset(-4, 3),
          a,
          b,
        ),
        a,
      );
      expect(
        MapPolygonSnapController.closestPointOnSegment(
          const Offset(14, 3),
          a,
          b,
        ),
        b,
      );
      expect(
        MapPolygonSnapController.closestPointOnSegment(
          const Offset(3, 3),
          a,
          a,
        ),
        a,
      );
    });
  });
}
