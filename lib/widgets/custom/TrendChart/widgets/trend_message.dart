// trend_message.dart
//
// _TrendMessage — the centred italic text TrendChart shows instead of the
// chart when there is no point or too few.

part of "../index.dart";

/// Fallback text shown in place of the chart.
final class _TrendMessage extends StatelessWidget {
  const _TrendMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding * 2, horizontal: kDefaultPadding * 3),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
