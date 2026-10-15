// sheet_header.dart
//
// _SheetHeader — title (18, w800, header semantics) and the optional
// subtitle of EditFieldsSheet.

part of "../index.dart";

final class _SheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SheetHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? subtitle = this.subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: cs.onSurface,
            ),
          ),
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...<Widget>[
          const SizedBox(height: kDefaultPadding / 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
