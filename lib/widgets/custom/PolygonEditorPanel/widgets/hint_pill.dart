// hint_pill.dart
//
// _HintPill — the rounded hint shown over the empty map of
// PolygonEditorPanel: cs.inverseSurface background, cs.onInverseSurface
// labelMedium text, radius 999. The parent makes it ignore pointers.

part of "../index.dart";

final class _HintPill extends StatelessWidget {
  final String text;

  const _HintPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.inverseSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding * 2,
          vertical: kDefaultPadding,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: cs.onInverseSurface,
          ),
        ),
      ),
    );
  }
}
