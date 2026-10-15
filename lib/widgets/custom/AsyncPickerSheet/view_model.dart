// view_model.dart
//
// _AsyncPickerSheetState — submit lifecycle of AsyncPickerSheet as a
// LoadState<void>: Idle, Loading while onSubmit runs, LoadError(message)
// after a failure. Ignores picks while busy or once disposed (a late onPicked
// from the caller's body) and guards every update after an await with
// `mounted`.

part of "index.dart";

final class _AsyncPickerSheetState<T> extends State<AsyncPickerSheet<T>> with _ViewMixin<T> {
  /// Current submit state, rendered by the view with an exhaustive switch.
  LoadState<void> submission = const Idle<void>();

  /// True while [AsyncPickerSheet.onSubmit] runs.
  bool get busy => submission.isLoading;

  /// Submits [value] unless a submit is already running or the widget is gone.
  Future<void> pick(T value) async {
    if (!mounted || busy) return;
    setState(() => submission = const Loading<void>());
    try {
      await widget.onSubmit(value);
    } catch (error) {
      if (!mounted) return;
      setState(() => submission = LoadError<void>(_messageFor(error)));
      return;
    }
    if (!mounted) return;
    setState(() => submission = const Idle<void>());
    widget.onSubmitted(value);
  }

  String _messageFor(Object error) {
    return widget.errorMessage?.call(error) ?? "custom.async_picker_sheet.submit_failed".tr();
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}
