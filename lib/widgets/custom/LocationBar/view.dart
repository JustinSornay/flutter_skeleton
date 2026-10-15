// view.dart
//
// Layout of LocationBar: an AnimatedSwitcher (150 ms through resolveMotion,
// easeOutCubic) between the search layout (empty and editing modes, which
// share the same field so it keeps its text and focus) and the selected row
// (EditableValueRow in an InkWell). The field is an AutocompleteSearch whose
// dropdown matches the field width. ColorScheme tokens only.

part of "index.dart";

/// Horizontal inset of the bar's content and dividers.
const double _kSideInset = kDefaultPadding * 2;

/// Cross-fade between the search layout and the selected row.
const Duration _kSwitchDuration = Duration(milliseconds: 150);

mixin _ViewMixin<T> {
  Widget render(BuildContext context, _LocationBarState<T> state) {
    final bool selected = state._mode == _LocationBarMode.selected;

    return AnimatedSwitcher(
      duration: resolveMotion(context, _kSwitchDuration),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: KeyedSubtree(
        key: ValueKey<bool>(selected),
        child: selected ? _renderSelected(state) : _renderSearch(state),
      ),
    );
  }

  Widget _renderSelected(_LocationBarState<T> state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: state._startEditing,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _kSideInset,
                vertical: kDefaultPadding * 1.5,
              ),
              child: EditableValueRow(
                icon: Icons.location_on_rounded,
                title: _title(state.widget),
                subtitle: state.widget.subtitle,
                semanticsLabel: "custom.location_bar.modify_semantics".tr(),
              ),
            ),
          ),
        ),
        const Divider(height: 1, indent: _kSideInset, endIndent: _kSideInset),
      ],
    );
  }

  Widget _renderSearch(_LocationBarState<T> state) {
    final LocationBar<T> widget = state.widget;
    final bool editing = state._mode == _LocationBarMode.editing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(_kSideInset, _kSideInset, _kSideInset, kDefaultPadding),
          child: _renderField(state),
        ),
        if (widget.onUseCurrentLocation != null)
          _LocateRow(busy: state._isLocating, onTap: state._useCurrentLocation),
        if (editing) ..._renderEditingFooter(state) else ..._renderEmptyFooter(widget),
      ],
    );
  }

  /// The AutocompleteSearch inside the focus anchor; its dropdown is as wide
  /// as the field.
  Widget _renderField(_LocationBarState<T> state) {
    final LocationBar<T> widget = state.widget;

    return Focus(
      focusNode: state._fieldAnchor,
      includeSemantics: false,
      onFocusChange: state._onFieldFocusChange,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return AutocompleteSearch<LocationSuggestion<T>>(
            key: ValueKey<int>(state._fieldGeneration),
            search: widget.search,
            itemBuilder: _renderSuggestion,
            onSelected: state._select,
            onError: widget.onError,
            hintText: widget.hintText ?? "custom.location_bar.placeholder".tr(),
            dropdownWidth: constraints.maxWidth,
          );
        },
      ),
    );
  }

  Widget _renderSuggestion(BuildContext context, LocationSuggestion<T> item) {
    return _SuggestionTile(
      title: item.title,
      subtitle: item.subtitle,
      badge: item.badge,
      semanticsLabel: item.semanticsLabel,
    );
  }

  /// Empty mode: a divider, then the alternative hint when set.
  List<Widget> _renderEmptyFooter(LocationBar<T> widget) {
    final String? hint = widget.alternativeHint;

    return <Widget>[
      const Divider(height: 1, indent: _kSideInset, endIndent: _kSideInset),
      if (hint != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(_kSideInset, kDefaultPadding, _kSideInset, kDefaultPadding * 1.5),
          child: _HintLine(text: hint),
        ),
    ];
  }

  /// Editing mode: the alternative hint next to Cancel, then the reminder of
  /// the current place when there is one.
  List<Widget> _renderEditingFooter(_LocationBarState<T> state) {
    final String? hint = state.widget.alternativeHint;

    return <Widget>[
      Padding(
        padding: const EdgeInsetsDirectional.only(start: _kSideInset, end: kDefaultPadding),
        child: Row(
          children: <Widget>[
            Expanded(
              child: hint == null
                  ? const SizedBox.shrink()
                  : Align(alignment: AlignmentDirectional.centerStart, child: _HintLine(text: hint)),
            ),
            TextButton(
              onPressed: state._cancelEditing,
              child: Text("custom.location_bar.cancel".tr()),
            ),
          ],
        ),
      ),
      if (state.widget.value != null) _CurrentReminder(text: _reminder(state.widget)),
    ];
  }

  /// Name shown for the chosen place.
  String _title(LocationBar<T> widget) {
    final String? title = widget.title;
    return title == null || title.isEmpty ? "custom.location_bar.unknown_place".tr() : title;
  }

  /// "Currently: title (subtitle)", or "Currently: title" without subtitle.
  String _reminder(LocationBar<T> widget) {
    final String? subtitle = widget.subtitle;
    final String name = subtitle == null || subtitle.isEmpty ? _title(widget) : "${_title(widget)} ($subtitle)";
    return "custom.location_bar.currently_at".tr(namedArgs: <String, String>{"name": name});
  }
}
