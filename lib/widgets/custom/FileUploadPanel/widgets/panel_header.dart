// panel_header.dart
//
// _PanelHeader — optional title (header semantics) and hint of
// FileUploadPanel, followed by the gap above the pick button.

part of "../index.dart";

final class _PanelHeader extends StatelessWidget {
  final String? title;
  final String? hint;

  const _PanelHeader({required this.title, required this.hint});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? title = this.title;
    final String? hint = this.hint;
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (title != null)
            Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
          if (title != null && hint != null) const SizedBox(height: kDefaultPadding / 2),
          if (hint != null)
            Text(
              hint,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
