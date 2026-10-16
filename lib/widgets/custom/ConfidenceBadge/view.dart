// view.dart
//
// Tree of ConfidenceBadge: the tap Tooltip, one semantics node carrying the
// label, a 48 dp minimum hit area and the icon + label row coloured with the
// level's StatusTones foreground. The percentage is floored to a whole
// percent and uses intl's percent pattern for the current locale.

part of "index.dart";

/// Gap between the icon and the label (4 dp).
const double _iconGap = kDefaultPadding / 2;

/// How long the tooltip stays visible after a tap.
const Duration _tooltipDuration = Duration(seconds: 5);

mixin _ViewMixin {
  Widget render(BuildContext context, ConfidenceBadge widget) {
    final ConfidenceLevel level = ConfidenceBadge.levelOf(
      widget.value,
      highAt: widget.highAt,
      moderateAt: widget.moderateAt,
    );
    final String title = widget.title ?? "custom.confidence_badge.title".tr();
    final String levelText = _levelKey(level).tr();
    final String label = "custom.confidence_badge.label".tr(
      namedArgs: <String, String>{"title": title, "level": levelText},
    );
    final String? hint = widget.hint;
    final String tooltip = hint != null && hint.isNotEmpty
        ? hint
        : "custom.confidence_badge.tooltip".tr(
            namedArgs: <String, String>{
              "title": title,
              "level": levelText,
              "percent": _percent(context, ConfidenceBadge._normalize(widget.value)),
            },
          );
    final Color color = StatusTones.colorsOf(context, level.tone).foreground;

    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      waitDuration: Duration.zero,
      showDuration: _tooltipDuration,
      child: Semantics(
        label: label,
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: kMinTapTarget,
            minHeight: kMinTapTarget,
          ),
          child: _row(context, widget.icon, label, color),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String label, Color color) {
    final TextStyle baseStyle = Theme.of(context).textTheme.labelMedium ?? const TextStyle(fontSize: 12);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: color),
        const SizedBox(width: _iconGap),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: baseStyle.copyWith(fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ],
    );
  }

  String _levelKey(ConfidenceLevel level) {
    return switch (level) {
      ConfidenceLevel.high => "custom.confidence_badge.high",
      ConfidenceLevel.moderate => "custom.confidence_badge.moderate",
      ConfidenceLevel.low => "custom.confidence_badge.low",
    };
  }

  /// [value] (already in `[0, 1]`) floored to a whole percent, so a value
  /// just below a threshold never reads as the threshold (0.7999 → 79%), then
  /// formatted for the current locale; an unknown locale falls back to intl's
  /// default. The nearest whole percent is stepped down when it exceeds
  /// [value]: exact at any distance below a threshold, and immune to binary
  /// rounding (0.29 * 100 is 28.999…, still 29%).
  String _percent(BuildContext context, double value) {
    final int nearest = (value * 100).round();
    final double floored = (nearest / 100 > value ? nearest - 1 : nearest) / 100;
    final String? locale = numberLocaleOf(context);
    return NumberFormat.percentPattern(locale).format(floored);
  }
}
