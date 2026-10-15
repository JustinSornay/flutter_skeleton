// view_model.dart
//
// _EditFieldsSheetState — one TextEditingController per field id (kept
// across rebuilds, created / disposed when the field set changes), dirty
// detection against each initialValue, and the save lifecycle as a
// LoadState<void>: Idle, Loading while onSubmit runs, LoadError(message)
// after a failure.

part of "index.dart";

final class _EditFieldsSheetState extends State<EditFieldsSheet> with _ViewMixin {
  final Map<String, TextEditingController> _controllers = <String, TextEditingController>{};

  /// Notifies on every edit of any field; drives the save button's state.
  late Listenable textChanges;

  /// Current save state, rendered by the view with an exhaustive switch.
  LoadState<void> submission = const Idle<void>();

  /// True while [EditFieldsSheet.onSubmit] runs.
  bool get busy => submission.isLoading;

  /// True when at least one field's text differs from its initial value.
  bool get isDirty => widget.fields.any(
    (EditSheetField field) => controllerFor(field).text != field.initialValue,
  );

  /// Text controller of [field].
  TextEditingController controllerFor(EditSheetField field) => _controllers[field.id]!;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(EditFieldsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  /// Keeps exactly one controller per current field id: new ids are seeded
  /// with their initial value, removed ids are disposed.
  void _syncControllers() {
    final Set<String> ids = <String>{
      for (final EditSheetField field in widget.fields) field.id,
    };
    assert(ids.length == widget.fields.length, "EditSheetField ids must be unique.");
    _controllers.removeWhere((String id, TextEditingController controller) {
      if (ids.contains(id)) return false;
      controller.dispose();
      return true;
    });
    for (final EditSheetField field in widget.fields) {
      _controllers.putIfAbsent(
        field.id,
        () => TextEditingController(text: field.initialValue),
      );
    }
    textChanges = Listenable.merge(_controllers.values.toList());
  }

  /// Every field's trimmed text keyed by id.
  Map<String, String> _values() {
    return <String, String>{
      for (final EditSheetField field in widget.fields) field.id: controllerFor(field).text.trim(),
    };
  }

  /// Submits the values unless nothing changed or a save is already running.
  Future<void> save() async {
    if (busy || !isDirty) return;
    final Map<String, String> values = _values();
    setState(() => submission = const Loading<void>());
    try {
      await widget.onSubmit(values);
    } catch (error) {
      if (!mounted) return;
      setState(() => submission = LoadError<void>(_messageFor(error)));
      return;
    }
    if (!mounted) return;
    setState(() => submission = const Idle<void>());
    widget.onSaved(values);
  }

  String _messageFor(Object error) {
    return widget.errorMessage?.call(error) ?? "custom.edit_fields_sheet.save_failed".tr();
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}
