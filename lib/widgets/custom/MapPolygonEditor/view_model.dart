// view_model.dart
//
// State of MapPolygonEditor: hover / snap / drag bookkeeping, tap handling
// and camera fitting. Vertex changes go through MapPolygonEditorController;
// snapping maths come from MapPolygonSnapController.

part of "index.dart";

/// Vertex snap radius: half the diagonal of the 48 dp square handle (about
/// 34 px), so a tap anywhere on a handle, corners included, snaps to its
/// vertex instead of adding a point.
const double _kVertexSnapRadius = kMinTapTarget / math.sqrt2;
const double _kEdgeSnapRadius = 12;
const double _kFitPadding = kDefaultPadding * 4;
const double _kGhostNodeSize = 18;
const Duration _kVertexMotion = Duration(milliseconds: 150);

/// A snap with its map coordinate (the vertex itself, or the point on the
/// edge).
typedef _SnapTarget = ({MapPolygonSnap snap, LatLng point});

final class _MapPolygonEditorState extends State<MapPolygonEditor>
    with _ViewMixin {
  final MapController _mapController = MapController();
  final MapPolygonSnapController _snapper = const MapPolygonSnapController(
    vertexRadius: _kVertexSnapRadius,
    edgeRadius: _kEdgeSnapRadius,
  );
  bool _mapReady = false;

  // Hover and snap state (mouse only: touch never hovers). [_hoverOffset] is
  // the last pointer position in the editor, used to recompute the snap after
  // a host-driven edit.
  Offset? _hoverOffset;
  LatLng? _hoverPoint;
  _SnapTarget? _snapTarget;

  // Vertex drag state.
  int _draggingIndex = -1;
  Offset? _dragStartScreen;
  Offset _dragAccum = Offset.zero;

  MapPolygonEditorController get _controller => widget.controller;
  List<LatLng> get _points => _controller._points;
  bool get _isDragging => _draggingIndex >= 0;

  /// Where the next tap lands: the snap point, else the hovered point.
  LatLng? get _ghostPoint => _snapTarget?.point ?? _hoverPoint;

  bool _isSnapTarget(int index) {
    final MapPolygonSnap? snap = _snapTarget?.snap;
    return snap != null &&
        snap.kind == MapPolygonSnapKind.vertex &&
        snap.index == index;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(MapPolygonEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_onControllerChanged);
    widget.controller.addListener(_onControllerChanged);
    _clearHover();
    _clearDrag();
    // Fitting moves the map camera: wait until this build is over.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) _fitIfPending();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }

  // ── Camera ──────────────────────────────────────────────────────────────

  void _onMapReady() {
    _mapReady = true;
    _fitIfPending();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    _fitIfPending();
    setState(_refreshHover);
  }

  /// Uses up a fit requested by the controller (constructor or load()).
  void _fitIfPending() {
    if (!_mapReady || !_controller._pendingFit) return;
    _controller._pendingFit = false;
    if (_points.length < 3) return;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(_points),
        padding: const EdgeInsets.all(_kFitPadding),
      ),
    );
  }

  // ── Hover and snapping ──────────────────────────────────────────────────

  void _onHover(Offset position) {
    if (!_mapReady) return;
    final LatLng hoverPoint = _mapController.camera.offsetToCrs(position);
    final _SnapTarget? snapTarget = _snapAt(position);
    _hoverOffset = position;
    if (snapTarget == _snapTarget && hoverPoint == _hoverPoint) return;
    setState(() {
      _hoverPoint = hoverPoint;
      _snapTarget = snapTarget;
    });
  }

  void _onHoverExit() {
    _hoverOffset = null;
    if (_hoverPoint == null && _snapTarget == null) return;
    setState(_clearHover);
  }

  /// Recomputes the hover point and snap at the last pointer position after
  /// a vertex change (tap, undo, reset, load…), so the ghost never stays on
  /// a vertex that moved or no longer exists. Skipped during a drag, which
  /// hides the ghost anyway.
  void _refreshHover() {
    final Offset? position = _hoverOffset;
    if (_isDragging || position == null) return;
    _hoverPoint = _mapController.camera.offsetToCrs(position);
    _snapTarget = _snapAt(position);
  }

  void _clearHover() {
    _hoverOffset = null;
    _hoverPoint = null;
    _snapTarget = null;
  }

  _SnapTarget? _snapAt(Offset position) {
    final MapCamera camera = _mapController.camera;
    final MapPolygonSnap? snap = _snapper.snap(position, <Offset>[
      for (final LatLng point in _points) camera.latLngToScreenOffset(point),
    ]);
    if (snap == null) return null;
    final LatLng point = snap.kind == MapPolygonSnapKind.vertex
        ? _points[snap.index]
        : camera.offsetToCrs(snap.position);
    return (snap: snap, point: point);
  }

  // ── Mutations (delegated to the controller) ─────────────────────────────

  void _onMapTap(TapPosition position, LatLng point) {
    // Snap at the tap itself so touch (which never hovers) behaves like a
    // mouse: a tap on a vertex is ignored, a tap on an edge inserts.
    final Offset? relative = position.relative;
    final _SnapTarget? target = relative == null
        ? _snapTarget
        : _snapAt(relative);
    if (target == null) {
      _controller.addPoint(point);
    } else if (target.snap.kind == MapPolygonSnapKind.edge) {
      _controller.insertPoint(target.snap.insertIndex, target.point);
    }
  }

  void _startVertexDrag(int index) {
    // INTENTIONAL: no setState here. Rebuilding on pointer down changes the
    // map gestures and cancels the in-flight press (double-press bug).
    _draggingIndex = index;
    _dragStartScreen = _mapController.camera.latLngToScreenOffset(
      _points[index],
    );
    _dragAccum = Offset.zero;
  }

  void _updateVertexDrag(Offset delta) {
    final Offset? start = _dragStartScreen;
    if (!_isDragging || start == null) return;
    _dragAccum += delta;
    _controller.moveVertex(
      _draggingIndex,
      _mapController.camera.offsetToCrs(start + _dragAccum),
    );
  }

  void _endVertexDrag() {
    if (!_isDragging) return;
    // The mouse does not hover while a button is pressed, so the hover state
    // is stale (old vertex position): drop it until the next hover event.
    setState(() {
      _clearDrag();
      _clearHover();
    });
  }

  void _clearDrag() {
    _draggingIndex = -1;
    _dragStartScreen = null;
    _dragAccum = Offset.zero;
  }
}
