// view.dart
//
// Tree of DistributionBar: the stacked bar and the legend in a padded body,
// hosted by a SectionCard when a title is set, else by a bare card with
// SectionCard's panel tokens. Resolves the shares, the segment colours and
// the localised percentages, and delegates the bar and the legend entries to
// the private parts in widgets/.

part of "index.dart";

/// Corner radius of the untitled card, matching SectionCard's panel.
const double _cardRadius = 12;

/// Colour cycle for segments without a colour or tone. Every token reaches at
/// least 3:1 against the card (`surfaceContainerLow`) in both brightnesses of
/// AppTheme (WCAG 1.4.11); the on-container tokens revisit the primary and
/// tertiary hues at a contrasting tone.
List<Color> _paletteOf(ColorScheme cs) {
  return <Color>[
    cs.primary,
    cs.tertiary,
    cs.secondary,
    cs.error,
    cs.onPrimaryContainer,
    cs.onTertiaryContainer,
    cs.outline,
  ];
}

mixin _ViewMixin {
  Widget render(BuildContext context, DistributionBar widget) {
    final double total = widget.segments.fold<double>(
      0,
      (double sum, DistributionBarSegment segment) => sum + segment.value,
    );
    if (total <= 0) return const SizedBox.shrink();

    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<double> shares = <double>[
      for (final DistributionBarSegment segment in widget.segments) segment.value / total,
    ];
    final List<Color> colors = _segmentColors(context, widget.segments);
    final Widget body = Padding(
      padding: const EdgeInsets.all(kDefaultPadding * 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _StackedBar(shares: shares, colors: colors),
          const SizedBox(height: kDefaultPadding * 1.5),
          _legend(context, widget, shares, colors),
        ],
      ),
    );

    final String? title = widget.title;
    if (title != null) return SectionCard(title: title, children: <Widget>[body]);
    return _untitledCard(cs, body);
  }

  /// Bare card for the untitled case (SectionCard requires a title), with
  /// SectionCard's panel tokens.
  Widget _untitledCard(ColorScheme cs, Widget body) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: body,
    );
  }

  /// One legend entry per segment, wrapping onto as many runs as needed.
  Widget _legend(BuildContext context, DistributionBar widget, List<double> shares, List<Color> colors) {
    return Wrap(
      spacing: kDefaultPadding * 1.5,
      runSpacing: kDefaultPadding * 0.75,
      children: <Widget>[
        for (int i = 0; i < widget.segments.length; i++)
          _LegendEntry(
            color: colors[i],
            text: _legendText(context, widget, widget.segments[i], shares[i]),
          ),
      ],
    );
  }

  /// Host-built legend text, or `"label · <percent>"`.
  String _legendText(BuildContext context, DistributionBar widget, DistributionBarSegment segment, double share) {
    final String Function(DistributionBarSegment segment, double share)? builder = widget.legendTextBuilder;
    if (builder != null) return builder(segment, share);
    return "${segment.label} · ${_percent(context, share)}";
  }

  /// Segment colour: explicit colour, else tone foreground, else the
  /// `ColorScheme` cycle by index.
  List<Color> _segmentColors(BuildContext context, List<DistributionBarSegment> segments) {
    final List<Color> palette = _paletteOf(Theme.of(context).colorScheme);
    return <Color>[
      for (int i = 0; i < segments.length; i++)
        segments[i].color ?? _toneColor(context, segments[i].tone) ?? palette[i % palette.length],
    ];
  }

  Color? _toneColor(BuildContext context, StatusTone? tone) {
    return tone == null ? null : StatusTones.colorsOf(context, tone).foreground;
  }

  /// [share] (in `[0, 1]`) as a percentage for the ambient locale; an unknown
  /// locale falls back to intl's default.
  String _percent(BuildContext context, double share) {
    final String? locale = numberLocaleOf(context);
    return NumberFormat.percentPattern(locale).format(share);
  }
}
