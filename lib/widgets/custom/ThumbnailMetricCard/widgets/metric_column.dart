// metric_column.dart
//
// _MetricColumn — one value column of ThumbnailMetricCard: the small muted
// label over the value, with the optional StatusTone.icon marker (tone
// foreground, announced as the tone label) before the value.

part of "../index.dart";

/// Gap between the label and the value line (2 dp).
const double _labelGap = kDefaultPadding / 4;

/// Size of the tone marker.
const double _markerSize = 12;

/// Gap between the tone marker and the value (4 dp).
const double _markerGap = kDefaultPadding / 2;

final class _MetricColumn extends StatelessWidget {
  /// Column to draw.
  final ThumbnailMetric metric;

  const _MetricColumn({required this.metric});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final StatusTone? tone = metric.tone;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          metric.label,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: _labelGap),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // A status tint is paired with the tone glyph, never colour alone.
            if (tone != null) ...<Widget>[
              Icon(
                tone.icon,
                size: _markerSize,
                color: StatusTones.colorsOf(context, tone).foreground,
                semanticLabel: _nonEmpty(metric.toneLabel),
              ),
              const SizedBox(width: _markerGap),
            ],
            Text(
              metric.value,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.onSurface),
            ),
          ],
        ),
      ],
    );
  }
}
