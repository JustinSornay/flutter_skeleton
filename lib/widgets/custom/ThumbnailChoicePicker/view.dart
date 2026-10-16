// view.dart
//
// Tree of ThumbnailChoicePicker: a transparent Material for ink, the padded
// LayoutBuilder choosing between the side-by-side and the stacked layout,
// the merged title block and the wrapping row of _ChoiceCard
// (widgets/choice_card.dart). Resolves each card's thumbnail, selection and
// tap callback. Colours come from the ColorScheme only.

part of "index.dart";

/// Room kept for the title block next to the cards in the side-by-side
/// layout; below it the title block is stacked above the cards.
const double _minTitleWidth = kDefaultPadding * 16;

/// Gap between the title block and the cards, side by side.
const double _titleCardsGap = kDefaultPadding * 2;

/// Gap between the title block and the cards, stacked.
const double _stackGap = kDefaultPadding * 1.5;

/// Gap between the title and the subtitle.
const double _subtitleGap = kDefaultPadding / 4;

mixin _ViewMixin<T> {
  Widget render(BuildContext context, ThumbnailChoicePicker<T> widget) {
    assert(widget.choices.isNotEmpty, "ThumbnailChoicePicker needs at least one choice");
    assert(
      widget.thumbnailSize.width >= kMinTapTarget && widget.thumbnailSize.height >= kMinTapTarget,
      "thumbnailSize must be at least kMinTapTarget on both sides",
    );

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: widget.padding,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return _layout(context, widget, constraints.maxWidth);
          },
        ),
      ),
    );
  }

  /// Cards alone, title block beside the cards, or title block above them.
  Widget _layout(BuildContext context, ThumbnailChoicePicker<T> widget, double maxWidth) {
    final Widget cards = _cards(widget);
    if (widget.title == null && widget.subtitle == null) return cards;

    final Widget titleBlock = _titleBlock(context, widget);
    if (_stacks(widget, maxWidth)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[titleBlock, const SizedBox(height: _stackGap), cards],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(child: titleBlock),
        const SizedBox(width: _titleCardsGap),
        cards,
      ],
    );
  }

  /// True below [ThumbnailChoicePicker.stackBreakpoint], or when the cards
  /// in one row would leave less than [_minTitleWidth] to the title block.
  bool _stacks(ThumbnailChoicePicker<T> widget, double maxWidth) {
    final int count = widget.choices.length;
    final double cardsWidth = count * widget.thumbnailSize.width + (count - 1) * widget.spacing;
    return maxWidth < widget.stackBreakpoint || cardsWidth + _titleCardsGap + _minTitleWidth > maxWidth;
  }

  /// Title and subtitle, announced together by screen readers.
  Widget _titleBlock(BuildContext context, ThumbnailChoicePicker<T> widget) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? title = widget.title;
    final String? subtitle = widget.subtitle;

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (title != null)
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
              ),
            ),
          if (title != null && subtitle != null) const SizedBox(height: _subtitleGap),
          if (subtitle != null)
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  /// One card per choice, in order, wrapping onto new runs when narrow.
  Widget _cards(ThumbnailChoicePicker<T> widget) {
    return Wrap(
      spacing: widget.spacing,
      runSpacing: widget.spacing,
      children: <Widget>[
        for (final ThumbnailChoice<T> choice in widget.choices) _card(widget, choice),
      ],
    );
  }

  Widget _card(ThumbnailChoicePicker<T> widget, ThumbnailChoice<T> choice) {
    final ChoiceOption<T> option = choice.option;
    final bool selected = option.value == widget.selected;

    return _ChoiceCard(
      label: option.label,
      semanticsLabel: option.semanticsLabel ?? option.label,
      selected: selected,
      size: widget.thumbnailSize,
      thumbnail: _thumbnail(choice),
      onTap: _onTapOf(widget, option, selected),
    );
  }

  Widget _thumbnail(ThumbnailChoice<T> choice) {
    final ColorScheme? scheme = choice.scheme;
    if (scheme != null) {
      return _MockupThumbnail(scheme: scheme, backgroundImage: choice.backgroundImage);
    }
    return choice.preview ?? const SizedBox.shrink();
  }

  /// Null (disabled card) without onChanged or for a disabled option. The
  /// selected card stays tappable but does not report its own value again.
  VoidCallback? _onTapOf(ThumbnailChoicePicker<T> widget, ChoiceOption<T> option, bool selected) {
    final ValueChanged<T>? onChanged = widget.onChanged;
    if (onChanged == null || !option.enabled) return null;

    return () {
      if (!selected) onChanged(option.value);
    };
  }
}
