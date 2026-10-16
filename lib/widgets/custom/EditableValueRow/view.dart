// view.dart
//
// Layout of EditableValueRow: tinted icon badge, title / subtitle column and
// the trailing edit chip (widgets/edit_chip.dart). Colours come from the
// ColorScheme only.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, EditableValueRow widget) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? subtitle = widget.subtitle;
    final bool hasSubtitle = subtitle != null && subtitle.isNotEmpty;

    return Row(
      children: <Widget>[
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(widget.icon, size: 16, color: cs.primary),
        ),
        const SizedBox(width: kDefaultPadding * 1.5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              if (hasSubtitle) ...<Widget>[
                const SizedBox(height: kDefaultPadding / 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: widget.subtitleItalic ? FontStyle.italic : FontStyle.normal,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: kDefaultPadding),
        _EditChip(title: widget.title, editLabel: widget.editLabel, semanticsLabel: widget.semanticsLabel),
      ],
    );
  }
}
