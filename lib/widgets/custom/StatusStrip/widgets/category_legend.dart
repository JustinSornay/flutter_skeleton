// category_legend.dart
//
// Private category legend of StatusStrip: one dot + label per category
// present (in the given order), then the agreement marker entries, each only
// when its marker is shown in the strip.

part of "../index.dart";

/// A legend entry resolved by the view: category [label] and fill [color].
typedef _LegendEntry = ({String label, Color color});

final class _CategoryLegend extends StatelessWidget {
  /// Categories present, in legend order.
  final List<_LegendEntry> entries;

  /// Adds the partial-agreement entry (corner dot).
  final bool showPartial;

  /// Adds the full-disagreement entry (dashed outline).
  final bool showFull;

  const _CategoryLegend({required this.entries, required this.showPartial, required this.showFull});

  static const double _dotSize = 8;
  static const Size _outlineSize = Size(14, 10);

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: kDefaultPadding,
      runSpacing: kDefaultPadding / 2,
      children: <Widget>[
        for (final _LegendEntry entry in entries)
          _LegendItem(
            glyph: SizedBox.square(
              dimension: _dotSize,
              child: DecoratedBox(decoration: BoxDecoration(color: entry.color, shape: BoxShape.circle)),
            ),
            label: entry.label,
            color: cs.onSurfaceVariant,
          ),
        if (showPartial)
          _LegendItem(
            glyph: const _PartialMarker(),
            label: "custom.status_strip.partial_agreement".tr(),
            color: cs.onSurfaceVariant,
          ),
        if (showFull)
          _LegendItem(
            glyph: CustomPaint(size: _outlineSize, painter: _DashedOutlinePainter(color: cs.error)),
            label: "custom.status_strip.full_disagreement".tr(),
            color: cs.onSurfaceVariant,
          ),
      ],
    );
  }
}
