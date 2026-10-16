// view.dart
//
// Tree of IndicatorChipRow: a Wrap of IndicatorChips, 4 dp apart in both
// directions, each drawn with the entry's tone when active and the
// neutral tone when muted.

part of "index.dart";

/// Gap between chips and between runs (4 dp).
const double _gap = kDefaultPadding / 2;

mixin _ViewMixin {
  Widget render(BuildContext context, IndicatorChipRow widget) {
    return Wrap(
      spacing: _gap,
      runSpacing: _gap,
      children: <Widget>[
        for (final IndicatorChipEntry entry in widget.entries)
          IndicatorChip(
            label: entry.label,
            icon: entry.icon,
            tone: entry.active ? entry.tone : StatusTone.neutral,
            semanticsLabel: entry.semanticsLabel,
          ),
      ],
    );
  }
}
