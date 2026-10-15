// view_model.dart
//
// _PolygonEditorPanelState — owns the MapPolygonEditorController (seeded
// once from initialPoints) and the save lifecycle as a LoadState<void>:
// Idle, Loading (Loader shown, repeat saves ignored), Loaded or LoadError
// (button back, host told through onSaved / onSaveError).

part of "index.dart";

final class _PolygonEditorPanelState extends State<PolygonEditorPanel>
    with _ViewMixin {
  /// Vertices drawn on the map; rebuilds the panel on every change.
  late final MapPolygonEditorController polygon;

  /// Save lifecycle: Idle, Loading, Loaded or LoadError.
  LoadState<void> saveState = const Idle<void>();

  /// Whether the vertices form a polygon that can be saved.
  bool get canSave => polygon.isClosedPolygon;

  @override
  void initState() {
    super.initState();
    polygon = MapPolygonEditorController(initialPoints: widget.initialPoints)
      ..addListener(_onPolygonChanged);
  }

  @override
  void dispose() {
    polygon
      ..removeListener(_onPolygonChanged)
      ..dispose();
    super.dispose();
  }

  void _onPolygonChanged() {
    if (mounted) setState(() {});
  }

  /// Saves the current vertices once; see [PolygonEditorPanel.onSave].
  Future<void> save() async {
    if (!canSave || saveState.isLoading) return;
    final List<LatLng> points = polygon.points;
    setState(() => saveState = const Loading<void>());
    try {
      await widget.onSave(points);
    } catch (error) {
      if (!mounted) return;
      setState(() => saveState = const LoadError<void>());
      widget.onSaveError(error);
      return;
    }
    if (!mounted) return;
    setState(() => saveState = const Loaded<void>(null));
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}
