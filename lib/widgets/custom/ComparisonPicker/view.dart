// view.dart
//
// Tree of ComparisonPicker: the A / B header (radio mode), the primary rows,
// then the secondary section (dashed divider, add button, rows or loading
// placeholder). Picks each row's leading control from the mode.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, _ComparisonPickerState state) {
    final ComparisonPicker widget = state.widget;
    final VoidCallback? onAdd = widget.readOnly ? null : widget.onAdd;
    final bool showSecondary = widget.secondary.isNotEmpty || widget.secondaryLoading || onAdd != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (!state._isLockedA) _SlotHeader(label: widget.headerLabel),
        for (final ComparisonPickerItem item in widget.primary) _row(context, state, item, primary: true),
        if (showSecondary) ...<Widget>[
          const SizedBox(height: kDefaultPadding),
          _DashedDivider(label: widget.secondaryLabel ?? "custom.comparison_picker.secondary".tr()),
          const SizedBox(height: kDefaultPadding),
          if (onAdd != null)
            _AddButton(label: widget.addLabel ?? "custom.comparison_picker.add".tr(), onPressed: onAdd),
          if (widget.secondaryLoading)
            const _LoadingRows()
          else
            for (final ComparisonPickerItem item in widget.secondary) _row(context, state, item, primary: false),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, _ComparisonPickerState state, ComparisonPickerItem item, {required bool primary}) {
    final _Slot? selected = state._slotOf(item.id);
    if (!state._isLockedA) {
      return _PickerRow(
        item: item,
        selected: selected,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[_radio(state, item, _Slot.a, selected), _radio(state, item, _Slot.b, selected)],
        ),
      );
    }
    if (primary) {
      return _PickerRow(
        item: item,
        selected: selected,
        leading: _LockedSlotDot(itemLabel: item.label, locked: selected == _Slot.a),
      );
    }
    final bool isB = selected == _Slot.b;
    return _PickerRow(
      item: item,
      selected: selected,
      leading: _SlotDot(slot: _Slot.b, filled: isB),
      toggle: _RowToggle(
        semanticsLabel: _selectLabel(_Slot.b, item.label),
        checked: isB,
        onTap: state.widget.readOnly ? null : () => state._toggle(_Slot.b, item.id),
      ),
    );
  }

  /// Radio of [slot] on [item]'s row. Disabled in read-only mode and when
  /// the row already holds the other slot.
  Widget _radio(_ComparisonPickerState state, ComparisonPickerItem item, _Slot slot, _Slot? selected) {
    final bool blocked = state.widget.readOnly || (selected != null && selected != slot);
    return _SlotRadio(
      slot: slot,
      selected: selected == slot,
      semanticsLabel: _selectLabel(slot, item.label),
      onTap: blocked ? null : () => state._toggle(slot, item.id),
    );
  }

  String _selectLabel(_Slot slot, String itemLabel) {
    final Map<String, String> args = <String, String>{"label": itemLabel};
    return switch (slot) {
      _Slot.a => "custom.comparison_picker.select_a".tr(namedArgs: args),
      _Slot.b => "custom.comparison_picker.select_b".tr(namedArgs: args),
    };
  }
}
