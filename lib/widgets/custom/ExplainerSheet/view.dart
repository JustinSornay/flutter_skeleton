// view.dart
//
// _ViewMixin — widget tree of ExplainerSheet: header title, the item rows
// (widgets/item_row.dart) separated by dividers or the empty row
// (widgets/empty_row.dart), the optional badge slot and the optional
// "learn more" TextButton, in a scroll view padded on the 8 dp grid.

part of "index.dart";

/// Height taken by a divider between two rows (8 dp above and below).
const double _dividerHeight = kDefaultPadding * 2;

/// Vertical gap between the title, the rows, the badge and the link.
const double _sectionGap = kDefaultPadding * 2;

mixin _ViewMixin {
  Widget render(BuildContext context, ExplainerSheet widget) {
    final ThemeData theme = Theme.of(context);
    final Widget? badge = widget.badge;
    final VoidCallback? onLearnMore = widget.onLearnMore;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        kDefaultPadding * 3,
        kDefaultPadding * 2,
        kDefaultPadding * 3,
        kDefaultPadding * 3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              widget.title ?? "custom.explainer_sheet.title".tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: _sectionGap),
          ..._rows(widget, theme.colorScheme),
          if (badge != null) ...<Widget>[
            const SizedBox(height: _sectionGap),
            badge,
          ],
          if (onLearnMore != null) ...<Widget>[
            const SizedBox(height: _sectionGap),
            _link(theme, widget.learnMoreLabel, onLearnMore),
          ],
        ],
      ),
    );
  }

  /// The first `maxItems` rows separated by dividers, or the empty row.
  List<Widget> _rows(ExplainerSheet widget, ColorScheme cs) {
    if (widget.items.isEmpty) {
      return <Widget>[
        _EmptyRow(label: widget.emptyLabel ?? "custom.explainer_sheet.empty".tr()),
      ];
    }
    final List<ExplainerItem> visible = widget.items.take(widget.maxItems).toList();
    return <Widget>[
      for (int i = 0; i < visible.length; i++) ...<Widget>[
        if (i > 0) Divider(height: _dividerHeight, color: cs.outlineVariant),
        _ItemRow(item: visible[i]),
      ],
    ];
  }

  /// "Learn more" link: a TextButton at least 48 × 48 (button semantics).
  Widget _link(ThemeData theme, String? label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        minimumSize: const Size.square(kMinTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
        textStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      child: Text(label ?? "custom.explainer_sheet.learn_more".tr()),
    );
  }
}
