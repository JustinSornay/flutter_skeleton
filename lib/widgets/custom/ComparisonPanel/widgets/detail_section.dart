// detail_section.dart
//
// _DetailSection — the collapsible part of a ComparisonPanel under a thin
// `cs.tertiary` divider: the colour legend and one ComparisonBar per metric
// (when there are metrics), then the optional change callout
// (widgets/change_callout.dart).

part of "../index.dart";

/// Diameter of a legend swatch.
const double _swatchSize = 8;

final class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.current,
    required this.candidate,
    required this.metrics,
    required this.change,
  });

  final ComparisonSide current;

  final ComparisonSide candidate;

  final List<ComparisonMetric> metrics;

  final ComparisonChange? change;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ComparisonChange? change = this.change;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        kDefaultPadding * 1.5,
        kDefaultPadding * 1.25,
        kDefaultPadding * 1.5,
        kDefaultPadding * 1.5,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.tertiary, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (metrics.isNotEmpty) ...<Widget>[
            _Legend(currentTag: current.tag, candidateTag: candidate.tag),
            const SizedBox(height: kDefaultPadding),
            for (final ComparisonMetric metric in metrics) _bar(cs, metric),
          ],
          if (change != null) ...<Widget>[
            if (metrics.isNotEmpty) const SizedBox(height: kDefaultPadding),
            _ChangeCallout(change: change),
          ],
        ],
      ),
    );
  }

  /// [metric] as a ComparisonBar in the side identity colours.
  Widget _bar(ColorScheme cs, ComparisonMetric metric) {
    return ComparisonBar(
      label: metric.label,
      sublabel: metric.sublabel,
      baselineValue: metric.current,
      comparisonValue: metric.candidate,
      min: metric.min,
      max: metric.max,
      lowerIsBetter: metric.lowerIsBetter,
      formatValue: metric.format,
      baselineColor: cs.primary,
      comparisonColor: cs.tertiary,
    );
  }
}

/// End-aligned legend: one swatch + tag per side.
final class _Legend extends StatelessWidget {
  const _Legend({required this.currentTag, required this.candidateTag});

  final String currentTag;

  final String candidateTag;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        ..._entry(cs, cs.primary, currentTag),
        const SizedBox(width: kDefaultPadding * 1.25),
        ..._entry(cs, cs.tertiary, candidateTag),
      ],
    );
  }

  List<Widget> _entry(ColorScheme cs, Color color, String tag) {
    return <Widget>[
      Container(
        width: _swatchSize,
        height: _swatchSize,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: kDefaultPadding / 2),
      Flexible(
        child: Text(
          tag,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant),
        ),
      ),
    ];
  }
}
