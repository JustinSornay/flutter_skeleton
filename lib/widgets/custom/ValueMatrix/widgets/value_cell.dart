// value_cell.dart
//
// _ValueCell — one ValueMatrix value: a kMinTapTarget-tall cell with the
// formatted value (w600, scaled down to fit the cell so a wide value is never
// cut), tinted with the toneOf tone (container fill, onContainer text) or
// untinted (cs.onSurface text). A missing value shows a cs.onSurfaceVariant
// "—" announced as custom.value_matrix.no_value.

part of "../index.dart";

final class _ValueCell extends StatelessWidget {
  /// Value, or null when missing.
  final double? value;

  /// Cell text of a value.
  final String Function(double value) format;

  /// Tone of a value; null leaves the cell untinted.
  final StatusTone Function(double value)? toneOf;

  final double width;

  const _ValueCell({
    required this.value,
    required this.format,
    required this.toneOf,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final double? current = value;
    final StatusTone Function(double value)? tone = toneOf;
    final ToneColors? colors = current == null || tone == null ? null : StatusTones.colorsOf(context, tone(current));
    final TextStyle? base = theme.textTheme.bodyMedium;

    return Container(
      width: width,
      height: kMinTapTarget,
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors?.container,
        border: Border(
          right: BorderSide(color: cs.outlineVariant, width: 0.5),
          bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
      ),
      child: current == null
          ? Semantics(
              label: "custom.value_matrix.no_value".tr(),
              excludeSemantics: true,
              child: Text("—", style: base?.copyWith(color: cs.onSurfaceVariant)),
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                format(current),
                maxLines: 1,
                style: base?.copyWith(fontWeight: FontWeight.w600, color: colors?.onContainer ?? cs.onSurface),
              ),
            ),
    );
  }
}
