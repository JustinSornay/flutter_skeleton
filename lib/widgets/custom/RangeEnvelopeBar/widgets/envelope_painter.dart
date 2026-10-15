// envelope_painter.dart
//
// Private painter of RangeEnvelopeBar: the rounded track and its bands, the
// series envelopes (full height with value ticks, or stacked halves), and the
// optional marker tick with its pill. Every colour is resolved by view.dart
// and injected here; the painter reads no theme.

part of "../index.dart";

/// A band resolved for painting.
typedef _BandPaint = ({double from, double to, Color color});

/// A series resolved for painting.
typedef _SeriesPaint = ({List<double> values, Color color});

/// The marker resolved for painting: tick / pill fill [color], pill text.
typedef _MarkerPaint = ({double value, String label, Color color, TextStyle textStyle});

/// Vertical slot of an envelope inside the bar.
enum _EnvelopeSlot { full, top, bottom }

final class _RangeEnvelopePainter extends CustomPainter {
  final _ValueScale scale;

  /// Track fill painted under the bands.
  final Color trackColor;

  final List<_BandPaint> bands;

  final _SeriesPaint primary;

  /// Non-null → dual layout.
  final _SeriesPaint? secondary;

  final _MarkerPaint? marker;

  /// Direction of the marker pill text.
  final TextDirection textDirection;

  _RangeEnvelopePainter({
    required this.scale,
    required this.trackColor,
    required this.bands,
    required this.primary,
    required this.secondary,
    required this.marker,
    required this.textDirection,
  });

  static const double _barRadius = 4;
  static const double _envelopeRadius = 3;
  static const double _envelopeInset = 3;
  static const double _halfEnvelopeHeight = 9;
  static const double _primaryFillAlpha = 0.28;
  static const double _secondaryFillAlpha = 0.25;
  static const double _tickWidth = 2;
  static const double _tickHalfHeight = 3;
  static const double _markerWidth = 2;
  static const double _markerOverhang = 2;
  /// Gap between the pill and the bar top; with the 12.8 dp pill it keeps
  /// the pill inside the 16 dp headroom (`_markerHeadroom`).
  static const double _pillGap = 3;
  static const double _pillPaddingH = 4;
  static const double _pillPaddingV = 1;
  static const double _pillRadius = 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;
    final Rect bar = Rect.fromLTWH(0, size.height - _barHeight, size.width, _barHeight);
    _paintTrack(canvas, bar);

    final _SeriesPaint? secondary = this.secondary;
    if (secondary == null) {
      _paintEnvelope(canvas, bar, primary, _EnvelopeSlot.full);
      _paintTicks(canvas, bar, primary);
    } else {
      _paintEnvelope(canvas, bar, primary, _EnvelopeSlot.top);
      _paintEnvelope(canvas, bar, secondary, _EnvelopeSlot.bottom);
    }

    final _MarkerPaint? marker = this.marker;
    if (marker != null) _paintMarker(canvas, bar, marker);
  }

  double _x(Rect bar, double value) => bar.left + _fractionOf(scale, value) * bar.width;

  void _paintTrack(Canvas canvas, Rect bar) {
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(bar, const Radius.circular(_barRadius)));
    canvas.drawRect(bar, Paint()..color = trackColor);
    for (final _BandPaint band in bands) {
      final Rect rect = Rect.fromLTRB(_x(bar, band.from), bar.top, _x(bar, band.to), bar.bottom);
      canvas.drawRect(rect, Paint()..color = band.color);
    }
    canvas.restore();
  }

  void _paintEnvelope(Canvas canvas, Rect bar, _SeriesPaint series, _EnvelopeSlot slot) {
    final double left = _x(bar, series.values.reduce(math.min));
    final double right = _x(bar, series.values.reduce(math.max));
    final Rect rect = switch (slot) {
      _EnvelopeSlot.full => Rect.fromLTRB(left, bar.top + _envelopeInset, right, bar.bottom - _envelopeInset),
      _EnvelopeSlot.top => Rect.fromLTRB(
          left,
          bar.top + _envelopeInset,
          right,
          bar.top + _envelopeInset + _halfEnvelopeHeight,
        ),
      _EnvelopeSlot.bottom => Rect.fromLTRB(left, bar.bottom - _halfEnvelopeHeight, right, bar.bottom),
    };
    final double fillAlpha = slot == _EnvelopeSlot.bottom ? _secondaryFillAlpha : _primaryFillAlpha;
    final RRect shape = RRect.fromRectAndRadius(rect, const Radius.circular(_envelopeRadius));
    canvas.drawRRect(shape, Paint()..color = series.color.withValues(alpha: fillAlpha));
    canvas.drawRRect(
      shape,
      Paint()
        ..color = series.color
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  void _paintTicks(Canvas canvas, Rect bar, _SeriesPaint series) {
    final double centerY = bar.center.dy;
    final Paint paint = Paint()
      ..color = series.color
      ..strokeWidth = _tickWidth;
    for (final double value in series.values) {
      final double x = _x(bar, value);
      canvas.drawLine(Offset(x, centerY - _tickHalfHeight), Offset(x, centerY + _tickHalfHeight), paint);
    }
  }

  void _paintMarker(Canvas canvas, Rect bar, _MarkerPaint marker) {
    final double inset = math.min(_markerWidth / 2, bar.width / 2);
    final double x = _x(bar, marker.value).clamp(bar.left + inset, bar.right - inset);
    final Paint fill = Paint()..color = marker.color;
    canvas.drawLine(
      Offset(x, bar.top - _markerOverhang),
      Offset(x, bar.bottom + _markerOverhang),
      fill..strokeWidth = _markerWidth,
    );

    final TextPainter text = TextPainter(
      text: TextSpan(text: marker.label, style: marker.textStyle),
      textDirection: textDirection,
      maxLines: 1,
    )..layout();
    final double pillWidth = text.width + _pillPaddingH * 2;
    final double pillHeight = text.height + _pillPaddingV * 2;
    final double pillLeft = (x - pillWidth / 2).clamp(bar.left, math.max(bar.left, bar.right - pillWidth));
    final Rect pill = Rect.fromLTWH(pillLeft, bar.top - _pillGap - pillHeight, pillWidth, pillHeight);
    canvas.drawRRect(RRect.fromRectAndRadius(pill, const Radius.circular(_pillRadius)), fill);
    text.paint(canvas, Offset(pill.left + _pillPaddingH, pill.top + _pillPaddingV));
    text.dispose();
  }

  @override
  bool shouldRepaint(covariant _RangeEnvelopePainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.trackColor != trackColor ||
        !listEquals(oldDelegate.bands, bands) ||
        !_sameSeries(oldDelegate.primary, primary) ||
        !_sameSeries(oldDelegate.secondary, secondary) ||
        oldDelegate.marker != marker ||
        oldDelegate.textDirection != textDirection;
  }

  static bool _sameSeries(_SeriesPaint? a, _SeriesPaint? b) {
    if (a == null || b == null) return a == b;
    return a.color == b.color && listEquals(a.values, b.values);
  }
}
