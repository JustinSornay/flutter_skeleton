// picker_row.dart
//
// One ComparisonPicker row: its own Material (slot-tinted fill and border),
// the leading slot control, the label / subtitle texts and the optional value
// (plain text or StatusTones pill with a labelled tone icon, capped at half
// the text width). A locked-A secondary row is also one tappable toggle node
// for slot B.

part of "../index.dart";

/// Corner radius of a row and of the add button.
const double _rowRadius = 8;

/// Vertical gap below each row.
const double _rowGap = kDefaultPadding / 2;

/// Border width of a row holding a slot, and of the other rows.
const double _selectedBorderWidth = 1;
const double _idleBorderWidth = 0.5;

/// Minimum width of a plain value, so values line up in a column.
const double _valueMinWidth = kDefaultPadding * 5;

/// Largest share of the text width a value may take; longer values end with
/// an ellipsis.
const double _valueMaxWidthFactor = 0.5;

/// Size of the tone icon in a value pill.
const double _toneIconSize = 12;

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
    final String? valueLabel = item.valueLabel;
    final StatusTone? tone = item.tone;
    final bool hasValue = (valueLabel != null && valueLabel.isNotEmpty) || tone != null;

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
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: constraints.maxWidth * _valueMaxWidthFactor),
                          child: _RowValue(
                            valueLabel: valueLabel,
                            tone: tone,
                            toneLabel: item.toneLabel,
                            color: foreground,
                          ),
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

/// End-of-row value: a StatusTones pill (tone icon + text) when [tone] is
/// set, plain bold text in [color] otherwise. Single line, ellipsised to the
/// width its parent allows.
final class _RowValue extends StatelessWidget {
  final String? valueLabel;

  final StatusTone? tone;

  /// Name of [tone]: the icon's semantics label when there is a
  /// [valueLabel], or the pill text when there is none.
  final String? toneLabel;

  /// Text colour of a plain value.
  final Color color;

  const _RowValue({required this.valueLabel, required this.tone, required this.toneLabel, required this.color});

  @override
  Widget build(BuildContext context) {
    final StatusTone? tone = this.tone;
    final String? valueLabel = this.valueLabel;
    final bool hasValueText = valueLabel != null && valueLabel.isNotEmpty;
    final TextStyle? style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w800);

    if (tone == null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minWidth: _valueMinWidth),
        child: Text(
          valueLabel ?? "",
          textAlign: TextAlign.end,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style?.copyWith(color: color),
        ),
      );
    }

    // The visible text is the value, else the tone name; the icon speaks the
    // tone name only when the text does not already say it.
    final String text = hasValueText ? valueLabel : (toneLabel ?? "");
    final ToneColors colors = StatusTones.colorsOf(context, tone);
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.container, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding / 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              tone.icon,
              size: _toneIconSize,
              color: colors.onContainer,
              semanticLabel: hasValueText ? toneLabel : null,
            ),
            if (text.isNotEmpty) ...<Widget>[
              const SizedBox(width: kDefaultPadding / 2),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style?.copyWith(color: colors.onContainer),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
