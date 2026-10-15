// view_model.dart
//
// Selection state of ComparisonPicker: the ids held by slot A and slot B,
// the locked-A mode flag and the toggle rules. Reports every change through
// ComparisonPicker.onChanged.

part of "index.dart";

/// The two comparison slots.
enum _Slot { a, b }

final class _ComparisonPickerState extends State<ComparisonPicker> with _ViewMixin {
  String? _slotA;
  String? _slotB;

  /// Exactly one primary item: slot A is locked to it and secondary rows
  /// toggle slot B.
  bool get _isLockedA => widget.primary.length == 1;

  @override
  void initState() {
    super.initState();
    _slotA = widget.initialSlotA;
    _slotB = widget.initialSlotB;
    if (_isLockedA && _slotA == null) {
      _slotA = widget.primary.first.id;
    }
  }

  /// The slot held by [id], or null.
  _Slot? _slotOf(String id) {
    if (_slotA == id) return _Slot.a;
    if (_slotB == id) return _Slot.b;
    return null;
  }

  /// Puts [id] in [slot], or empties [slot] when it already holds [id]. An
  /// item never holds both slots: the other slot is emptied if it held [id].
  void _toggle(_Slot slot, String id) {
    setState(() {
      switch (slot) {
        case _Slot.a:
          _slotA = _slotA == id ? null : id;
          if (_slotB == id) _slotB = null;
        case _Slot.b:
          _slotB = _slotB == id ? null : id;
          if (_slotA == id) _slotA = null;
      }
    });
    widget.onChanged(_slotA, _slotB);
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}
