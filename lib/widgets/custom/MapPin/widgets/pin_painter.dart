// pin_painter.dart
//
// Private painter of MapPin: the shape-following blurred shadow, the round
// head with its outline and the tapered wick. Every colour is resolved by
// view.dart and injected here; the painter reads no theme.

part of "../index.dart";

/// Stroke width of the head outline.
const double _kOutlineWidth = 1.5;

/// Blur radius of the drop shadow (same as a `BoxShadow.blurRadius`).
const double _kShadowBlurRadius = 8;

/// Offset of the drop shadow.
const Offset _kShadowOffset = Offset(0, 2);

/// Wick half-width, as a fraction of the box width (5 dp at 28 dp).
const double _kWickHalfWidth = 5 / 28;

/// Wick start, as a fraction of the box width (24 dp at 28 dp).
const double _kWickTop = 24 / 28;

/// Paints the pin: head circle of radius `width / 2` centred at
/// `(width / 2, width / 2)` and a wick tapering to `(width / 2, height)`.
final class _PinPainter extends CustomPainter {
  final Color fill;
  final Color outline;

  /// Shadow colour, or null for no shadow.
  final Color? shadow;

  const _PinPainter({required this.fill, required this.outline, this.shadow});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset head = Offset(radius, radius);
    final Path wick = _wick(size);

    final Color? shadowColor = shadow;
    if (shadowColor != null) {
      // Both sub-paths wind clockwise, so their overlap is filled once.
      final Path silhouette = Path()
        ..addOval(Rect.fromCircle(center: head, radius: radius))
        ..addPath(wick, Offset.zero);
      canvas.drawPath(
        silhouette.shift(_kShadowOffset),
        Paint()
          ..color = shadowColor
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            Shadow.convertRadiusToSigma(_kShadowBlurRadius),
          ),
      );
    }

    final Paint fillPaint = Paint()..color = fill;
    final Paint outlinePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kOutlineWidth;
    canvas
      ..drawCircle(head, radius, fillPaint)
      ..drawCircle(head, radius, outlinePaint)
      ..drawPath(wick, fillPaint);
  }

  /// Triangle from the lower part of the head down to the tip.
  Path _wick(Size size) {
    final double cx = size.width / 2;
    final double halfWidth = size.width * _kWickHalfWidth;
    final double top = size.width * _kWickTop;
    return Path()
      ..moveTo(cx - halfWidth, top)
      ..lineTo(cx + halfWidth, top)
      ..lineTo(cx, size.height)
      ..close();
  }

  @override
  bool shouldRepaint(_PinPainter oldDelegate) {
    return oldDelegate.fill != fill || oldDelegate.outline != outline || oldDelegate.shadow != shadow;
  }
}
