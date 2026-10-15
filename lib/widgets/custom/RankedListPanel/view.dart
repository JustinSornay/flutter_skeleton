// view.dart
//
// _ViewMixin — tree of RankedListPanel: an elevated Material with rounded
// top corners holding the optional decorative grip, the optional overline
// title and one _RankedListPanelRow per entry in a min-size Column.

part of "index.dart";

/// Top corner radius of the panel.
const double _panelRadius = kDefaultPadding * 2;

/// Elevation of the panel surface.
const double _panelElevation = 6;

/// Inner padding of the panel (16 / 8 / 16 / 16 dp).
const EdgeInsets _panelPadding = EdgeInsets.fromLTRB(
  kDefaultPadding * 2,
  kDefaultPadding,
  kDefaultPadding * 2,
  kDefaultPadding * 2,
);

/// Size of the decorative grip (32 x 4 dp).
const Size _gripSize = Size(kDefaultPadding * 4, kDefaultPadding / 2);

/// Opacity of the grip colour.
const double _gripAlpha = 0.4;

/// Letter spacing of the overline title.
const double _titleLetterSpacing = 1.5;

mixin _ViewMixin<T> {
  Widget render(BuildContext context, RankedListPanel<T> widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? title = widget.title;
    final bool hasRows = widget.entries.isNotEmpty;

    return Material(
      color: cs.surfaceContainerLow,
      elevation: _panelElevation,
      shadowColor: cs.shadow,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(_panelRadius)),
      child: Padding(
        padding: _panelPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (widget.showHandle) ...<Widget>[_grip(cs), const SizedBox(height: kDefaultPadding)],
            if (title != null) ...<Widget>[
              _title(context, title),
              if (hasRows) const SizedBox(height: kDefaultPadding),
            ],
            ..._rows(widget),
          ],
        ),
      ),
    );
  }

  /// Decorative grip, centred and hidden from assistive technologies.
  Widget _grip(ColorScheme cs) {
    return ExcludeSemantics(
      child: Center(
        child: SizedBox.fromSize(
          size: _gripSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: _gripAlpha),
              borderRadius: BorderRadius.circular(_gripSize.height / 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(BuildContext context, String title) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: _titleLetterSpacing,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  List<Widget> _rows(RankedListPanel<T> widget) {
    final List<RankedListEntry<T>> entries = widget.entries;
    return <Widget>[
      for (int index = 0; index < entries.length; index++)
        _RankedListPanelRow<T>(
          entry: entries[index],
          rank: entries[index].rank ?? index + 1,
          icon: entries[index].icon ?? widget.icon,
          onTap: widget.onTap,
        ),
    ];
  }
}
