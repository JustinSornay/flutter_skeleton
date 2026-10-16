// entry_row.dart
//
// Private row of an open ExpandableGroupTile: label, optional description,
// optional trailing text in cs.primary and a small chevron. Disabled entries
// are dimmed and ignore taps; one button semantics node per row.

part of "../index.dart";

/// Opacity of a disabled entry or an inert header (Material 3 disabled
/// content).
const double _disabledOpacity = 0.38;

/// Trailing chevron size.
const double _entryChevronSize = 16;

final class _EntryRow<T> extends StatelessWidget {
  final ChoiceOption<T> entry;

  final ValueChanged<T> onSelected;

  const _EntryRow({required this.entry, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final String? semanticsLabel = entry.semanticsLabel;

    // The visible texts are excluded (not the InkWell) so the node keeps its
    // tap action when semanticsLabel replaces them.
    return Semantics(
      container: true,
      button: true,
      enabled: entry.enabled,
      label: semanticsLabel,
      child: InkWell(
        onTap: entry.enabled ? () => onSelected(entry.value) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              kDefaultPadding * 3,
              kDefaultPadding,
              kDefaultPadding * 2,
              kDefaultPadding,
            ),
            child: Opacity(
              opacity: entry.enabled ? 1 : _disabledOpacity,
              child: ExcludeSemantics(
                excluding: semanticsLabel != null,
                child: _content(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? description = entry.description;
    final String? trailing = entry.trailing;

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                entry.label,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: cs.onSurface),
              ),
              if (description != null && description.isNotEmpty)
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
            ],
          ),
        ),
        if (trailing != null && trailing.isNotEmpty) ...<Widget>[
          const SizedBox(width: kDefaultPadding),
          Text(
            trailing,
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: cs.primary),
          ),
        ],
        const SizedBox(width: kDefaultPadding / 2),
        Icon(Icons.chevron_right, size: _entryChevronSize, color: cs.outline),
      ],
    );
  }
}
