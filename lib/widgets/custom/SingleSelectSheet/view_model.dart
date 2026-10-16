// view_model.dart
//
// _SingleSelectSheetState — the pending selection of SingleSelectSheet.
// Starts at initialValue when it is one of the options (none otherwise),
// moves on row taps, and is handed to onConfirm only when the confirm button
// is pressed.

part of "index.dart";

final class _SingleSelectSheetState<T extends Object> extends State<SingleSelectSheet<T>>
    with _ViewMixin<T> {
  /// Pending selection, or null when no row is checked.
  T? selected;

  /// True when the confirm button can emit a value.
  bool get canConfirm => selected != null;

  @override
  void initState() {
    super.initState();
    final T? initial = widget.initialValue;
    selected = widget.options.any((ChoiceOption<T> option) => option.value == initial) ? initial : null;
  }

  /// Moves the pending selection to [value].
  void select(T value) {
    if (value == selected) return;
    setState(() => selected = value);
  }

  /// Emits the pending selection.
  void confirm() {
    final T? value = selected;
    if (value == null) return;
    widget.onConfirm(value);
  }

  /// Leaves without emitting a value.
  void cancel() => widget.onCancel();

  @override
  Widget build(BuildContext context) => render(context, this);
}
