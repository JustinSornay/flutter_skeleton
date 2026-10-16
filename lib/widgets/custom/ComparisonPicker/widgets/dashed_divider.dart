// dashed_divider.dart
//
// Labelled dashed divider that opens the secondary section of
// ComparisonPicker: cs.outline dashes on both sides of a muted label.

part of "../index.dart";

/// Length of one dash and of the gap after it.
const double _dashLength = 4;
const double _dashGap = 3;

/// Shortest dash run kept on each side of a long label.
const double _minDashRun = kDefaultPadding * 2;

final class _DashedDivider extends StatelessWidget {
  /// Divider text, already localised.
  final String label;

  const _DashedDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget dashes = CustomPaint(
      size: const Size.fromHeight(1),
      painter: _DashedPainter(color: theme.colorScheme.outline),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxLabelWidth = math.max(0, constraints.maxWidth - 2 * (_minDashRun + kDefaultPadding));
        return Row(
          children: <Widget>[
            Expanded(child: dashes),
            const SizedBox(width: kDefaultPadding),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxLabelWidth),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: kDefaultPadding),
            Expanded(child: dashes),
          ],
        );
      },
    );
  }
}

/// Horizontal dashes centred vertically in the paint area.
final class _DashedPainter extends CustomPainter {
  final Color color;

  _DashedPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final double y = size.height / 2;
    for (double x = 0; x < size.width; x += _dashLength + _dashGap) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + _dashLength, size.width), y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPainter oldDelegate) => oldDelegate.color != color;
}
