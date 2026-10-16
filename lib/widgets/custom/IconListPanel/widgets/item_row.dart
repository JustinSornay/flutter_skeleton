// item_row.dart
//
// _ItemRow — one row of IconListPanel: an optional 36 dp icon tile tinted by
// the item's StatusTone (container fill, onContainer icon), the one-line title
// with the tag StatusPill beside it (wrapping under it when both do not fit),
// and the optional muted subtitle. One merged semantics node.

part of "../index.dart";

/// Side of the icon tile.
const double _tileSize = 36;

/// Corner radius of the icon tile.
const double _tileRadius = kDefaultPadding;

/// Icon size inside the tile.
const double _tileIconSize = 18;

/// Gap between the title line and the subtitle (4 dp); also the run spacing
/// when the tag wraps under the title.
const double _lineGap = kDefaultPadding / 2;

final class _ItemRow extends StatelessWidget {
  final IconListPanelItem item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final IconData? icon = item.icon;
    final String? subtitle = item.subtitle;

    return MergeSemantics(
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            _tile(context, icon),
            const SizedBox(width: _inset),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _titleLine(context),
                if (subtitle != null && subtitle.isNotEmpty) ...<Widget>[
                  const SizedBox(height: _lineGap),
                  _subtitle(context, subtitle),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Decorative tile: tone `container` fill, tone `onContainer` icon
  /// (>= 4.5:1 on the fill for every tone; `foreground` can drop to 1.5:1).
  Widget _tile(BuildContext context, IconData icon) {
    final ToneColors colors = StatusTones.colorsOf(context, item.tone);

    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: _tileSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.container,
            borderRadius: BorderRadius.circular(_tileRadius),
          ),
          child: Center(child: Icon(icon, size: _tileIconSize, color: colors.onContainer)),
        ),
      ),
    );
  }

  /// Title (one line, ellipsis) and, when set, the tag pill. The pill sits
  /// beside the title, or on the next line when both do not fit.
  Widget _titleLine(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? tag = item.tag;

    return Wrap(
      spacing: kDefaultPadding,
      runSpacing: _lineGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (tag != null && tag.isNotEmpty) StatusPill(label: tag, tone: item.tone, dense: true),
      ],
    );
  }

  Widget _subtitle(BuildContext context, String subtitle) {
    final ThemeData theme = Theme.of(context);

    return Text(
      subtitle,
      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }
}
