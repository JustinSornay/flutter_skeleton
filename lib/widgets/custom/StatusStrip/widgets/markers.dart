// markers.dart
//
// Private agreement markers of StatusStrip, shared by the cells and the
// legend: the partial-agreement corner dot (warning tone foreground, sized by
// the caller so it fits narrow cells) and the dashed outline painter of full
// disagreement (colour injected by the caller, `cs.error`; drawn at any size).

part of "../index.dart";

/// Dot in the warning tone `foreground`, [maxSize] (5 dp) unless the cell
/// is too small for it.
final class _PartialMarker extends StatelessWidget {
  /// Diameter of the dot.
  final double size;

  const _PartialMarker({this.size = maxSize});

  static const double maxSize = 5;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: StatusTones.colorsOf(context, StatusTone.warning).foreground,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Dashed rectangle with cut corners around the painted area. The corner
/// cut shrinks to a quarter of the shortest side on small areas, so every
/// side keeps a visible dash down to a few pixels.
final class _DashedOutlinePainter extends CustomPainter {
  final Color color;

  _DashedOutlinePainter({required this.color});

  static const double _strokeWidth = 1.5;
  static const double _dash = 3;
  static const double _gap = 2.5;
  static const double _corner = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final double corner = math.min(_corner, size.shortestSide / 4);
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;
    final double w = size.width;
    final double h = size.height;
    _dashLine(canvas, paint, Offset(corner, 0), Offset(w - corner, 0));
    _dashLine(canvas, paint, Offset(w, corner), Offset(w, h - corner));
    _dashLine(canvas, paint, Offset(w - corner, h), Offset(corner, h));
    _dashLine(canvas, paint, Offset(0, h - corner), Offset(0, corner));
  }

  void _dashLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    final Offset delta = end - start;
    final double length = delta.distance;
    for (double drawn = 0; drawn < length; drawn += _dash + _gap) {
      final double segmentEnd = math.min(drawn + _dash, length);
      canvas.drawLine(start + delta * (drawn / length), start + delta * (segmentEnd / length), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedOutlinePainter oldDelegate) => oldDelegate.color != color;
}
