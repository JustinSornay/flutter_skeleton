// body_row.dart
//
// _BodyRow — one ValueMatrix row: the cs.surfaceContainerHigh row-label cell
// (one line, ellipsis) then one _ValueCell per column, all kMinTapTarget tall.

part of "../index.dart";

final class _BodyRow extends StatelessWidget {
  /// Row-label text.
  final String label;

  /// One value per column, null when missing.
  final List<double?> values;

  /// Cell text of a value.
  final String Function(double value) format;

  /// Tone of a value; null leaves the cells untinted.
  final StatusTone Function(double value)? toneOf;

  final double firstColumnWidth;

  final double columnWidth;

  const _BodyRow({
    required this.label,
    required this.values,
    required this.format,
    required this.toneOf,
    required this.firstColumnWidth,
    required this.columnWidth,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Row(
      children: <Widget>[
        Container(
          width: firstColumnWidth,
          height: kMinTapTarget,
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            border: Border(
              right: BorderSide(color: cs.outlineVariant),
              bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface),
          ),
        ),
        for (final double? value in values)
          _ValueCell(value: value, format: format, toneOf: toneOf, width: columnWidth),
      ],
    );
  }
}
