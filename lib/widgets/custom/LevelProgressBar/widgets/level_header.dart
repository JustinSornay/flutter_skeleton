// level_header.dart
//
// Header row of LevelProgressBar: the current level label at the start and
// the optional counter (a LevelProgressCounter, number emphasised) at the
// end. The label keeps its natural width up to half the row; the counter
// takes what the label leaves free, and the label then takes what the
// counter leaves free.

part of "../index.dart";

/// Gap between the level label and the counter (12 dp).
const double _counterGap = kDefaultPadding * 1.5;

/// Current level label (start) and optional counter (end), on one line.
final class _LevelHeader extends StatelessWidget {
  const _LevelHeader({required this.label, required this.counter});

  /// Label of the current level.
  final String label;

  /// Split counter, or null to hide it.
  final LevelProgressCounter? counter;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final TextStyle base = (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(fontSize: 13);
    final TextStyle labelStyle = base.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface);
    final Widget labelText = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: labelStyle);
    final LevelProgressCounter? runs = counter;
    if (runs == null) return Row(children: <Widget>[Flexible(child: labelText)]);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(child: labelText),
            // Laid out before the Flexible label: bounded so the label keeps
            // its natural width up to half the row.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _counterMaxWidth(context, constraints.maxWidth, labelStyle)),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: _counterGap),
                child: Text.rich(
                  TextSpan(
                    style: base.copyWith(fontWeight: FontWeight.w400, color: cs.onSurfaceVariant),
                    children: <TextSpan>[
                      TextSpan(text: runs.before),
                      TextSpan(
                        text: runs.count,
                        style: TextStyle(fontWeight: FontWeight.w800, color: cs.primary),
                      ),
                      TextSpan(text: runs.after),
                    ],
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Widest the counter may be, gap included, in a row of [rowWidth]: the
  /// row minus the label's natural width, the label reserving at most half
  /// of the row after the gap. Measured as [Text] would render the label.
  double _counterMaxWidth(BuildContext context, double rowWidth, TextStyle labelStyle) {
    final double labelWidth = TextPainter.computeMaxIntrinsicWidth(
      text: TextSpan(text: label, style: DefaultTextStyle.of(context).style.merge(labelStyle)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 1,
    );
    // Rounded up so floating-point noise never ellipsizes a label that fits.
    return rowWidth - math.min(labelWidth.ceilToDouble(), (rowWidth - _counterGap) / 2);
  }
}
