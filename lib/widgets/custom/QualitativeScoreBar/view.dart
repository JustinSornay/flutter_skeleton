// view.dart
//
// Tree of QualitativeScoreBar: one semantics node (optional prefix + level
// label) over a Column holding the level label in the tone foreground and a
// rounded determinate bar (track surfaceContainerHighest, radius 999, fill =
// tone foreground). The bar's percentage semantics are excluded.

part of "index.dart";

/// Bar thickness, kept from the original look.
const double _barHeight = 5;

mixin _ViewMixin {
  Widget render(BuildContext context, QualitativeScoreBar widget) {
    final double? value = QualitativeScoreBar._normalize(widget.value);
    final ScoreLevel? level = value == null ? null : ScoreLevel.resolve(widget.levels, value);
    final String label = level?.label ?? widget.noDataLabel ?? "custom.qualitative_score_bar.no_data".tr();
    final StatusTone tone = level?.tone ?? StatusTone.neutral;
    final Color color = StatusTones.colorsOf(context, tone).foreground;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: _semanticsLabel(widget.semanticsLabel, label),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: _labelStyle(context, color)),
          const SizedBox(height: kDefaultPadding),
          _bar(context, value ?? 0, color),
        ],
      ),
    );
  }

  TextStyle _labelStyle(BuildContext context, Color color) {
    final TextStyle base = Theme.of(context).textTheme.titleMedium ?? const TextStyle();
    return base.copyWith(fontSize: 15, fontWeight: FontWeight.w800, color: color);
  }

  Widget _bar(BuildContext context, double value, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value,
        minHeight: _barHeight,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  /// [label], prefixed with [prefix] when it is non-empty.
  String _semanticsLabel(String? prefix, String label) {
    if (prefix == null || prefix.isEmpty) return label;
    return "custom.qualitative_score_bar.semantics_label".tr(
      namedArgs: <String, String>{"prefix": prefix, "level": label},
    );
  }
}
