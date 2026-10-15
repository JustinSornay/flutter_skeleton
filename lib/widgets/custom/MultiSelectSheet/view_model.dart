// view_model.dart
//
// _MultiSelectSheetState — the pending selection of MultiSelectSheet.
// Seeded from the initialSelection values that match an option (at most max
// of them), toggled by row taps within the optional cap,
// and handed to onConfirm only when the confirm button is pressed.

part of "index.dart";

final class _MultiSelectSheetState<K> extends State<MultiSelectSheet<K>> with _ViewMixin<K> {
  /// Pending selection, in insertion order.
  late final Set<K> selected;

  /// True when the cap is reached: unchecked rows are disabled.
  bool get isFull {
    final int? max = widget.max;
    return max != null && selected.length >= max;
  }

  /// True when the confirm button can emit a value.
  bool get canConfirm => selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final Set<K> known = widget.options.map((ChoiceOption<K> option) => option.value).toSet();
    final Iterable<K> kept = widget.initialSelection.where(known.contains);
    final int? max = widget.max;
    selected = Set<K>.of(max == null ? kept : kept.take(max));
  }

  /// True when [option] cannot be toggled.
  bool isDisabled(ChoiceOption<K> option) {
    if (!option.enabled) return true;
    return isFull && !selected.contains(option.value);
  }

  /// Checks or unchecks [option], unless it is disabled.
  void toggle(ChoiceOption<K> option) {
    if (isDisabled(option)) return;
    setState(() {
      if (!selected.remove(option.value)) selected.add(option.value);
    });
  }

  /// Emits a copy of the pending selection.
  void confirm() {
    if (!canConfirm) return;
    widget.onConfirm(Set<K>.of(selected));
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}
