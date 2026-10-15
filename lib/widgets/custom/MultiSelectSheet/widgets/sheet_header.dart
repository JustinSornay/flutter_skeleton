// sheet_header.dart
//
// _SheetHeader — title (semantics header) and the counter pill of
// MultiSelectSheet. The counter is a live region so selection changes are
// announced, and takes at most half of the header width.

part of "../index.dart";

final class _SheetHeader extends StatelessWidget {
  final String title;
  final String counter;

  const _SheetHeader({
    required this.title,
    required this.counter,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) => Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: kDefaultPadding),
          Semantics(
            liveRegion: true,
            child: _Pill(
              text: counter,
              radius: _counterRadius,
              rowWidth: constraints.maxWidth,
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
                vertical: kDefaultPadding / 2,
              ),
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
