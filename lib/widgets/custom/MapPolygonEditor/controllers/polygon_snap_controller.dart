// polygon_snap_controller.dart
//
// Pure screen-space snapping maths for MapPolygonEditor: finds the vertex or
// edge a pointer snaps to. Works on projected screen offsets only (the view
// model converts with the map camera), so it is unit-tested without a map.

part of "../index.dart";

/// What a pointer snapped to.
@visibleForTesting
enum MapPolygonSnapKind { vertex, edge }

/// Result of [MapPolygonSnapController.snap].
@visibleForTesting
@immutable
final class MapPolygonSnap {
  /// Snapped to the vertex at [index], whose screen offset is [position].
  const MapPolygonSnap.vertex(this.index, this.position)
    : kind = MapPolygonSnapKind.vertex;

  /// Snapped to the edge `index → index + 1` (the closing edge is
  /// `last → 0`) at the screen offset [position].
  const MapPolygonSnap.edge(this.index, this.position)
    : kind = MapPolygonSnapKind.edge;

  final MapPolygonSnapKind kind;

  /// Vertex index, or index of the edge's first vertex.
  final int index;

  /// Snapped screen offset.
  final Offset position;

  /// Index a vertex inserted on this edge takes, so the winding order is kept.
  int get insertIndex => index + 1;

  @override
  bool operator ==(Object other) =>
      other is MapPolygonSnap &&
      other.kind == kind &&
      other.index == index &&
      other.position == position;

  @override
  int get hashCode => Object.hash(kind, index, position);
}

/// Snaps a pointer to the vertices or edges of a polygon, in screen space.
@visibleForTesting
final class MapPolygonSnapController {
  const MapPolygonSnapController({
    required this.vertexRadius,
    required this.edgeRadius,
  });

  /// Maximum pointer distance to a vertex, in logical pixels.
  final double vertexRadius;

  /// Maximum pointer distance to an edge, in logical pixels.
  final double edgeRadius;

  /// Snaps [pointer] to the first vertex within [vertexRadius], else to the
  /// closest edge within [edgeRadius], else returns null.
  ///
  /// [vertices] are screen offsets in polygon order. Two vertices make one
  /// edge; with 3 or more the closing edge (last → first) counts too.
  MapPolygonSnap? snap(Offset pointer, List<Offset> vertices) {
    return _snapToVertex(pointer, vertices) ?? _snapToEdge(pointer, vertices);
  }

  MapPolygonSnap? _snapToVertex(Offset pointer, List<Offset> vertices) {
    for (int i = 0; i < vertices.length; i++) {
      if ((pointer - vertices[i]).distance <= vertexRadius) {
        return MapPolygonSnap.vertex(i, vertices[i]);
      }
    }
    return null;
  }

  MapPolygonSnap? _snapToEdge(Offset pointer, List<Offset> vertices) {
    if (vertices.length < 2) return null;
    final int edgeCount = vertices.length >= 3 ? vertices.length : 1;
    MapPolygonSnap? best;
    double bestDistance = double.infinity;
    for (int i = 0; i < edgeCount; i++) {
      final Offset closest = closestPointOnSegment(
        pointer,
        vertices[i],
        vertices[(i + 1) % vertices.length],
      );
      final double distance = (pointer - closest).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = MapPolygonSnap.edge(i, closest);
      }
    }
    return bestDistance <= edgeRadius ? best : null;
  }

  /// Closest point to [point] on the segment [a]–[b].
  static Offset closestPointOnSegment(Offset point, Offset a, Offset b) {
    final Offset ab = b - a;
    final double lengthSquared = ab.distanceSquared;
    if (lengthSquared == 0) return a;
    final Offset ap = point - a;
    final double t = (ap.dx * ab.dx + ap.dy * ab.dy) / lengthSquared;
    return a + ab * t.clamp(0.0, 1.0);
  }
}
