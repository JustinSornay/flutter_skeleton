// spread_pill.dart
//
// Private pill of RangeEnvelopeBar: the spread label, upper-cased, on the tone
// container colour with onContainer text. Screen readers get the original
// casing.

part of "../index.dart";

final class _SpreadPill extends StatelessWidget {
  /// Text, shown upper-cased.
  final String label;

  /// Fill (`container`) and text (`onContainer`) tone.
  final StatusTone tone;

  const _SpreadPill({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final ToneColors colors = StatusTones.colorsOf(context, tone);
    final TextStyle style = (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
      fontSize: 8,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
      color: colors.onContainer,
    );

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.container,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding,
            vertical: kDefaultPadding / 4,
          ),
          child: Text(label.toUpperCase(), style: style),
        ),
      ),
    );
  }
}
