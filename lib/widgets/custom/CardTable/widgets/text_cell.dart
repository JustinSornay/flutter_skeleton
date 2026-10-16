// text_cell.dart
//
// _TextCell — the built-in cell of CardTableColumn.text: one line of text
// with an ellipsis, styled by CardTableEmphasis (strong: 12.5 sp w700
// cs.onSurface; muted: 11.5 sp w400 cs.onSurfaceVariant).

part of "../index.dart";

/// Font size of a strong text cell.
const double _strongFontSize = 12.5;

/// Font size of a muted text cell.
const double _mutedFontSize = 11.5;

final class _TextCell extends StatelessWidget {
  /// Cell text, already localised and formatted.
  final String text;

  final CardTableEmphasis emphasis;

  final TextAlign align;

  const _TextCell({required this.text, required this.emphasis, required this.align});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _style(Theme.of(context)),
    );
  }

  TextStyle? _style(ThemeData theme) {
    final ColorScheme cs = theme.colorScheme;
    final TextStyle? base = theme.textTheme.bodySmall;
    return switch (emphasis) {
      CardTableEmphasis.strong => base?.copyWith(
          fontSize: _strongFontSize,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      CardTableEmphasis.muted => base?.copyWith(
          fontSize: _mutedFontSize,
          fontWeight: FontWeight.w400,
          color: cs.onSurfaceVariant,
        ),
    };
  }
}
