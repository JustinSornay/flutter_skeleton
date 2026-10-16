// view.dart
//
// Tree of TrendSplitSection: a Row of two cards (rising left, falling right),
// each with a tinted header (arrow icon + uppercased title) and its rows
// (label + StatusPill, capped so the label keeps a minimum width) or the
// empty placeholder. Colours come from the ColorScheme and StatusTones only.

part of "index.dart";

/// Card corner radius.
const double _radius = 10;

/// Header and body inset, and the divider height between rows (12 dp).
const double _inset = kDefaultPadding * 1.5;

/// Header icon size.
const double _headerIconSize = 14;

/// Letter spacing of the uppercased header title.
const double _titleTracking = 0.8;

/// Width a row always leaves to its label (32 dp). The pill takes what it
/// needs up to the rest of the row, then its text ellipsizes instead of
/// pushing the row out of its card.
const double _minLabelWidth = kDefaultPadding * 4;

/// Everything one card needs: resolved title, header icon, tone and entries.
final class _TrendColumn {
  final String title;
  final IconData headerIcon;
  final StatusTone tone;
  final List<TrendEntry> entries;

  const _TrendColumn({
    required this.title,
    required this.headerIcon,
    required this.tone,
    required this.entries,
  });
}

mixin _ViewMixin {
  Widget render(BuildContext context, TrendSplitSection widget) {
    final String? tag = Localizations.maybeLocaleOf(context)?.toLanguageTag();
    final String Function(double delta) format =
        widget.format ?? (double delta) => TrendSplitSection.defaultFormat(delta, locale: tag);
    final String empty = widget.emptyLabel ?? "custom.trend_split_section.empty".tr();

    final _TrendColumn rising = _TrendColumn(
      title: widget.risingTitle ?? "custom.trend_split_section.rising".tr(),
      headerIcon: Icons.trending_up_rounded,
      tone: widget.higherIsBetter ? StatusTone.success : StatusTone.danger,
      entries: widget.rising,
    );
    final _TrendColumn falling = _TrendColumn(
      title: widget.fallingTitle ?? "custom.trend_split_section.falling".tr(),
      headerIcon: Icons.trending_down_rounded,
      tone: widget.higherIsBetter ? StatusTone.danger : StatusTone.success,
      entries: widget.falling,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: _card(context, rising, empty, format)),
        const SizedBox(width: kDefaultPadding),
        Expanded(child: _card(context, falling, empty, format)),
      ],
    );
  }

  Widget _card(
    BuildContext context,
    _TrendColumn column,
    String empty,
    String Function(double delta) format,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final BorderRadius radius = BorderRadius.circular(_radius);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: radius),
      foregroundDecoration: BoxDecoration(borderRadius: radius, border: Border.all(color: cs.outlineVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _header(context, column),
          Padding(
            padding: const EdgeInsets.all(_inset),
            child: column.entries.isEmpty
                ? Text(empty, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant))
                : Column(children: _rows(context, column, format)),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, _TrendColumn column) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _inset, vertical: kDefaultPadding),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            column.headerIcon,
            size: _headerIconSize,
            color: StatusTones.colorsOf(context, column.tone).foreground,
          ),
          const SizedBox(width: kDefaultPadding / 2),
          Flexible(
            child: Semantics(
              header: true,
              label: column.title,
              child: ExcludeSemantics(
                child: Text(
                  column.title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: _titleTracking,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _rows(BuildContext context, _TrendColumn column, String Function(double delta) format) {
    final Color dividerColor = Theme.of(context).colorScheme.outlineVariant;
    final String zero = format(0);

    return <Widget>[
      for (int i = 0; i < column.entries.length; i++) ...<Widget>[
        if (i > 0) Divider(height: _inset, color: dividerColor),
        _row(context, column.tone, column.entries[i], format(column.entries[i].delta), zero),
      ],
    ];
  }

  /// Arrow of the pill for [delta]: up when positive, down when negative,
  /// none when it is zero, NaN, or its [text] reads like the formatted zero.
  IconData? _arrow(double delta, String text, String zero) {
    if (text == zero) return null;
    if (delta > 0) return Icons.arrow_upward_rounded;
    if (delta < 0) return Icons.arrow_downward_rounded;
    return null;
  }

  Widget _row(BuildContext context, StatusTone tone, TrendEntry entry, String text, String zero) {
    final ThemeData theme = Theme.of(context);

    return MergeSemantics(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => Row(
          children: <Widget>[
            Expanded(
              child: Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: kDefaultPadding),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.max(0, constraints.maxWidth - kDefaultPadding - _minLabelWidth),
              ),
              child: StatusPill(label: text, tone: tone, icon: _arrow(entry.delta, text, zero), dense: true),
            ),
          ],
        ),
      ),
    );
  }
}
