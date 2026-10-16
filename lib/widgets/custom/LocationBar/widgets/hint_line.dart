// hint_line.dart
//
// _HintLine — the host's alternative hint ("or tap the map"…): a touch icon
// and a muted bodySmall text that wraps instead of overflowing.

part of "../index.dart";

final class _HintLine extends StatelessWidget {
  /// Already localised hint.
  final String text;

  const _HintLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.touch_app_rounded, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: kDefaultPadding * 0.75),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
