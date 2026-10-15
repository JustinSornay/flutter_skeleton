// error_banner.dart
//
// _ErrorBanner — inline message shown by AsyncPickerSheet after a failed
// submit. Error container colours paired with an icon and the text, announced
// as a live region.

part of "../index.dart";

final class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          kDefaultPadding * 2,
          0,
          kDefaultPadding * 2,
          kDefaultPadding,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding * 2,
          vertical: kDefaultPadding,
        ),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.error_outline, size: 20, color: cs.onErrorContainer),
            const SizedBox(width: kDefaultPadding),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
