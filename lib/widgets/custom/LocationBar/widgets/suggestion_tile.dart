// suggestion_tile.dart
//
// _SuggestionTile — content of one dropdown row (AutocompleteSearch adds the
// tappable frame): a muted pin, the bold title with an optional tonal badge
// (cs.primaryContainer / cs.onPrimaryContainer) and an optional muted second
// line. An explicit semantics label replaces the visible texts.

part of "../index.dart";

final class _SuggestionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? badge;
  final String? semanticsLabel;

  const _SuggestionTile({
    required this.title,
    this.subtitle,
    this.badge,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final String? label = semanticsLabel;
    final Widget content = Row(
      children: <Widget>[
        Icon(Icons.location_on_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: kDefaultPadding),
        Expanded(child: _texts(context)),
      ],
    );
    if (label == null) return content;
    return Semantics(label: label, excludeSemantics: true, child: content);
  }

  Widget _texts(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? subtitle = this.subtitle;
    final String? badge = this.badge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(color: cs.onSurface),
              ),
            ),
            if (badge != null && badge.isNotEmpty) ...<Widget>[
              const SizedBox(width: kDefaultPadding * 0.75),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding * 0.75,
                    vertical: kDefaultPadding / 4,
                  ),
                  child: Text(
                    badge,
                    maxLines: 1,
                    style: theme.textTheme.labelSmall?.copyWith(color: cs.onPrimaryContainer),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...<Widget>[
          const SizedBox(height: kDefaultPadding / 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
