// view.dart
//
// Layout of AutocompleteSearch: the SearchField wrapped in a TapRegion, a
// CompositedTransformTarget and an OverlayPortal, and the dropdown it shows:
// a Material card (elevation 4, radius 12, cs.surfaceContainerHigh) that
// follows the field's bottom-left corner and holds a live region with either
// the suggestion rows or the empty-result text. The dropdown sits in the
// field's TapRegion group and in a TextFieldTapRegion, so a tap inside it
// neither closes it nor takes focus from the field. ColorScheme tokens only.

part of "index.dart";

mixin _ViewMixin<T> {
  Widget render(BuildContext context, _AutocompleteSearchState<T> state) {
    return TapRegion(
      groupId: state._tapGroup,
      onTapOutside: state._onTapOutside,
      onTapInside: state._onTapInside,
      child: CompositedTransformTarget(
        link: state._link,
        child: OverlayPortal(
          controller: state._portal,
          overlayChildBuilder: (BuildContext overlayContext) =>
              renderDropdown(overlayContext, state),
          child: SearchField(
            controller: state._controller,
            hintText: state.widget.hintText ?? "custom.autocomplete_search.hint".tr(),
            onChanged: state._onQueryChanged,
            loading: state._isLoading,
          ),
        ),
      ),
    );
  }

  Widget renderDropdown(BuildContext context, _AutocompleteSearchState<T> state) {
    final AutocompleteSearch<T> widget = state.widget;
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Positioned(
      width: widget.dropdownWidth,
      child: CompositedTransformFollower(
        link: state._link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        offset: const Offset(0, kDefaultPadding),
        child: TapRegion(
          groupId: state._tapGroup,
          // Without it, the text field's own tap-outside handler unfocuses it
          // on desktop and web whenever the dropdown is tapped.
          child: TextFieldTapRegion(
            child: Material(
              elevation: 4,
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: widget.dropdownMaxHeight),
                child: state._results.isEmpty
                    ? _renderEmpty(context, state)
                    : _renderList(state),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _renderList(_AutocompleteSearchState<T> state) {
    final List<T> results = state._results;

    return Semantics(
      container: true,
      liveRegion: true,
      label: "custom.autocomplete_search.results".tr(
        namedArgs: <String, String>{"count": "${results.length}"},
      ),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: results.length,
        itemBuilder: (BuildContext context, int index) {
          final T item = results[index];
          return _SuggestionRow(
            onTap: () => state._select(item),
            child: state.widget.itemBuilder(context, item),
          );
        },
      ),
    );
  }

  Widget _renderEmpty(BuildContext context, _AutocompleteSearchState<T> state) {
    final ThemeData theme = Theme.of(context);

    return Semantics(
      container: true,
      liveRegion: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinTapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding * 1.5,
            vertical: kDefaultPadding,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            heightFactor: 1,
            child: Text(
              state.widget.noResultsText ?? "custom.autocomplete_search.no_results".tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
