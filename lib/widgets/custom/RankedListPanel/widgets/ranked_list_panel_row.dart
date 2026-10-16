// ranked_list_panel_row.dart
//
// _RankedListPanelRow — one row of RankedListPanel: rank, optional leading
// icon tinted by the entry's tone foreground (StatusTones), bold label,
// optional muted detail and a chevron. A single button semantics node, at
// least kMinTapTarget tall, with a primary-tinted ink. A LayoutBuilder lets
// the label and the detail share the width left by the other parts.

part of "../index.dart";

/// Corner radius of the row ink.
const double _rowInkRadius = kDefaultPadding;

/// Inner padding of a row (4 / 8 dp).
const EdgeInsets _rowPadding = EdgeInsets.symmetric(
  horizontal: kDefaultPadding / 2,
  vertical: kDefaultPadding,
);

/// Minimum width of the rank column (24 dp, gap included).
const double _rankMinWidth = kDefaultPadding * 3;

/// Gap kept after a rank wider than its column.
const double _rankGap = kDefaultPadding / 2;

/// Size of the leading icon.
const double _iconSize = 18;

/// Size of the chevron.
const double _chevronSize = 16;

/// Widest the detail may grow before it ellipsises (128 dp).
const double _detailMaxWidth = kDefaultPadding * 16;

/// Gap between the label and the detail.
const double _detailGap = kDefaultPadding;

/// Opacity of the ink splash and highlight.
const double _splashAlpha = 0.08;
const double _highlightAlpha = 0.04;

/// Separator of the default semantics label parts.
const String _semanticsSeparator = " — ";

final class _RankedListPanelRow<T> extends StatelessWidget {
  final RankedListEntry<T> entry;

  /// Rank drawn in the first column.
  final int rank;

  /// Leading glyph; null hides it.
  final IconData? icon;

  final ValueChanged<T> onTap;

  const _RankedListPanelRow({
    required this.entry,
    required this.rank,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(_rowInkRadius);

    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      label: _semanticsLabel(),
      onTap: _handleTap,
      child: InkWell(
        onTap: _handleTap,
        borderRadius: radius,
        splashColor: cs.primary.withValues(alpha: _splashAlpha),
        highlightColor: cs.primary.withValues(alpha: _highlightAlpha),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          child: Padding(
            padding: _rowPadding,
            child: Row(
              children: <Widget>[
                _rank(context),
                ..._icon(context),
                Expanded(child: _texts()),
                const SizedBox(width: kDefaultPadding / 2),
                Icon(Icons.chevron_right_rounded, size: _chevronSize, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap() => onTap(entry.value);

  Widget _rank(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: _rankGap),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: _rankMinWidth - _rankGap),
        child: Text(
          "$rank",
          maxLines: 1,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  List<Widget> _icon(BuildContext context) {
    final IconData? glyph = icon;
    if (glyph == null) return const <Widget>[];
    return <Widget>[
      Icon(glyph, size: _iconSize, color: StatusTones.colorsOf(context, entry.tone).foreground),
      const SizedBox(width: kDefaultPadding),
    ];
  }

  /// Label and detail sharing the width left by the rank, the icon and the
  /// chevron: the detail gets at most [_detailMaxWidth] and never more than
  /// half of that width, the label fills the rest. A flex Row cannot do this
  /// alone: it splits the free space evenly between flexible children and
  /// leaves a short detail's unused share empty at the end of the row.
  Widget _texts() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double detailMaxWidth = ((constraints.maxWidth - _detailGap) / 2).clamp(0.0, _detailMaxWidth);
        return Row(
          children: <Widget>[
            Expanded(child: _label(context)),
            ..._detail(context, detailMaxWidth),
          ],
        );
      },
    );
  }

  Widget _label(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      entry.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  List<Widget> _detail(BuildContext context, double maxWidth) {
    final String? detail = entry.detail;
    if (detail == null || detail.isEmpty) return const <Widget>[];
    final ThemeData theme = Theme.of(context);
    return <Widget>[
      const SizedBox(width: _detailGap),
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    ];
  }

  /// [RankedListEntry.semanticsLabel], else the rank, the label and the
  /// detail joined with " — ".
  String _semanticsLabel() {
    final String? custom = entry.semanticsLabel;
    if (custom != null) return custom;
    final String head = "custom.ranked_list_panel.rank".tr(namedArgs: <String, String>{"rank": "$rank"});
    return <String?>[head, entry.label, entry.detail]
        .whereType<String>()
        .where((String part) => part.isNotEmpty)
        .join(_semanticsSeparator);
  }
}
