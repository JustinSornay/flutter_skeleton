// item_row.dart
//
// _ItemRow — one ExplainerSheet row: tone dot, label with the optional italic
// caption under it, and the optional trailing value in the tone foreground.
// MergeSemantics makes the row read as "label, caption, value".

part of "../index.dart";

/// Gap between the dot and the label column.
const double _dotGap = kDefaultPadding * 2;

final class _ItemRow extends StatelessWidget {
  final ExplainerItem item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Color toneColor = StatusTones.colorsOf(context, item.tone).foreground;
    final TextStyle labelStyle = (theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14))
        .copyWith(fontWeight: FontWeight.w600, color: cs.onSurface);
    final double lineHeight = _ToneDot.lineHeightOf(context, labelStyle);
    final String? caption = item.caption;
    final String? value = item.value;

    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ToneDot(color: toneColor, lineHeight: lineHeight),
          const SizedBox(width: _dotGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.label, style: labelStyle),
                if (caption != null && caption.isNotEmpty)
                  Text(
                    caption,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (value != null && value.isNotEmpty) ...<Widget>[
            const SizedBox(width: kDefaultPadding),
            SizedBox(
              height: lineHeight,
              child: Center(
                widthFactor: 1,
                child: Text(
                  value,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: toneColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
