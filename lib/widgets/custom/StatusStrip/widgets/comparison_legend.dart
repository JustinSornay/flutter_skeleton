// comparison_legend.dart
//
// Private comparison legend of StatusStrip: a short dash + name for the
// primary series (`cs.primary`) and for the comparison series
// (`cs.tertiary`), shown under the strip in comparison mode.

part of "../index.dart";

final class _ComparisonLegend extends StatelessWidget {
  /// Primary series name (top halves).
  final String primaryLabel;

  /// Comparison series name (bottom halves).
  final String comparisonLabel;

  const _ComparisonLegend({required this.primaryLabel, required this.comparisonLabel});

  static const Size _dashSize = Size(10, 2);

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: kDefaultPadding * 1.5,
      runSpacing: kDefaultPadding / 2,
      children: <Widget>[
        _LegendItem(glyph: _dash(cs.primary), label: primaryLabel, color: cs.primary),
        _LegendItem(glyph: _dash(cs.tertiary), label: comparisonLabel, color: cs.tertiary),
      ],
    );
  }

  Widget _dash(Color color) {
    return SizedBox.fromSize(size: _dashSize, child: ColoredBox(color: color));
  }
}
