// view.dart
//
// Layout of SearchField: a kMinTapTarget-tall rounded box (fill
// cs.surfaceContainerHighest) whose border and glow animate on focus, holding
// the search icon or Loader, the borderless TextField and the clear button
// (widgets/clear_button.dart) or a trailing gap. ColorScheme tokens only.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, _SearchFieldState state) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final SearchField widget = state.widget;
    final bool focused = state._focused;
    final VoidCallback? onClear = widget.onClear;
    final TextStyle? textStyle = theme.textTheme.bodyMedium;
    final BorderRadius radius = BorderRadius.circular(kDefaultPadding);

    return AnimatedContainer(
      duration: resolveMotion(context, kMotionShort),
      curve: Curves.easeOut,
      height: kMinTapTarget,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: radius,
        boxShadow: focused
            ? <BoxShadow>[BoxShadow(color: cs.primary.withAlpha(20), blurRadius: 6)]
            : const <BoxShadow>[],
      ),
      // The border is painted in front so it does not inset the content: the
      // field and the clear button keep the full kMinTapTarget height.
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: focused ? cs.primary : cs.outlineVariant,
          width: focused ? 1 : 0.5,
        ),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: kDefaultPadding * 1.5),
          if (widget.loading)
            const Loader(size: 16)
          else
            Icon(Icons.search_rounded, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: kDefaultPadding),
          // A non-dense decoration keeps the TextField kMinInteractiveDimension
          // (48 dp) tall with the text centred, so its whole height is tappable.
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: state._focusNode,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              style: textStyle?.copyWith(color: cs.onSurface),
              cursorColor: cs.primary,
              decoration: InputDecoration(
                hintText: widget.hintText ?? "custom.search_field.hint".tr(),
                hintStyle: textStyle?.copyWith(color: cs.onSurfaceVariant),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (onClear != null && state._hasText)
            _ClearButton(onTap: onClear)
          else
            const SizedBox(width: kDefaultPadding),
        ],
      ),
    );
  }
}
