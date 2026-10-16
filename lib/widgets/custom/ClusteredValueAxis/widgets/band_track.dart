// band_track.dart
//
// _BandTrack — the 16 dp track of ClusteredValueAxis: a
// cs.surfaceContainerHighest bar (radius 4) with each visible ValueBand
// painted at its clipped span (ValueBand.resolveColor). A band label is
// exposed to screen readers only.

part of "../index.dart";

final class _BandTrack extends StatelessWidget {
  /// Bands, in the order of [spans].
  final List<ValueBand> bands;

  /// `(leftPercent, widthPercent)` of each band (ValueAxisLayout.computeBandSpans).
  final List<(double, double)> spans;

  const _BandTrack({required this.bands, required this.spans});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = constraints.maxWidth;
            return Stack(
              children: <Widget>[
                for (int i = 0; i < bands.length; i++)
                  if (spans[i].$2 > 0)
                    Positioned(
                      left: width * spans[i].$1 / 100,
                      top: 0,
                      bottom: 0,
                      width: width * spans[i].$2 / 100,
                      child: _band(context, bands[i]),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _band(BuildContext context, ValueBand band) {
    final Widget fill = ColoredBox(color: band.resolveColor(context));
    final String? label = band.label;
    if (label == null) return fill;
    return Semantics(container: true, label: label, child: fill);
  }
}
