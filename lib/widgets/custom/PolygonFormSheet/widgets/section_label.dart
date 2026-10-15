// section_label.dart
//
// _SectionLabel — uppercase section header of PolygonFormSheet (10, w800,
// tracking 0.8, cs.onSurfaceVariant). Screen readers get the original case.

part of "../index.dart";

final class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      semanticsLabel: text,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
