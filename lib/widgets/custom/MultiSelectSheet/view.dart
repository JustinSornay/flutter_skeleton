// view.dart
//
// _ViewMixin — widget tree of MultiSelectSheet: the header, the checkbox list
// (or the empty state) and the confirm button, inside a SafeArea on a
// transparent Material.

part of "index.dart";

/// Maximum height of the checkbox list before it scrolls.
const double _listMaxHeight = 360;

/// Confirm button corner radius.
const double _buttonRadius = 10;

mixin _ViewMixin<K> {
  Widget render(BuildContext context, _MultiSelectSheetState<K> state) {
    final MultiSelectSheet<K> widget = state.widget;

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: kSectionGap,
            right: kSectionGap,
            top: kSectionGap,
            bottom: MediaQuery.viewInsetsOf(context).bottom + kDefaultPadding * 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _SheetHeader(title: widget.title, counter: _counterText(state)),
              const SizedBox(height: kDefaultPadding * 2),
              if (widget.options.isEmpty) _empty(context, widget) else Flexible(child: _list(state)),
              const SizedBox(height: kDefaultPadding * 2),
              _confirmButton(context, state),
            ],
          ),
        ),
      ),
    );
  }

  /// "count/max" when capped, "count" otherwise.
  String _counterText(_MultiSelectSheetState<K> state) {
    final String count = state.selected.length.toString();
    final int? max = state.widget.max;
    if (max == null) {
      return "custom.multi_select_sheet.counter".tr(namedArgs: <String, String>{"count": count});
    }
    return "custom.multi_select_sheet.counter_max".tr(
      namedArgs: <String, String>{"count": count, "max": max.toString()},
    );
  }

  /// Centred empty-state text.
  Widget _empty(BuildContext context, MultiSelectSheet<K> widget) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSectionGap),
      child: Text(
        widget.emptyLabel ?? "custom.multi_select_sheet.empty".tr(),
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  /// Checkbox rows separated by dividers, capped at [_listMaxHeight].
  Widget _list(_MultiSelectSheetState<K> state) {
    final List<ChoiceOption<K>> options = state.widget.options;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: _listMaxHeight),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: options.length,
        separatorBuilder: (BuildContext context, int index) => Divider(
          height: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        itemBuilder: (BuildContext context, int index) {
          final ChoiceOption<K> option = options[index];
          return _OptionRow<K>(
            option: option,
            isSelected: state.selected.contains(option.value),
            isDisabled: state.isDisabled(option),
            onToggle: state.toggle,
          );
        },
      ),
    );
  }

  /// Full-width confirm button, disabled while nothing is selected.
  Widget _confirmButton(BuildContext context, _MultiSelectSheetState<K> state) {
    final ThemeData theme = Theme.of(context);

    return FilledButton(
      onPressed: state.canConfirm ? state.confirm : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(kMinTapTarget),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(_buttonRadius)),
        ),
        textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      child: Text(state.widget.confirmLabel ?? "custom.multi_select_sheet.confirm".tr()),
    );
  }
}
