// view.dart
//
// Render for MapPolygonEditor: a FlutterMap with the host tile layer, the
// live polygon, the ghost preview (mouse hover) and the draggable vertex
// handles (widgets/vertex_handle.dart, widgets/ghost_node.dart).

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, _MapPolygonEditorState state) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final MapPolygonEditor widget = state.widget;
    // A fresh copy per build: map layers may cache by polygon points.
    final List<LatLng> points = widget.controller.points;
    return Semantics(
      container: true,
      label: "custom.map_polygon_editor.label".tr(
        namedArgs: <String, String>{"count": "${points.length}"},
      ),
      hint: "custom.map_polygon_editor.hint".tr(),
      child: MouseRegion(
        onHover: (PointerHoverEvent event) =>
            state._onHover(event.localPosition),
        onExit: (PointerExitEvent event) => state._onHoverExit(),
        child: FlutterMap(
          mapController: state._mapController,
          options: _mapOptions(cs, state),
          children: <Widget>[
            widget.tileLayer,
            ..._shapeLayers(cs, state, points),
            if (points.isNotEmpty) _vertexLayer(state, points),
            ?widget.attribution,
          ],
        ),
      ),
    );
  }

  MapOptions _mapOptions(ColorScheme cs, _MapPolygonEditorState state) {
    final MapPolygonEditor widget = state.widget;
    return MapOptions(
      initialCenter: widget.initialCenter,
      initialZoom: widget.initialZoom,
      minZoom: widget.minZoom,
      maxZoom: widget.maxZoom,
      backgroundColor: cs.surfaceContainerHighest,
      onMapReady: state._onMapReady,
      onTap: state._onMapTap,
      // No map pan while a vertex is dragged, so the pan recognizer does not
      // compete with the handle's raw pointer listener.
      interactionOptions: InteractionOptions(
        flags: state._isDragging
            ? InteractiveFlag.all & ~InteractiveFlag.drag
            : InteractiveFlag.all,
      ),
    );
  }

  /// Polygon fill, ghost triangle (exactly 2 vertices) and ghost node.
  List<Widget> _shapeLayers(
    ColorScheme cs,
    _MapPolygonEditorState state,
    List<LatLng> points,
  ) {
    final LatLng? ghost = state._isDragging ? null : state._ghostPoint;
    return <Widget>[
      if (points.length >= 3)
        PolygonLayer(
          polygons: <Polygon>[
            Polygon(
              points: points,
              color: cs.primary.withValues(alpha: 0.18),
              borderColor: cs.primary,
              borderStrokeWidth: 2,
            ),
          ],
        ),
      if (points.length == 2 && ghost != null)
        PolygonLayer(
          polygons: <Polygon>[
            Polygon(
              points: <LatLng>[...points, ghost],
              color: cs.primary.withValues(alpha: 0.10),
              borderColor: cs.primary.withValues(alpha: 0.45),
              borderStrokeWidth: 1.5,
            ),
          ],
        ),
      if (ghost != null)
        MarkerLayer(
          markers: <Marker>[
            Marker(
              point: ghost,
              width: _kGhostNodeSize,
              height: _kGhostNodeSize,
              child: const _GhostNode(),
            ),
          ],
        ),
    ];
  }

  Widget _vertexLayer(_MapPolygonEditorState state, List<LatLng> points) {
    return MarkerLayer(
      markers: <Marker>[
        for (int i = 0; i < points.length; i++)
          Marker(
            point: points[i],
            width: kMinTapTarget,
            height: kMinTapTarget,
            child: _VertexHandle(
              index: i,
              isDragging: state._draggingIndex == i,
              isSnapTarget: state._isSnapTarget(i),
              onDragStart: () => state._startVertexDrag(i),
              onDragUpdate: state._updateVertexDrag,
              onDragEnd: state._endVertexDrag,
            ),
          ),
      ],
    );
  }
}
