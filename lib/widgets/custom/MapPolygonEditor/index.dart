// index.dart
//
// MapPolygonEditor — a chrome-less map widget for drawing and editing one
// polygon: tap to add vertices, mouse hover ghost preview, vertex / edge
// snapping with a winding-preserving edge insert, draggable vertices.
//
// State lives in the host-owned MapPolygonEditorController (declared here);
// the host composes its own counter, undo / reset / save chrome around the
// editor. Snapping maths: controllers/polygon_snap_controller.dart. Vertex
// handle and ghost node: widgets/.

import "dart:math" as math;

import "package:easy_localization/easy_localization.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:latlong2/latlong.dart";

part "controllers/polygon_snap_controller.dart";
part "view_model.dart";
part "view.dart";
part "widgets/ghost_node.dart";
part "widgets/vertex_handle.dart";

/// Holds the vertices of the polygon being edited and the commands that
/// change them.
///
/// The host owns it (creates and disposes it), reads [points] for validation
/// or submission, and calls [undo] / [reset] / [load] from its own toolbar.
/// Every real change notifies listeners.
final class MapPolygonEditorController extends ChangeNotifier {
  /// Starts with a copy of [initialPoints]. With 3 or more points the editor
  /// fits the camera to them once its map is ready.
  MapPolygonEditorController({List<LatLng>? initialPoints})
    : _points = List<LatLng>.of(initialPoints ?? const <LatLng>[]),
      _pendingFit = (initialPoints?.length ?? 0) >= 3;

  List<LatLng> _points;

  // Set by the constructor and [load]; the editor uses it up by fitting the
  // camera to the polygon. Plain edits never move the camera.
  bool _pendingFit;

  /// Current vertices in polygon order (unmodifiable copy).
  List<LatLng> get points => List<LatLng>.unmodifiable(_points);

  /// Number of vertices.
  int get length => _points.length;

  /// Whether there is no vertex yet.
  bool get isEmpty => _points.isEmpty;

  /// Whether the vertices form a polygon (3 or more).
  bool get isClosedPolygon => _points.length >= 3;

  /// Replaces every vertex with a copy of [points] (e.g. an existing
  /// boundary) and, with 3 or more points, asks the editor to fit the camera.
  void load(List<LatLng> points) {
    _points = List<LatLng>.of(points);
    _pendingFit = _points.length >= 3;
    notifyListeners();
  }

  /// Appends [point] as the last vertex.
  void addPoint(LatLng point) {
    _points.add(point);
    notifyListeners();
  }

  /// Inserts [point] at [index] (0 ≤ index ≤ [length]).
  void insertPoint(int index, LatLng point) {
    _points.insert(index, point);
    notifyListeners();
  }

  /// Moves the vertex at [index] to [point]. Out-of-range indexes are ignored.
  void moveVertex(int index, LatLng point) {
    if (index < 0 || index >= _points.length) return;
    _points[index] = point;
    notifyListeners();
  }

  /// Removes the last vertex. Does nothing (no notification) when empty.
  void undo() {
    if (_points.isEmpty) return;
    _points.removeLast();
    notifyListeners();
  }

  /// Removes every vertex. Does nothing (no notification) when empty.
  void reset() {
    if (_points.isEmpty) return;
    _points.clear();
    notifyListeners();
  }
}

/// Interactive map editor for one polygon, driven by [controller].
///
/// - Tap the map to append a vertex.
/// - With a mouse, a ghost node shows where the next tap lands; with exactly
///   two vertices a ghost triangle previews the shape.
/// - The pointer snaps to a vertex (anywhere on its 48 dp handle) or an edge
///   (12 px). A tap on an edge inserts a vertex there (winding order kept); a
///   tap on a vertex handle is ignored, touch and mouse alike.
/// - Vertices are dragged directly; the map does not pan during a drag.
/// - [MapPolygonEditorController.load] fits the camera to the polygon, and so
///   does a controller created with 3 or more `initialPoints`.
///
/// The widget has no chrome (counter, undo / reset, save, hint): the host
/// stacks those around it and drives [controller]. Tiles come from
/// [tileLayer], so the host owns the tile URL, user agent and caching; pass
/// the attribution the tile source requires as [attribution].
///
/// Uses no Tooltip or other overlay: it needs no `Overlay` ancestor.
final class MapPolygonEditor extends StatefulWidget {
  /// Host-owned vertex state; the editor listens to it.
  final MapPolygonEditorController controller;

  /// Base map tiles (first map layer).
  final TileLayer tileLayer;

  /// Camera centre before any fit.
  final LatLng initialCenter;

  /// Camera zoom before any fit.
  final double initialZoom;

  /// Lowest zoom the camera allows.
  final double minZoom;

  /// Highest zoom the camera allows (fits included).
  final double maxZoom;

  /// Optional last map layer, e.g. a `SimpleAttributionWidget`.
  final Widget? attribution;

  const MapPolygonEditor({
    super.key,
    required this.controller,
    required this.tileLayer,
    required this.initialCenter,
    this.initialZoom = 5.5,
    this.minZoom = 4,
    this.maxZoom = 18,
    this.attribution,
  });

  @override
  State<MapPolygonEditor> createState() => _MapPolygonEditorState();
}
