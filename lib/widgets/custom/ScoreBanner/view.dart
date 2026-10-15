// view.dart
//
// Tree of ScoreBanner: one semantics container over the tone `container`
// box (radius 8), holding the decorative icon circle, the message, the score
// row, the optional note pill and the optional link. Colours come from
// StatusTones only.

part of "index.dart";

/// Corner radius of the banner and of the link ink (8 dp).
const double _radius = kDefaultPadding;

/// Inner padding of the banner (24 dp horizontal, 16 dp vertical).
const EdgeInsetsDirectional _padding = EdgeInsetsDirectional.symmetric(
  horizontal: kDefaultPadding * 3,
  vertical: kDefaultPadding * 2,
);

/// Diameter of the icon circle.
const double _iconCircleSize = 30;

/// Size of the glyph inside the icon circle.
const double _glyphSize = 16;

/// Gap between the icon circle and the text column (12 dp).
const double _iconGap = kDefaultPadding * 1.5;

/// Vertical gap between the message, the score row, the note and the link.
const double _rowGap = kDefaultPadding;

mixin _ViewMixin {
  Widget render(BuildContext context, ScoreBanner widget) {
    final ToneColors colors = StatusTones.colorsOf(context, widget.tone);
    final VoidCallback? onLink = widget.onLink;

    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.container,
          borderRadius: BorderRadius.circular(_radius),
        ),
        child: Padding(
          padding: _padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _iconCircle(widget.icon ?? widget.tone.icon, colors),
                  const SizedBox(width: _iconGap),
                  Expanded(child: _body(context, widget, colors)),
                ],
              ),
              if (onLink != null) ...<Widget>[
                const SizedBox(height: _rowGap),
                _BannerLink(
                  label: widget.linkLabel ?? "custom.score_banner.link".tr(),
                  color: colors.onContainer,
                  onTap: onLink,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Decorative filled circle: `onContainer` fill, `container` glyph.
  Widget _iconCircle(IconData icon, ToneColors colors) {
    return ExcludeSemantics(
      child: Container(
        width: _iconCircleSize,
        height: _iconCircleSize,
        decoration: BoxDecoration(color: colors.onContainer, shape: BoxShape.circle),
        child: Icon(icon, size: _glyphSize, color: colors.container),
      ),
    );
  }

  /// Message, score row and optional note.
  Widget _body(BuildContext context, ScoreBanner widget, ToneColors colors) {
    final TextStyle messageStyle = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final double ratio = ScoreBanner._ratio(widget.value);
    final Map<String, String> args = <String, String>{"value": "${(ratio * 100).round()}"};
    final String? valueLabel = widget.valueLabel;
    final ScoreBannerNote? note = widget.note;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.message,
          style: messageStyle.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: colors.onContainer,
          ),
        ),
        const SizedBox(height: _rowGap),
        _ScoreRow(
          ratio: ratio,
          text: valueLabel ?? "custom.score_banner.value".tr(namedArgs: args),
          semanticsLabel: valueLabel ?? "custom.score_banner.value_semantics".tr(namedArgs: args),
          color: colors.onContainer,
        ),
        if (note != null) ...<Widget>[
          const SizedBox(height: _rowGap),
          _NotePill(note: note),
        ],
      ],
    );
  }
}
