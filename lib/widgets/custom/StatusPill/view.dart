// view.dart
//
// Tree of StatusPill: nothing for an empty label, a tone-tinted PillBadge
// for the pill, or a tone-tinted 24 × 24 circle with one semantics node for
// the compact variant. Colours come from StatusTones only.

part of "index.dart";

/// Diameter of the compact circle (24 dp).
const double _compactSize = kDefaultPadding * 3;

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

  Widget _compact(BuildContext context, StatusPill widget, String letter, ToneColors colors) {
    final TextStyle baseStyle = Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11);

    return Semantics(
      label: widget.label,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: _compactSize,
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
