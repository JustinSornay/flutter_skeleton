// stacked_bar.dart
//
// Private part of DistributionBar: the 12 dp stacked bar. One slice per
// share, sized by an integer flex; slices that round to nothing are skipped.
// Decorative only — the legend carries the data.

part of "../index.dart";

/// Height of the bar.
const double _barHeight = kDefaultPadding * 1.5;

/// Flex resolution of one slice (per-mille of the total).
const int _flexScale = 1000;

/// Fully rounded, clipped bar split into proportional slices.
final class _StackedBar extends StatelessWidget {
  /// Share of each segment, in `[0, 1]`, in display order.
  final List<double> shares;

  /// Colour of each segment, same order and length as [shares].
  final List<Color> colors;

  const _StackedBar({required this.shares, required this.colors});

  @override
  Widget build(BuildContext context) {
    final List<Widget> slices = <Widget>[];
    for (int i = 0; i < shares.length; i++) {
      final int flex = (shares[i] * _flexScale).round();
      if (flex > 0) slices.add(Expanded(flex: flex, child: ColoredBox(color: colors[i])));
    }
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: DecoratedBox(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
          child: SizedBox(
            height: _barHeight,
            child: Row(children: slices),
          ),
        ),
      ),
    );
  }
}
