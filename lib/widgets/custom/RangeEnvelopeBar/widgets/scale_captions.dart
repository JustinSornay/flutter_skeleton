// scale_captions.dart
//
// Private caption row of RangeEnvelopeBar: each band label centred under its
// band (positioned on the same linear scale as the painter), with the
// formatted min and max values pinned to the left and right edges.

part of "../index.dart";

final class _ScaleCaptions extends StatelessWidget {
  /// Scale shared with the painter.
  final _ValueScale scale;

  /// Bands whose `label` is captioned (null labels are skipped).
  final List<ValueBand> bands;

  /// Text pinned to the left edge.
  final String minLabel;

  /// Text pinned to the right edge.
  final String maxLabel;

  const _ScaleCaptions({
    required this.scale,
    required this.bands,
    required this.minLabel,
    required this.maxLabel,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle style = (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
      fontSize: 8,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            for (final ValueBand band in bands) ?_bandCaption(band, width, style),
            // Non-positioned: gives the row its width and text height.
            Align(
              alignment: Alignment.centerLeft,
              child: Text(minLabel, style: style, maxLines: 1),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Text(maxLabel, style: style, maxLines: 1),
            ),
          ],
        );
      },
    );
  }

  /// Caption centred over the band's span, or null when the band has no
  /// label or lies outside the scale.
  Widget? _bandCaption(ValueBand band, double width, TextStyle style) {
    final String? label = band.label;
    final double left = _fractionOf(scale, band.from) * width;
    final double right = _fractionOf(scale, band.to) * width;
    if (label == null || right <= left) return null;
    return Positioned(
      top: 0,
      left: left,
      width: right - left,
      child: Text(
        label,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}
