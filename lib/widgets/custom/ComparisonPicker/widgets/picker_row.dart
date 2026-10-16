// picker_row.dart
//
// One ComparisonPicker row: its own Material (slot-tinted fill and border),
// the leading slot control, the label / subtitle texts and the optional value
// (plain text or a StatusTones pill led by the tone icon, capped at half the
// text width; or a tone-label pill followed by the plain value, capped at
// 70 % of it, the pill taking what the value leaves). A locked-A secondary
// row is also one tappable toggle node for slot B.

part of "../index.dart";

/// Corner radius of a row and of the add button.
const double _rowRadius = 8;

/// Vertical gap below each row.
const double _rowGap = kDefaultPadding / 2;

/// Border width of a row holding a slot, and of the other rows.
const double _selectedBorderWidth = 1;
const double _idleBorderWidth = 0.5;

/// Minimum width of a lone plain value, so values line up in a column.
const double _valueMinWidth = kDefaultPadding * 5;

/// Largest share of the text width a lone value (plain text or pill) may
/// take; longer values end with an ellipsis.
const double _valueMaxWidthFactor = 0.5;

/// Largest share of the text width a tone pill followed by a plain value may
/// take together; the label keeps the rest.
const double _pairMaxWidthFactor = 0.7;

/// Largest share of the text width the plain value after a pill may take
/// (it takes its natural width up to that); the pill gets what it leaves.
const double _pairValueMaxWidthFactor = 0.25;

/// Size of the tone icon in a value pill.
const double _toneIconSize = 12;

/// Gap between the tone pill and the plain value that follows it.
const double _pillValueGap = kDefaultPadding / 2;

/// [text], or null when it is null or empty, so an empty string is treated
/// as a missing one.
String? _nonEmpty(String? text) => (text == null || text.isEmpty) ? null : text;

/// Whole-row toggle of a locked-A secondary row.
final class _RowToggle {
  /// Spoken label ("Select {label} as B").
  final String semanticsLabel;

  /// Whether the row holds slot B.
  final bool checked;

  /// Null in read-only mode.
  final VoidCallback? onTap;

  const _RowToggle({required this.semanticsLabel, required this.checked, this.onTap});
}

final class _PickerRow extends StatelessWidget {
  final ComparisonPickerItem item;

  /// Slot held by the row, if any.
  final _Slot? selected;

  /// Slot control at the start (radios or a dot).
  final Widget leading;

  /// Set on locked-A secondary rows only.
  final _RowToggle? toggle;

