// popover_row.dart
//
// _PopoverRow — one popover row, shared by the reference and the members:
// a badge, the label (ellipsised) over an optional caption, and the value
// (cs.primary for members, cs.onSurface for the reference). At least
// kMinTapTarget tall; the active row is tinted cs.secondaryContainer.
// Announced as `label, caption, value`, selected when active.

part of "../index.dart";

final class _PopoverRow extends StatelessWidget {
  /// _RankBadge.
  final Widget leading;

  final String label;
  final String? caption;

  /// Formatted value.
  final String valueText;

  /// The row is the active selection.
  final bool active;

  /// Reference row (value in cs.onSurface).
  final bool reference;

  /// Null makes the row inert.
  final VoidCallback? onTap;

  const _PopoverRow({
    required this.leading,
    required this.label,
    required this.valueText,
    required this.active,
    this.caption,
    this.reference = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final BorderRadius radius = BorderRadius.circular(kDefaultPadding);

    return Semantics(
      container: true,
      excludeSemantics: true,
      button: onTap != null,
      selected: active,
      label: <String>[label, ?caption, valueText].join(", "),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(color: active ? cs.secondaryContainer : null, borderRadius: radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTapTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
              child: Row(
                children: <Widget>[
                  leading,
                  const SizedBox(width: kDefaultPadding),
                  Expanded(child: _texts(cs, textTheme)),
                  Text(
                    valueText,
                    style: textTheme.titleSmall?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: reference ? cs.onSurface : cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _texts(ColorScheme cs, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        if (caption case final String text)
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
