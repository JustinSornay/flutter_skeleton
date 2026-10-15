// comparison_readout.dart
//
// _ComparisonReadout — the right column of a ComparisonBar row: the runs of
// the localized readout template rendered as one line of styled spans
// (values in their dot colours, connector in the direction tone), followed by
// the direction tone icon, scaled down together when wider than the column.

part of "../index.dart";

/// Size of the direction tone icon after the readout.
const double _toneIconSize = 10;

/// Gap between the readout text and the tone icon.
const double _toneIconGap = kDefaultPadding / 4;

final class _ComparisonReadout extends StatelessWidget {
  const _ComparisonReadout({
    required this.parts,
    required this.baselineText,
    required this.comparisonText,
    required this.baselineColor,
    required this.comparisonColor,
    required this.connectorTone,
  });

  /// Template runs from [ComparisonBarReadout.resolve].
  final List<ComparisonBarReadoutPart> parts;

  /// Formatted baseline value (`{baseline}` and `{value}` placeholders).
  final String baselineText;

  /// Formatted comparison value (`{comparison}` placeholder).
  final String comparisonText;

  final Color baselineColor;

  final Color comparisonColor;

  /// Direction tone of the literal runs and of the trailing [StatusTone.icon];
  /// null when the values are unchanged (muted italic connector, no icon).
  final StatusTone? connectorTone;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
        .copyWith(fontSize: 11, height: 1.15);
    final StatusTone? tone = connectorTone;
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  for (final ComparisonBarReadoutPart part in parts)
                    TextSpan(text: _textOf(part), style: _styleOf(context, part, base)),
                ],
              ),
              maxLines: 1,
              softWrap: false,
            ),
            // Non-colour cue of the direction: the tone glyph (check / alert).
            if (tone != null) ...<Widget>[
              const SizedBox(width: _toneIconGap),
              Icon(tone.icon, size: _toneIconSize, color: StatusTones.colorsOf(context, tone).foreground),
            ],
          ],
        ),
      ),
    );
  }

  String _textOf(ComparisonBarReadoutPart part) {
    return switch (part.placeholder) {
      ComparisonBarReadout.baseline || ComparisonBarReadout.value => baselineText,
      ComparisonBarReadout.comparison => comparisonText,
      _ => part.text,
    };
  }

  TextStyle _styleOf(BuildContext context, ComparisonBarReadoutPart part, TextStyle base) {
    return switch (part.placeholder) {
      ComparisonBarReadout.baseline || ComparisonBarReadout.value =>
        base.copyWith(fontWeight: FontWeight.w700, color: baselineColor),
      ComparisonBarReadout.comparison => base.copyWith(fontWeight: FontWeight.w800, color: comparisonColor),
      _ => _connectorStyle(context, base),
    };
  }

  TextStyle _connectorStyle(BuildContext context, TextStyle base) {
    final StatusTone? tone = connectorTone;
    if (tone == null) {
      return base.copyWith(
        fontSize: 10,
        fontStyle: FontStyle.italic,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }
    return base.copyWith(
      fontSize: 9,
      color: StatusTones.colorsOf(context, tone).foreground,
    );
  }
}
