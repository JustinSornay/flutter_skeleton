// empty_row.dart
//
// _EmptyRow — the ExplainerSheet row shown when there is no item: a success
// dot and the label, both in the success tone foreground.

part of "../index.dart";

final class _EmptyRow extends StatelessWidget {
  final String label;

  const _EmptyRow({required this.label});

  @override
  Widget build(BuildContext context) {
    final Color color = StatusTones.colorsOf(context, StatusTone.success).foreground;
    final TextStyle style = (Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 14))
        .copyWith(fontWeight: FontWeight.w600, color: color);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ToneDot(color: color, lineHeight: _ToneDot.lineHeightOf(context, style)),
        const SizedBox(width: _dotGap),
        Expanded(child: Text(label, style: style)),
      ],
    );
  }
}
