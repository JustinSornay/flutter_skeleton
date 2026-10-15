// view_model.dart
//
// _PolygonWizardSheetState — owns the polygon controller and the name text
// controller, the current step, the selections (plus the ids still
// resolving), the loaded suggestion rows (plus their loading flag), the
// imported suggestion and the submit lifecycle (LoadState: Idle, Loading,
// Loaded = locked after success, LoadError = inline error). Re-runs the
// crossing check on every vertex change. Step completeness comes from
// PolygonWizardRules. Every input handler checks [busy] itself: a tap that
// lands in the frame where a submit starts still holds its old callback.
// While busy, and while another step is shown, the drawing is held at the
// submitted vertices, or at those drawn when the polygon step was left.

part of "index.dart";

final class _PolygonWizardSheetState extends State<PolygonWizardSheet>
    with _ViewMixin {
  /// Vertices drawn on the map; rebuilds the sheet on every change.
  final MapPolygonEditorController polygon = MapPolygonEditorController();

  /// Text of the name step.
  final TextEditingController nameController = TextEditingController();

  /// Resolved selections, in pick order.
  final List<PolygonFormSelection> selections = <PolygonFormSelection>[];

  /// Ids whose [PolygonWizardSheet.loadSelection] is still running.
  final Set<String> pendingIds = <String>{};

  /// Index of the step shown.
  int step = 0;

  /// Whether two edges of the polygon cross or touch.
  bool edgesCross = false;

  /// Whether the last pick failed to resolve (inline error).
  bool selectionFailed = false;

  /// Rows returned by [PolygonWizardSheet.loadSuggestions].
  List<PolygonSuggestionGroup> loadedSuggestions =
      const <PolygonSuggestionGroup>[];

  /// Whether [PolygonWizardSheet.loadSuggestions] is still running.
  bool suggestionsLoading = false;

  /// Id of the suggestion whose polygon is loaded in the editor.
  String? importedId;

  /// Submit lifecycle: Idle, Loading, Loaded (succeeded, locked) or
  /// LoadError (inline error).
  LoadState<void> submission = const Idle<void>();

  /// Vertices the drawing is held at while [_drawingHeld]: those handed to
  /// the last [PolygonWizardSheet.onSubmit], or those drawn when the polygon
  /// step was left.
  List<LatLng> _heldPoints = const <LatLng>[];

  /// The step shown.
  PolygonWizardStep get currentStep => widget.steps[step];

  /// Whether the step shown is the last one (its button submits).
  bool get isLastStep => step == widget.steps.length - 1;

  /// True while a pick resolves.
  bool get resolving => pendingIds.isNotEmpty;

  /// Suggestion rows: the current [PolygonWizardSheet.suggestions], then the
  /// loaded ones.
  List<PolygonSuggestionGroup> get suggestionGroups => <PolygonSuggestionGroup>[
    ...widget.suggestions,
    ...loadedSuggestions,
  ];

  /// True while [PolygonWizardSheet.onSubmit] runs (the button shows a busy
  /// indicator).
  bool get submitting => submission is Loading<void>;

  /// True while [PolygonWizardSheet.onSubmit] runs and after it succeeded:
  /// the sheet ignores input.
  bool get busy => submitting || submission is Loaded<void>;

  /// True while the drawing must keep [_heldPoints]: while [busy], and while
  /// the polygon step is not the one shown.
  bool get _drawingHeld =>
      busy || currentStep.kind != PolygonWizardStepKind.polygon;

  /// Whether the drawing is a submittable polygon: 3 or more vertices and no
  /// crossing edges.
  bool get shapeValid => polygon.isClosedPolygon && !edgesCross;

  /// Ids of the resolved selections.
  Set<String> get selectedIds => <String>{
    for (final PolygonFormSelection selection in selections) selection.id,
  };

  /// Whether every step is complete.
  bool get canSubmit => widget.steps.every(
    (PolygonWizardStep candidate) => _isComplete(candidate.kind),
  );

  /// Whether the Next / Submit button is enabled.
  bool get canGoNext {
    if (busy || resolving) return false;
    return isLastStep ? canSubmit : _isComplete(currentStep.kind);
  }

  @override
  void initState() {
    super.initState();
    assert(() {
      final String? problem = PolygonWizardRules.stepsProblem(
        widget.steps,
        hasPicker: widget.pickerBuilder != null,
      );
      if (problem != null) throw AssertionError(problem);
      return true;
    }());
    step = PolygonWizardRules.initialStep(widget.steps, widget.initialName);
    nameController.text = widget.initialName ?? "";
    polygon.addListener(_onPolygonChanged);
    final Future<List<PolygonSuggestionGroup>> Function()? load =
        widget.loadSuggestions;
    if (load != null) {
      suggestionsLoading = true;
      unawaited(_loadSuggestions(load));
    }
  }

  @override
  void dispose() {
    polygon
      ..removeListener(_onPolygonChanged)
      ..dispose();
    nameController.dispose();
    super.dispose();
  }

  bool _isComplete(PolygonWizardStepKind kind) {
    return PolygonWizardRules.isComplete(
      kind,
      name: nameController.text,
      shapeValid: shapeValid,
      selectionCount: selections.length,
    );
  }

  void _onPolygonChanged() {
    if (!mounted) return;
    if (_drawingHeld && !listEquals(polygon.points, _heldPoints)) {
      // flutter_map delivers a map tap 250 ms after the finger lifts, and a
      // drag that started before the lock keeps its pointer: such a change
      // can still land after the submit captured the vertices, or after Next
      // left the step (the step cross-fade keeps the outgoing editor
      // mounted). Put the held polygon back (load() notifies again, with
      // equal points).
      polygon.load(_heldPoints);
      return;
    }
    setState(() {
      edgesCross = PolygonWizardRules.hasCrossingEdges(polygon.points);
      if (polygon.isEmpty) importedId = null;
    });
  }

  Future<void> _loadSuggestions(
    Future<List<PolygonSuggestionGroup>> Function() load,
  ) async {
    try {
      final List<PolygonSuggestionGroup> loaded = await load();
      if (!mounted) return;
      setState(() {
        loadedSuggestions = loaded;
        suggestionsLoading = false;
      });
    } catch (error) {
      Logger().w("PolygonWizardSheet.loadSuggestions: $error");
      if (!mounted) return;
      setState(() => suggestionsLoading = false);
    }
  }

  /// Removes the last vertex (the undo button).
  void undoVertex() {
    if (_drawingHeld) return;
    polygon.undo();
  }

  /// Removes every vertex (the reset button).
  void resetPolygon() {
    if (_drawingHeld) return;
    polygon.reset();
  }

  /// Rebuilds after the name field changed (Next gating).
  void onNameChanged(String _) => setState(() {});

  /// Imports [suggestion] into the editor, or clears the polygon when it is
  /// the imported one. Suggestions with fewer than 3 points are ignored.
  void toggleSuggestion(PolygonSuggestion suggestion) {
    if (_drawingHeld) return;
    if (importedId == suggestion.id) {
      polygon.reset();
      setState(() => importedId = null);
      return;
    }
    if (suggestion.points.length < 3) return;
    // load() replaces the vertices and fits the editor camera to them.
    polygon.load(suggestion.points);
    setState(() => importedId = suggestion.id);
  }

  bool _acceptsPick(String id) {
    if (busy || pendingIds.contains(id) || selectedIds.contains(id)) {
      return false;
    }
    // A single selection resolves one pick at a time.
    return widget.allowMultipleSelections || !resolving;
  }

  /// Resolves the id reported by the picker and adds (or, with a single
  /// selection, sets) the result.
  Future<void> onPicked(String id) async {
    final Future<PolygonFormSelection> Function(String id, LatLng centroid)?
    load = widget.loadSelection;
    if (load == null || !_acceptsPick(id)) return;
    final LatLng centroid = PolygonWizardRules.centroid(
      polygon.points,
      widget.initialCenter,
    );
    setState(() {
      pendingIds.add(id);
      selectionFailed = false;
    });
    try {
      final PolygonFormSelection picked = await load(id, centroid);
      if (!mounted) return;
      setState(() {
        pendingIds.remove(id);
        if (!widget.allowMultipleSelections) selections.clear();
        selections
          ..removeWhere((PolygonFormSelection s) => s.id == picked.id)
          ..add(picked);
      });
    } catch (error) {
      Logger().e("PolygonWizardSheet.onPicked: $error");
      if (!mounted) return;
      setState(() {
        pendingIds.remove(id);
        selectionFailed = true;
      });
    }
  }

  /// Removes the selection [id] (a chip's remove button).
  void removeSelection(String id) {
    if (busy) return;
    setState(
      () => selections.removeWhere((PolygonFormSelection s) => s.id == id),
    );
  }

  /// Clears the single selection and shows the picker again (the card tap).
  void clearSelections() {
    if (busy) return;
    setState(selections.clear);
  }

  /// Goes to the next step, or submits on the last one.
  void next() {
    if (!canGoNext) return;
    if (isLastStep) {
      unawaited(submit());
      return;
    }
    _goTo(step + 1);
  }

  /// Goes back one step.
  void back() {
    if (step == 0 || busy) return;
    _goTo(step - 1);
  }

  void _goTo(int index) {
    setState(() {
      // Leaving the polygon step: hold the drawing as it is now.
      if (currentStep.kind == PolygonWizardStepKind.polygon) {
        _heldPoints = polygon.points;
      }
      step = index;
      selectionFailed = false;
      if (submission.hasError) submission = const Idle<void>();
    });
    // The polygon step builds a fresh editor at initialCenter: ask it to fit
    // the existing polygon instead.
    if (widget.steps[index].kind == PolygonWizardStepKind.polygon &&
        polygon.isClosedPolygon) {
      polygon.load(polygon.points);
    }
  }

  /// Submits once every step is complete; see [PolygonWizardSheet.onSubmit].
  Future<void> submit() async {
    if (busy || !canSubmit) return;
    final List<PolygonFormSelection> picked =
        List<PolygonFormSelection>.unmodifiable(selections);
    final PolygonFormResult result = PolygonFormResult(
      selection: picked.firstOrNull,
      points: polygon.points,
      name: PolygonWizardRules.resolveName(
        nameController.text,
        picked,
        widget.fallbackName ?? "custom.polygon_wizard_sheet.default_name".tr(),
      ),
    );
    _heldPoints = result.points;
    setState(() => submission = const Loading<void>());
    try {
      await widget.onSubmit(result, picked);
    } catch (error) {
      Logger().e("PolygonWizardSheet.submit: $error");
      if (!mounted) return;
      setState(() => submission = const LoadError<void>());
      return;
    }
    if (!mounted) return;
    setState(() => submission = const Loaded<void>(null));
    // A route that is closing or covered must not make the host pop the
    // route above it.
    if (ModalRoute.of(context)?.isCurrent ?? true) widget.onSubmitted?.call();
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}
