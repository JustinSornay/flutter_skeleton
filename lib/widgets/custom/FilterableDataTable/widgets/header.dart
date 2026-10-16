// header.dart
//
// Private header strip of FilterableDataTable: the title overline and the
// row count on a tinted band with a bottom border, exposed as one semantics
// header node.

part of "../index.dart";

/// Header font size (title and count).
const double _headerFontSize = 10;

/// Title letter spacing.
const double _titleLetterSpacing = 0.8;

final class _Header extends StatelessWidget {
  /// Overline text, shown as given.
  final String title;

  /// Number of displayed rows.
  final int count;

  const _Header({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final TextStyle? base = theme.textTheme.labelSmall?.copyWith(
      fontSize: _headerFontSize,
      color: cs.onSurfaceVariant,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 2, vertical: kDefaultPadding),
        child: MergeSemantics(
          child: Semantics(
            header: true,
            child: Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    title,
                    style: base?.copyWith(fontWeight: FontWeight.w700, letterSpacing: _titleLetterSpacing),
                  ),
                ),
                const SizedBox(width: kDefaultPadding),
                Text("$count", style: base?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
