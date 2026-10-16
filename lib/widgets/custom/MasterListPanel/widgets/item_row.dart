// item_row.dart
//
// _ItemRow — one selectable row of MasterListPanel: line 1 title + trailing
// (_TitleLine, shared with the archive drawer rows), line 2 optional icon +
// subtitle, line 3 tag pills (PillBadge, dense) with a "+N" overflow pill.
// Selected: cs.secondaryContainer background + 3 dp cs.primary left border,
// and the pills switch to a cs.surface fill so they stay visible on it.
// One merged semantics node (button, selected), at least kMinTapTarget tall.
// The trailing text is capped at 40 % of line 1 and ellipsised.

part of "../index.dart";

/// Width of the left selection indicator.
const double _indicatorWidth = 3;

/// Largest share of line 1 given to the trailing text; longer text is
/// ellipsised so the title keeps the rest of the line.
const double _trailingMaxFraction = 0.4;

/// Inner padding of a row (16 / 10 dp).
const EdgeInsets _rowPadding = EdgeInsets.symmetric(
  horizontal: kDefaultPadding * 2,
  vertical: kDefaultPadding * 1.25,
);

final class _ItemRow extends StatelessWidget {
  final MasterListItem item;
  final bool selected;
  final int maxVisibleTags;
  final VoidCallback onTap;

  const _ItemRow({
    super.key,
    required this.item,
    required this.selected,
    required this.maxVisibleTags,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? cs.secondaryContainer : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: selected ? cs.primary : Colors.transparent, width: _indicatorWidth),
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: kMinTapTarget),
                child: Padding(
                  padding: _rowPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _TitleLine(title: item.title, trailing: item.trailing),
                      ..._subtitle(context),
                      ..._tags(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _subtitle(BuildContext context) {
    final String? subtitle = item.subtitle;
    if (subtitle == null) return const <Widget>[];
    final ThemeData theme = Theme.of(context);
    final Color color = theme.colorScheme.onSurfaceVariant;
    final IconData? icon = item.subtitleIcon;
    return <Widget>[
      const SizedBox(height: kDefaultPadding / 2),
      Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: kDefaultPadding / 2),
          ],
          Expanded(
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _tags(BuildContext context) {
    if (item.tags.isEmpty) return const <Widget>[];
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<String> visible = item.tags.take(maxVisibleTags).toList();
    final int hidden = item.tags.length - visible.length;
    // The selected row is cs.secondaryContainer: pills of the same fill
    // would lose their shape, so they switch to cs.surface there.
    final Color? selectedFill = selected ? cs.surface : null;
    return <Widget>[
      const SizedBox(height: kDefaultPadding * 0.75),
      Wrap(
        spacing: kDefaultPadding / 2,
        runSpacing: kDefaultPadding / 2,
        children: <Widget>[
          for (final String tag in visible)
            PillBadge(
              label: tag,
              dense: true,
              color: cs.onSecondaryContainer,
              backgroundColor: selectedFill ?? cs.secondaryContainer,
            ),
          if (hidden > 0)
            PillBadge(
              label: "+$hidden",
              dense: true,
              color: cs.onSurfaceVariant,
              backgroundColor: selectedFill ?? cs.surfaceContainerHighest,
              semanticsLabel: "custom.master_list_panel.more_tags".tr(
                namedArgs: <String, String>{"count": "$hidden"},
              ),
            ),
        ],
      ),
    ];
  }
}

/// Line 1 of a row: [title] (one line, ellipsised) + optional [trailing]
/// (one line, at most [_trailingMaxFraction] of the line, ellipsised).
final class _TitleLine extends StatelessWidget {
  final String title;
  final String? trailing;

  const _TitleLine({required this.title, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? trailing = this.trailing;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) => Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: kDefaultPadding),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * _trailingMaxFraction),
              child: Text(
                trailing,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
