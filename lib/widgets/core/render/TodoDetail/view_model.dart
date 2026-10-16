// view_model.dart
//
// _TodoDetailState — local UI state for TodoDetail (load state, busy flag).
// Calls and their feedback are delegated to TodoController.

part of "index.dart";

final class _TodoDetailState extends State<TodoDetail> with _ViewMixin {
  /// Lifecycle of the todo fetch.
  LoadState<TodoDetailOutput> todo = const Idle<TodoDetailOutput>();

  /// True while a PATCH or DELETE is in flight — disables the actions.
  bool isSaving = false;

  TodoController get _controller => widget.controller ?? const TodoController();

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
    final LoadState<TodoDetailOutput> result = await _controller.load(context, widget.todoId);
    if (mounted) setState(() => todo = result);
  }

  /// Persists the completion flag. On failure the previous value is kept.
  Future<void> setCompleted(bool completed) async {
    setState(() => isSaving = true);
    final TodoDetailOutput? result = await _controller.setCompleted(context, widget.todoId, completed);
    if (!mounted) return;
    setState(() {
      isSaving = false;
      if (result != null) todo = Loaded<TodoDetailOutput>(result);
    });
  }

  /// Deletes the todo after confirmation; the controller redirects on success.
  Future<void> delete() async {
    setState(() => isSaving = true);
    await _controller.delete(context, widget.todoId);
    if (mounted) setState(() => isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}