  const _PickerRow({required this.item, required this.selected, required this.leading, this.toggle});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final (Color fill, Color border, Color foreground) = switch (selected) {
      _Slot.a => (cs.primaryContainer, cs.primary, cs.onPrimaryContainer),
      _Slot.b => (cs.tertiaryContainer, cs.tertiary, cs.onTertiaryContainer),
      null => (cs.surface, cs.outlineVariant, cs.onSurface),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: _rowGap),
      child: Material(
        color: fill,
        animationDuration: Duration.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_rowRadius),
          side: BorderSide(color: border, width: selected == null ? _idleBorderWidth : _selectedBorderWidth),
        ),
        child: _tappable(_body(context, foreground)),
      ),
    );
  }

  /// Wraps [body] in the slot-B toggle node of a locked-A secondary row.
  Widget _tappable(Widget body) {
    final _RowToggle? toggle = this.toggle;
    if (toggle == null) return body;
    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: toggle.checked,
      enabled: toggle.onTap != null,
      label: toggle.semanticsLabel,
      child: InkWell(onTap: toggle.onTap, child: body),
    );
  }

  Widget _body(BuildContext context, Color foreground) {
    final String? valueLabel = _nonEmpty(item.valueLabel);
    final String? toneLabel = _nonEmpty(item.toneLabel);
    final StatusTone? tone = item.tone;
    // A tone is drawn only with a text to pair it with.
    final bool hasValue = valueLabel != null || (tone != null && toneLabel != null);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kMinTapTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
        child: Row(
          children: <Widget>[
            leading,
            const SizedBox(width: kDefaultPadding),
            Expanded(
              child: MergeSemantics(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) => Row(
                    children: <Widget>[
                      Expanded(child: _texts(context, foreground)),
                      if (hasValue) ...<Widget>[
                        const SizedBox(width: kDefaultPadding),
                        _RowValue(
                          valueLabel: valueLabel,
                          tone: tone,
                          toneLabel: toneLabel,
                          color: foreground,
                          areaWidth: constraints.maxWidth,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _texts(BuildContext context, Color foreground) {
    final ThemeData theme = Theme.of(context);
    final String? subtitle = item.subtitle;
    final TextStyle? base = theme.textTheme.bodySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          item.label,
          style: base?.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: foreground),
        ),
        if (subtitle != null && subtitle.isNotEmpty)
          Text(
            subtitle,
            style: base?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: selected == null ? theme.colorScheme.onSurfaceVariant : foreground,
            ),
          ),
      ],
    );
  }
}

/// End-of-row value on single ellipsised lines, sized from [areaWidth], the
/// text width it shares with the label:
/// - no [tone]: [valueLabel] as plain bold text in [color], at most half of
///   [areaWidth];
/// - a [tone] and one text: a StatusTones pill led by the tone icon, holding
///   [toneLabel] (else [valueLabel]), at most half of [areaWidth];
/// - a [tone] and both texts: the [toneLabel] pill, then [valueLabel] as
///   plain text at its natural width, at most a quarter of [areaWidth]; the
///   pill takes what the value leaves of 70 % of [areaWidth].
///
/// Reading order: tone label, then value; the icon is decorative.
final class _RowValue extends StatelessWidget {
  /// Non-empty or null.
  final String? valueLabel;

  final StatusTone? tone;

  /// Non-empty or null. Ignored without [tone].
  final String? toneLabel;

  /// Text colour of a plain value.
  final Color color;

  /// Width of the text area the value shares with the label.
  final double areaWidth;

  const _RowValue({
    required this.valueLabel,
    required this.tone,
    required this.toneLabel,
    required this.color,
    required this.areaWidth,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w800);
    final StatusTone? tone = this.tone;
    final String? valueLabel = this.valueLabel;
    final String? toneLabel = this.toneLabel;
    if (tone == null) {
      return _capped(_valueMaxWidthFactor, _plain(valueLabel ?? "", style, minWidth: _valueMinWidth));
    }
    if (toneLabel == null || valueLabel == null) {
      return _capped(_valueMaxWidthFactor, _pill(context, tone, toneLabel ?? valueLabel ?? "", style));
    }
    return _capped(
      _pairMaxWidthFactor,
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // A Flexible is laid out after its siblings: the pill gets
          // everything the capped value leaves.
          Flexible(child: _pill(context, tone, toneLabel, style)),
          const SizedBox(width: _pillValueGap),
          _capped(_pairValueMaxWidthFactor, _plain(valueLabel, style)),
        ],
      ),
    );
  }

  /// [child], at most [factor] × [areaWidth] wide.
  Widget _capped(double factor, Widget child) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: areaWidth * factor),
      child: child,
    );
  }

  /// Plain bold value, right-aligned, at least [minWidth] wide (so lone
  /// values line up in a column).
  Widget _plain(String text, TextStyle? style, {double minWidth = 0}) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: Text(
        text,
        textAlign: TextAlign.end,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style?.copyWith(color: color),
      ),
    );
  }

  /// StatusTones pill: the decorative tone icon, then [text], drawn as one
  /// ellipsised line (the icon is a placeholder in the span), so a squeezed
  /// pill cuts its text instead of overflowing.
  Widget _pill(BuildContext context, StatusTone tone, String text, TextStyle? style) {
    final ToneColors colors = StatusTones.colorsOf(context, tone);
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.container, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding / 4),
        child: Text.rich(
          TextSpan(
            children: <InlineSpan>[
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: kDefaultPadding / 2),
                  child: Icon(tone.icon, size: _toneIconSize, color: colors.onContainer),
                ),
              ),
              TextSpan(text: text),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style?.copyWith(color: colors.onContainer),
        ),
      ),
    );
  }
}
