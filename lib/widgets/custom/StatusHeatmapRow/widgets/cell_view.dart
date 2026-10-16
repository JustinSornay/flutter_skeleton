// cell_view.dart
//
// _CellView — one tinted cell of StatusHeatmapRow: the (count-up) value, the
// caption and the status icon, exposed as a single semantics node.

part of "../index.dart";

/// Minimum height of a cell.
const double _cellMinHeight = 72;

/// Corner radius of a cell.
const double _cellRadius = 8;

/// Alpha of the tone fill.
const double _fillAlpha = 0.1;

/// Alpha of the tone border.
const double _borderAlpha = 0.25;

/// Size of the status icon.
const double _iconSize = 14;

/// Placeholder shown instead of a missing value.
const String _emptyValue = "—";

final class _CellView extends StatelessWidget {
  const _CellView({required this.cell, required this.format});

  final StatusHeatmapCell cell;
  final StatusHeatmapValueFormatter format;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color color = StatusTones.colorsOf(context, cell.tone).foreground;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: _semanticsLabel(),
      child: Container(
        constraints: const BoxConstraints(minHeight: _cellMinHeight),
        decoration: BoxDecoration(
          color: color.withValues(alpha: _fillAlpha),
          borderRadius: BorderRadius.circular(_cellRadius),
          border: Border.all(color: color.withValues(alpha: _borderAlpha)),
        ),
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FittedBox(fit: BoxFit.scaleDown, child: _value(color)),
            const SizedBox(height: kDefaultPadding / 2),
            Text(
              cell.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: kDefaultPadding / 2),
            Icon(cell.icon ?? cell.tone.icon, size: _iconSize, color: color),
          ],
        ),
      ),
    );
  }

  Widget _value(Color color) {
    final TextStyle style = TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color);
    final double? value = cell.value;
    if (value == null) return Text(_emptyValue, maxLines: 1, style: style);
    return _CountUpText(value: value, format: format, style: style);
  }

  String _semanticsLabel() {
    final double? value = cell.value;
    if (value == null) {
      return "${cell.label}, ${"custom.status_heatmap_row.no_value".tr()}";
    }
    return "${cell.label}, ${format(value)}, ${cell.statusLabel ?? ""}";
  }
}
