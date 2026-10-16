// view_model.dart
//
// _PolygonFormSheetState — owns the polygon controller and the name text
// controller; tracks the picked item and the submit lifecycle as
// LoadState values: selection (Idle = picker, Loading, Loaded, LoadError =
// picker with an error) and submission (Idle, Loading, Loaded = locked after
// success, LoadError = inline error). Re-runs hasCrossingEdges on every
// vertex change and remembers whether the form was shown, so it stays
// mounted behind the picker.

part of "index.dart";

final class _PolygonFormSheetState extends State<PolygonFormSheet>
    with _ViewMixin {
  /// Vertices drawn on the map; rebuilds the form on every change.
  final MapPolygonEditorController polygon = MapPolygonEditorController();

  /// Text of the optional name field.
  final TextEditingController nameController = TextEditingController();

  /// Picked item: Idle (nothing picked), Loading, Loaded or LoadError.
  LoadState<PolygonFormSelection> selection =
      const Idle<PolygonFormSelection>();

  /// Submit lifecycle: Idle, Loading, Loaded (succeeded, locked) or
  /// LoadError (inline error).
  LoadState<void> submission = const Idle<void>();

  /// Whether two edges of the polygon cross or touch.
  bool edgesCross = false;

  /// Whether the form was shown at least once (after the first pick). From
  /// then on it stays mounted behind the picker, keeping the map camera.
  bool formShown = false;

  /// Whether the sheet has a picker phase.
  bool get hasPicker => widget.pickerBuilder != null;

  /// Whether the picker fills the body (nothing picked, or the last pick
  /// failed to load).
  bool get showsPicker =>
      hasPicker &&
      (selection is Idle<PolygonFormSelection> ||
          selection is LoadError<PolygonFormSelection>);

  /// True while [PolygonFormSheet.onSubmit] runs and after it succeeded.
  bool get busy => submission is Loading<void> || submission is Loaded<void>;

  /// Whether the drawing is a submittable polygon: 3 or more vertices and
  /// no crossing edges.
  bool get shapeValid => polygon.isClosedPolygon && !edgesCross;

  /// Whether the submit button is enabled.
  bool get canSubmit =>
      !busy &&
      shapeValid &&
      (!hasPicker || selection is Loaded<PolygonFormSelection>);

  @override
  void initState() {
    super.initState();
    polygon.addListener(_onPolygonChanged);
  }

  @override
  void dispose() {
    polygon
      ..removeListener(_onPolygonChanged)
      ..dispose();
    nameController.dispose();
    super.dispose();
  }

  void _onPolygonChanged() {
    if (!mounted) return;
    setState(() {
      edgesCross = hasCrossingEdges(polygon.points);
    });
  }

  /// Resolves the id reported by the picker. Repeat picks are ignored while a
  /// load runs.
  Future<void> onPicked(String id) async {
    final Future<PolygonFormSelection> Function(String id)? load =
        widget.loadSelection;
    if (load == null || selection.isLoading) return;
    setState(() {
      formShown = true;
      selection = const Loading<PolygonFormSelection>();
    });
    try {
      final PolygonFormSelection picked = await load(id);
      if (!mounted) return;
      setState(() => selection = Loaded<PolygonFormSelection>(picked));
    } catch (error) {
      Logger().e("PolygonFormSheet.onPicked: $error");
      if (!mounted) return;
      setState(() => selection = const LoadError<PolygonFormSelection>());
    }
  }

  /// Goes back to the picker (the selection row's tap).
  void changeSelection() {
    if (busy) return;
    setState(() => selection = const Idle<PolygonFormSelection>());
  }

  /// Submits the polygon once; see [PolygonFormSheet.onSubmit].
  Future<void> submit() async {
    if (!canSubmit) return;
    final PolygonFormResult result = PolygonFormResult(
      selection: selection.dataOrNull,
      points: polygon.points,
      name: nameController.text.trim(),
    );
    setState(() => submission = const Loading<void>());
    try {
      await widget.onSubmit(result);
    } catch (error) {
      Logger().e("PolygonFormSheet.submit: $error");
      if (!mounted) return;
      setState(() => submission = const LoadError<void>());
      return;
    }
    if (!mounted) return;
    setState(() => submission = const Loaded<void>(null));
    // A route that is closing or covered must not make the host pop the
    // route above it.
    if (ModalRoute.of(context)?.isCurrent ?? true) widget.onClose();
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}
