// score_row.dart
//
// Private score row of ScoreBanner: the thin determinate bar (radius 999, fill
// = tone onContainer on a track of the same colour at low alpha) and the value
// text, capped at half the row width with an ellipsis. Exposed as one
// semantics node that carries the full label.

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
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Row(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: _barHeight,
                    backgroundColor: color.withValues(alpha: _trackAlpha),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: kDefaultPadding),
              // A long label is cut at half the row so the bar keeps the
              // other half; the semantics label above keeps the full text.
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
                child: Text(
                  text,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle.copyWith(fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
