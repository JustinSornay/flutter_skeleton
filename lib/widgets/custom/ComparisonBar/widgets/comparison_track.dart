// comparison_track.dart
//
// _ComparisonTrack — the middle of a ComparisonBar row: a pill track, the
// gradient segment between the two values and the two ringed dots, placed
// from 0..1 positions computed by ComparisonBar.

part of "../index.dart";

/// Height of the track area; the dots overflow the 5 dp track inside it.
const double _trackAreaHeight = 14;

/// Thickness of the track and of the segment.
const double _trackThickness = 5;

/// Diameter of a dot, ring included.
const double _dotSize = 10;

/// Width of the `cs.surface` ring around a dot.
const double _dotRing = 2;

/// Shared bar radius (pill).
const BorderRadius _pill = BorderRadius.all(Radius.circular(999));

final class _ComparisonTrack extends StatelessWidget {
  const _ComparisonTrack({
    required this.baselinePosition,
    required this.comparisonPosition,
    required this.baselineColor,
    required this.comparisonColor,
    required this.showSegment,
  });

  /// Baseline dot centre, `0..1` of the track width.
  final double baselinePosition;

  /// Comparison dot centre, `0..1` of the track width.
  final double comparisonPosition;

  final Color baselineColor;

  final Color comparisonColor;

  /// False when the values are unchanged: no segment between the dots.
  final bool showSegment;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    // LayoutBuilder wraps the Stack so every Positioned stays a direct Stack
    // child (Stack parent data).
    return SizedBox(
      height: _trackAreaHeight,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: <Widget>[
              _bar(BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: _pill)),
              if (showSegment) _segment(width),
              _dot(width, baselinePosition, baselineColor, cs.surface),
              _dot(width, comparisonPosition, comparisonColor, cs.surface),
            ],
          );
        },
      ),
    );
  }

  /// Segment between both dots, its gradient running from the left dot
  /// colour to the right dot colour.
  Widget _segment(double width) {
    final bool baselineFirst = baselinePosition <= comparisonPosition;
    final double start = math.min(baselinePosition, comparisonPosition);
    final double end = math.max(baselinePosition, comparisonPosition);
    return Positioned(
      left: width * start,
      width: width * (end - start),
      child: _bar(
        BoxDecoration(
          gradient: LinearGradient(
            colors: baselineFirst
                ? <Color>[baselineColor, comparisonColor]
                : <Color>[comparisonColor, baselineColor],
          ),
          borderRadius: _pill,
        ),
      ),
    );
  }

  Widget _bar(BoxDecoration decoration) {
    return SizedBox(
      width: double.infinity,
      height: _trackThickness,
      child: DecoratedBox(decoration: decoration),
    );
  }

  Widget _dot(double width, double position, Color color, Color ring) {
    return Positioned(
      left: width * position - _dotSize / 2,
      child: SizedBox.square(
        dimension: _dotSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: ring, width: _dotRing),
          ),
        ),
      ),
    );
  }
}
