// weight_slider_row.dart
//
// _WeightSliderRow — one component row of a WeightedScoreCard: label column,
// a continuous slider (at least kMinTapTarget high) tinted with the
// component colour, and the weight as a percentage.

part of "../index.dart";

final class _WeightSliderRow extends StatelessWidget {
  const _WeightSliderRow({
    required this.label,
    required this.weight,
    required this.percent,
    required this.color,
    required this.labelWidth,
    required this.semanticsValue,
    required this.onChanged,
  });

  final String label;

  /// Current weight, in `[0, 1]`.
  final double weight;

  /// [weight] formatted as a percentage.
  final String percent;

  /// Active track and thumb colour.
  final Color color;

  final double labelWidth;

  /// Screen-reader value of the slider for a weight.
  final String Function(double value) semanticsValue;

  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextStyle style = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface);

    return Row(
      children: <Widget>[
        SizedBox(
          width: labelWidth,
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
        ),
        Expanded(
          child: SizedBox(
            height: kMinTapTarget,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                thumbColor: color,
                inactiveTrackColor: cs.surfaceContainerHighest,
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: weight.clamp(0.0, 1.0),
                onChanged: onChanged,
                semanticFormatterCallback: semanticsValue,
              ),
            ),
          ),
        ),
        SizedBox(
          width: kDefaultPadding * 5,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(percent, style: style)),
          ),
        ),
      ],
    );
  }
}
