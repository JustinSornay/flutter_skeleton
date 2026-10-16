// count_up_text.dart
//
// _CountUpText — value text of a StatusHeatmapRow cell that tweens from 0 to
// its value over 500 ms, or shows the value at once under reduced motion.

part of "../index.dart";

/// Duration of the count-up before [resolveMotion].
const Duration _countUpDuration = Duration(milliseconds: 500);

final class _CountUpText extends StatelessWidget {
  const _CountUpText({
    required this.value,
    required this.format,
    required this.style,
  });

  final double value;
  final StatusHeatmapValueFormatter format;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final Duration duration = resolveMotion(context, _countUpDuration);
    if (duration == Duration.zero) return _text(value);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.linear,
      builder: (BuildContext context, double current, Widget? child) => _text(current),
    );
  }

  Widget _text(double shown) => Text(format(shown), maxLines: 1, style: style);
}
