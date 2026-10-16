// view.dart
//
// Tree of StatusPill: nothing for an empty label, a tone-tinted PillBadge
// for the pill, or a tone-tinted circle (24 dp at the default text scale,
// scaled with the code's font above it) with one semantics node for the
// compact variant. Colours come from StatusTones only.

part of "index.dart";

/// Diameter of the compact circle at the default text scale (24 dp); also its minimum.
const double _compactSize = kDefaultPadding * 3;

/// Size of the compact code when the theme's labelSmall has none (11 sp).
const double _compactFontSize = 11;

mixin _ViewMixin {
  Widget render(BuildContext context, StatusPill widget) {
    if (widget.label.isEmpty) return const SizedBox.shrink();

    final ToneColors colors = StatusTones.colorsOf(context, widget.tone);
    final String? letter = widget.letter;
    if (letter != null) return _compact(context, widget, letter, colors);

    return PillBadge(
      label: widget.label,
      tone: widget.tone,
      icon: widget.icon,
      color: colors.onContainer,
      backgroundColor: colors.container,
      dense: widget.dense,
      semanticsLabel: widget.semanticsLabel,
    );
  }

  /// The circle grows by the same factor as the code's font under the text
  /// scaler (never below 24 dp), so an enlarged code is neither clipped nor
  /// shifted off-centre.
  Widget _compact(BuildContext context, StatusPill widget, String letter, ToneColors colors) {
    assert(letter.trim().isNotEmpty, "letter must contain a visible character");
    final TextStyle baseStyle = Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: _compactFontSize);
    final double fontSize = baseStyle.fontSize ?? _compactFontSize;
    final double fontScale = MediaQuery.textScalerOf(context).scale(fontSize) / fontSize;

    return Semantics(
      label: widget.label,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: math.max(_compactSize, _compactSize * fontScale),
        child: DecoratedBox(
          decoration: BoxDecoration(color: colors.container, shape: BoxShape.circle),
          child: Center(
            child: Text(
              letter,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: baseStyle.copyWith(color: colors.onContainer, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
