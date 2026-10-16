// share_donut.dart
//
// _ShareDonut — the loaded right side of a WeightedScoreCard header: an
// fl_chart donut of each component's share of the score (decorative, hidden
// from screen readers) and a legend "label  NN %" carrying the weights.

part of "../index.dart";

final class _ShareDonut extends StatelessWidget {
  const _ShareDonut({
    required this.shares,
    required this.colors,
    required this.legend,
    required this.size,
    required this.duration,
  });

  /// Share of each component; zero shares draw no slice.
  final List<double> shares;

  /// Colour of each component (slice and legend dot).
  final List<Color> colors;

  /// Legend line of each component.
  final List<String> legend;

  /// Diameter of the donut.
  final double size;

  /// Slice animation duration, already resolved for reduced motion.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        ExcludeSemantics(
          child: SizedBox.square(
            dimension: size,
            child: PieChart(
              PieChartData(
                sections: <PieChartSectionData>[
                  for (int i = 0; i < shares.length; i++)
                    if (shares[i] > 0)
                      PieChartSectionData(
                        value: shares[i] * 100,
                        color: colors[i],
                        title: "",
                        showTitle: false,
                        radius: 28,
                      ),
                ],
                centerSpaceRadius: 22,
                sectionsSpace: 2,
                startDegreeOffset: -90,
              ),
              duration: duration,
            ),
          ),
        ),
        const SizedBox(width: kDefaultPadding * 1.5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < legend.length; i++) _legendRow(context, legend[i], colors[i]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendRow(BuildContext context, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding / 2),
      child: Row(
        children: <Widget>[
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: 10,
              child: DecoratedBox(decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            ),
          ),
          const SizedBox(width: kDefaultPadding * 0.75),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
