// view.dart
//
// _ViewMixin — widget tree of SingleSelectSheet: the header, a divider, the
// scrolling body (optional section label + radio rows), a divider and the
// action bar, inside a SafeArea on a transparent Material.

part of "index.dart";

/// Horizontal inset shared by the body and the action bar.
const double _sideInset = kDefaultPadding * 3;

mixin _ViewMixin<T extends Object> {
  Widget render(BuildContext context, _SingleSelectSheetState<T> state) {
    final SingleSelectSheet<T> widget = state.widget;

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SheetHeader(title: widget.title, onClose: state.cancel),
            const Divider(height: 1),
            Flexible(child: _body(context, state)),
            const Divider(height: 1),
            _ActionBar(
              cancelLabel: widget.cancelLabel ?? "custom.single_select_sheet.cancel".tr(),
              confirmLabel: widget.confirmLabel ?? "custom.single_select_sheet.confirm".tr(),
              onCancel: state.cancel,
              onConfirm: state.canConfirm ? state.confirm : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Optional section label, then one radio row per option.
  Widget _body(BuildContext context, _SingleSelectSheetState<T> state) {
    final ThemeData theme = Theme.of(context);
    final SingleSelectSheet<T> widget = state.widget;
    final String? sectionLabel = widget.sectionLabel;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        _sideInset,
        kDefaultPadding * 2,
        _sideInset,
        kDefaultPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (sectionLabel != null) ...<Widget>[
            Text(
              sectionLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: kDefaultPadding),
          ],
          for (final ChoiceOption<T> option in widget.options)
            _OptionRow<T>(
              option: option,
              isSelected: option.value == state.selected,
              onSelected: state.select,
            ),
        ],
      ),
    );
  }
}
