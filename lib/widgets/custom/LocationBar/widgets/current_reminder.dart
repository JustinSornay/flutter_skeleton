// current_reminder.dart
//
// _CurrentReminder — the strip under the editing layout that recalls the
// place currently chosen: a small pin icon and one muted, ellipsised line on
// cs.surfaceContainerLow.

part of "../index.dart";

final class _CurrentReminder extends StatelessWidget {
  /// Already localised "Currently: …" text.
  final String text;

  const _CurrentReminder({required this.text});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return ColoredBox(
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _kSideInset, vertical: kDefaultPadding),
        child: Row(
          children: <Widget>[
            Icon(Icons.location_on_rounded, size: 12, color: cs.onSurfaceVariant),
            const SizedBox(width: kDefaultPadding * 0.75),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
