// tone_dot.dart
//
// _ToneDot — the decorative 8 dp tone dot of ExplainerSheet rows, centred on
// the first line of the row label so it stays aligned when a caption wraps
// under the label or the text is scaled.

part of "../index.dart";

/// Diameter of the leading dot.
const double _dotSize = kDefaultPadding;

final class _ToneDot extends StatelessWidget {
  /// Fill colour (a tone `foreground`).
  final Color color;

  /// Height of the label's first line; the dot is centred in it.
  final double lineHeight;

  const _ToneDot({
    required this.color,
    required this.lineHeight,
  });

  /// Rendered height of one line of [style] under the current text scaler.
  /// A style without `height` uses 1.2, close to the platform default.
  static double lineHeightOf(BuildContext context, TextStyle style) {
    final double fontSize = MediaQuery.textScalerOf(context).scale(style.fontSize ?? 14);
    return fontSize * (style.height ?? 1.2);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _dotSize,
      height: lineHeight,
      child: Center(
        child: SizedBox.square(
          dimension: _dotSize,
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
