// view.dart
//
// Tree of SwimlaneCard: the rounded card holding the header row (title and
// trailing slot), the optional subtitle and the horizontal lane of
// _SwimlaneTile parts, each told whether it is selected.

part of "index.dart";

/// Corner radius of the card.
const double _cardRadius = 12;

/// Height of the lane (and of every tile) at the default text scale.
const double _laneHeight = kDefaultPadding * 12;

/// Font size on which the text scale applied to the lane is measured.
const double _scaleReference = 14;

/// Letter spacing of the caption-style title.
const double _titleLetterSpacing = 1.5;

mixin _ViewMixin<T> {
  Widget render(BuildContext context, SwimlaneCard<T> widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? subtitle = widget.subtitle;

    return Container(
      padding: const EdgeInsets.all(kDefaultPadding * 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _header(context, widget),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: kDefaultPadding / 4),
            _subtitle(context, subtitle),
          ],
          const SizedBox(height: kDefaultPadding),
          SizedBox(height: _laneHeightOf(context), child: _lane(widget)),
        ],
      ),
    );
  }

  /// Title (taking the free width, ellipsized) and the trailing slot.
  Widget _header(BuildContext context, SwimlaneCard<T> widget) {
    final ThemeData theme = Theme.of(context);
    final Widget? trailing = widget.trailing;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: _titleLetterSpacing,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: kDefaultPadding),
          trailing,
        ],
      ],
    );
  }

  Widget _subtitle(BuildContext context, String subtitle) {
    final ThemeData theme = Theme.of(context);

    return Text(
      subtitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  /// [_laneHeight] grown with the text scale, so enlarged text still fits
  /// in the tiles.
  double _laneHeightOf(BuildContext context) {
    final double factor = MediaQuery.textScalerOf(context).scale(_scaleReference) / _scaleReference;
    return factor > 1 ? _laneHeight * factor : _laneHeight;
  }

  Widget _lane(SwimlaneCard<T> widget) {
    final T? selectedId = widget.selectedId;
    final ValueChanged<T>? onSelected = widget.onSelected;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: widget.items.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(width: kDefaultPadding),
      itemBuilder: (BuildContext context, int index) {
        final SwimlaneItem<T> item = widget.items[index];
        return _SwimlaneTile(
          item: item,
          width: widget.tileWidth,
          selected: selectedId != null && item.id == selectedId,
          onTap: onSelected == null ? null : () => onSelected(item.id),
        );
      },
    );
  }
}
