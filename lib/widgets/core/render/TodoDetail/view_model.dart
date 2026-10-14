// view_model.dart
//
// _TodoDetailState — fetch + toggle logic for TodoDetail.

part of "index.dart";

final class _TodoDetailState extends State<TodoDetail> with _ViewMixin {
  /// Lifecycle of the todo fetch.
  LoadState<TodoDetailOutput> todo = const Idle<TodoDetailOutput>();

  /// True while a PATCH is in flight — disables the switch.
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant TodoDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.todoId != widget.todoId) load();
  }

  /// (Re)loads the todo. Errors switch the view to its error state.
  Future<void> load() async {
    setState(() => todo = const Loading<TodoDetailOutput>());
    try {
      final TodoDetailOutput result = await (widget.getTodo ?? TodoService.get)(widget.todoId);
      if (!mounted) return;
      setState(() => todo = Loaded<TodoDetailOutput>(result));
    } catch (e) {
      Logger().e("TodoDetail.load: $e");
      if (!mounted) return;
      setState(() => todo = LoadError<TodoDetailOutput>(e is ApiException ? e.detail : null));
    }
  }

  /// Persists the completion flag. On failure the previous value is kept and
  /// a global error toast is shown.
  Future<void> setCompleted(bool completed) async {
    setState(() => isSaving = true);
    try {
      final TodoDetailOutput result = await (widget.patchTodo ?? TodoService.patch)(
        widget.todoId,
        TodoPatchInput(completed: completed),
      );
      if (!mounted) return;
      setState(() => todo = Loaded<TodoDetailOutput>(result));
    } catch (e) {
      Logger().e("TodoDetail.setCompleted: $e");
      if (!mounted) return;
      context.read<ErrorProvider>().show("error.save_failed".tr());
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}
