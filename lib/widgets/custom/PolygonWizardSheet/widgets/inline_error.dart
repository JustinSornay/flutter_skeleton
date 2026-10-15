// inline_error.dart
//
// _InlineError — one error line of PolygonWizardSheet (cs.error, bodySmall)
// announced as a live region: failed submit, failed pick, crossing edges.

part of "../index.dart";

final class _InlineError extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;

  const _InlineError({required this.text, required this.padding});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Padding(
        padding: padding,
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}
