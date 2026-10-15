// view.dart
//
// _ViewMixin — widget tree of OptionPickerSheet: the header title, then the
// option cards (widgets/option_card.dart) in a scroll view that takes the
// remaining height, padded on the 8 dp grid inside a SafeArea.

part of "index.dart";

mixin _ViewMixin<T> {
  Widget render(BuildContext context, OptionPickerSheet<T> widget) {
    final ThemeData theme = Theme.of(context);
    final T? selected = widget.selected;

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            kDefaultPadding * 3,
            kDefaultPadding * 3,
            kDefaultPadding * 3,
            kDefaultPadding * 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: kDefaultPadding * 2),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (final ChoiceOption<T> option in widget.options)
                        _OptionCard<T>(
                          option: option,
                          isSelected: selected != null && option.value == selected,
                          onSelected: widget.onSelected,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
