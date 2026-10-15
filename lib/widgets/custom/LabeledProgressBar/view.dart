// view.dart
//
// Tree of LabeledProgressBar: one semantics node (label + value text) over a
// Column holding the header row (label, tone icon for a non-primary tone,
// value text) and the rounded determinate bar (track surfaceContainerHighest,
// radius 999, fill = colour override or tone foreground). Colours come from
// the ColorScheme and StatusTones only.

part of "index.dart";

/// Bar thickness (12 dp, as in the original look).
const double _barHeight = kDefaultPadding * 1.5;

/// Gap between the label and the value text, and between the header and the
/// bar (12 dp).
const double _gap = kDefaultPadding * 1.5;

/// Size of the tone icon shown before the value text (16 dp).
const double _iconSize = kDefaultPadding * 2;

/// Gap between the tone icon and the value text (4 dp).
const double _iconGap = kDefaultPadding / 2;

mixin _ViewMixin {
  Widget render(BuildContext context, LabeledProgressBar widget) {
    final double ratio = LabeledProgressBar._ratio(widget.value);
    final String text = widget.valueLabel ?? _percent(context, ratio);
    final Color fill = widget.color ?? StatusTones.colorsOf(context, widget.tone).foreground;
    // The fill shows a status tone: pair its colour with the tone glyph.
    final IconData? icon = widget.color == null && widget.tone != StatusTone.primary ? widget.tone.icon : null;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: widget.label,
      value: text,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _header(context, widget.label, text, icon, fill),
          const SizedBox(height: _gap),
          _bar(context, ratio, fill),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String label, String text, IconData? icon, Color fill) {
    final ThemeData theme = Theme.of(context);
    final Color onSurface = theme.colorScheme.onSurface;
    final TextStyle labelStyle = theme.textTheme.bodyMedium ?? const TextStyle();
    final TextStyle valueStyle = theme.textTheme.titleMedium ?? const TextStyle();

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: labelStyle.copyWith(fontWeight: FontWeight.w600, color: onSurface),
          ),
        ),
        const SizedBox(width: _gap),
        if (icon != null) ...<Widget>[
          Icon(icon, size: _iconSize, color: fill),
          const SizedBox(width: _iconGap),
        ],
        Text(
          text,
          style: valueStyle.copyWith(fontWeight: FontWeight.w800, color: onSurface),
        ),
      ],
    );
  }

  Widget _bar(BuildContext context, double ratio, Color fill) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: ratio,
        minHeight: _barHeight,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(fill),
      ),
    );
  }

  /// [ratio] (already in `[0, 1]`) as a percentage for the ambient locale;
  /// an unknown locale falls back to intl's default.
  String _percent(BuildContext context, double ratio) {
    final String? tag = Localizations.maybeLocaleOf(context)?.toLanguageTag();
    final String? locale = Intl.verifiedLocale(tag, NumberFormat.localeExists, onFailure: (String _) => null);
    return NumberFormat.percentPattern(locale).format(ratio);
  }
}
