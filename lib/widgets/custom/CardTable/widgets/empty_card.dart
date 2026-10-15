// empty_card.dart
//
// _EmptyCard — the card shown by CardTable when there is no row: the same
// frame as the table (surfaceContainerLowest, outlineVariant border, radius
// 12) with the message in 12 sp cs.onSurfaceVariant.

part of "../index.dart";

final class _EmptyCard extends StatelessWidget {
  /// Text shown in the card, already localised.
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kDefaultPadding * 2),
      decoration: _cardDecoration(cs),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: cs.onSurfaceVariant),
      ),
    );
  }
}
