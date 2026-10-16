// legend_item.dart
//
// Private legend entry of StatusStrip: a small glyph followed by a label
// (9 / w700) on one line, laid out as one paragraph so a label too long for
// the width ends with an ellipsis instead of overflowing. Shared by both
// legends.

part of "../index.dart";

final class _LegendItem extends StatelessWidget {
  /// Decorative glyph drawn before the label (dot, dash, marker).
  final Widget glyph;

  /// Entry text.
  final String label;

  /// Text colour.
  final Color color;

  const _LegendItem({required this.glyph, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final TextStyle style = (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      color: color,
    );
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: kDefaultPadding / 2),
              child: glyph,
            ),
          ),
          TextSpan(text: label),
        ],
      ),
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
