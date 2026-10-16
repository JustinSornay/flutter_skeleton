// score_row.dart
//
// Private score row of ScoreBanner: the thin determinate bar (radius 999, fill
// = tone onContainer on a track of the same colour at low alpha) and the value
// text, capped at half the row width with an ellipsis, laid out by a one-row
// Table. Exposed as one semantics node that carries the full label.

part of "../index.dart";

/// Bar thickness (5 dp, as in the original look).
const double _barHeight = 5;

/// Alpha of the track over the banner fill: a tone-derived track that stays
/// visible on every tone (≥ 1.3:1 against the banner, fill ≥ 3.3:1 against
/// the track in both AppThemes).
const double _trackAlpha = 0.18;

final class _ScoreRow extends StatelessWidget {
  /// Bar value, already clamped to `[0, 1]`.
  final double ratio;

  /// Text beside the bar.
  final String text;

  /// Label of the row's single semantics node.
  final String semanticsLabel;

  /// Bar fill, track base and text colour (the tone onContainer).
  final Color color;

  const _ScoreRow({
    required this.ratio,
    required this.text,
    required this.semanticsLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = Theme.of(context).textTheme.labelMedium ?? const TextStyle();

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: semanticsLabel,
      // A one-row Table, not a Row: the value column takes its natural width
      // capped at half the row (a longer label ends with an ellipsis) and the
      // bar column takes the rest. Unlike a LayoutBuilder, a Table still
      // reports intrinsic sizes, so the banner also works in IntrinsicHeight.
      child: Table(
        columnWidths: const <int, TableColumnWidth>{
          0: FlexColumnWidth(),
          1: FixedColumnWidth(kDefaultPadding),
          2: MinColumnWidth(IntrinsicColumnWidth(), FractionColumnWidth(0.5)),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: <TableRow>[
          TableRow(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: _barHeight,
                  backgroundColor: color.withValues(alpha: _trackAlpha),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox.shrink(),
              Text(
                text,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: textStyle.copyWith(fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
