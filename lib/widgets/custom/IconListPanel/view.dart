// view.dart
//
// Tree of IconListPanel: a clipped rounded panel (foreground border) holding
// the header band (semantic header) and the body — the rows separated by
// dividers, or the empty placeholder. Colours come from the ColorScheme only;
// the rows (widgets/item_row.dart) add the StatusTones.

part of "index.dart";

/// Panel corner radius.
const double _panelRadius = 10;

/// Body inset (12 dp); also the gap between the icon tile and the text.
const double _inset = kDefaultPadding * 1.5;

/// Header band padding (16 / 8 dp).
const EdgeInsets _headerPadding = EdgeInsets.symmetric(
  horizontal: kDefaultPadding * 2,
  vertical: kDefaultPadding,
);

/// Height of the divider between two rows (16 dp).
const double _dividerHeight = kDefaultPadding * 2;

/// Letter spacing of the header title.
const double _titleTracking = 0.8;

mixin _ViewMixin {
  Widget render(BuildContext context, IconListPanel widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(_panelRadius);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: radius),
      // Foreground, so the header fill never covers the border.
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _header(context, widget.title),
          Padding(
            padding: const EdgeInsets.all(_inset),
            child: widget.items.isEmpty ? _empty(context, widget) : _rows(context, widget.items),
          ),
        ],
      ),
    );
  }

  /// Tinted band with the title, exposed as a semantic header.
  Widget _header(BuildContext context, String title) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Container(
      padding: _headerPadding,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Semantics(
        container: true,
        header: true,
        child: Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: _titleTracking,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  /// Rows in order, a divider between two consecutive rows.
  Widget _rows(BuildContext context, List<IconListPanelItem> items) {
    final Color dividerColor = Theme.of(context).colorScheme.outlineVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0) Divider(height: _dividerHeight, color: dividerColor),
          _ItemRow(item: items[i]),
        ],
      ],
    );
  }

  /// Muted placeholder of an empty list.
  Widget _empty(BuildContext context, IconListPanel widget) {
    final ThemeData theme = Theme.of(context);

    return Text(
      widget.emptyLabel ?? "custom.icon_list_panel.empty".tr(),
      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }
}
