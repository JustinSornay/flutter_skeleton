// score_list_row.dart
//
// _ScoreListRow — one scored row of ScoreListCard: title + optional italic
// subtitle, a 6 dp bar (track cs.surfaceContainerHighest, radius 999, fill =
// tone foreground) with the score text in the same tone, and an optional
// wrapping caption. The score slot width is shared by every row of the card
// (scoreSlotWidth: the widest label, 32–96 dp), so all bar tracks have the
// same length and stay comparable. A single semantics node; ink and button
// semantics only when the row has a tap handler. At least kMinTapTarget tall.

part of "../index.dart";

/// Bar thickness (6 dp, the compact row variant).
const double _barHeight = kDefaultPadding * 0.75;

/// Vertical padding of a row, and gap between the title and the subtitle.
const double _rowInset = kDefaultPadding * 0.75;

/// Width bounds of the shared score text slot (32–96 dp). The cap keeps a
/// long label or a large text scale from overflowing the row: it ellipsises.
const double _scoreMinWidth = kDefaultPadding * 4;
const double _scoreMaxWidth = kDefaultPadding * 12;

final class _ScoreListRow extends StatelessWidget {
  final ScoreListEntry entry;

  /// Width of the score text slot, the same for every row of the card (see
  /// [scoreSlotWidth]), so every bar track has the same length.
  final double scoreWidth;

  /// Tap handler; null makes the row inert.
  final VoidCallback? onTap;

  const _ScoreListRow({required this.entry, required this.scoreWidth, required this.onTap});

  /// Width of the widest score text of [entries] as rendered in [context]
  /// (text scale included), clamped to 32–96 dp. Shared by all the rows.
  static double scoreSlotWidth(BuildContext context, List<ScoreListEntry> entries) {
    final TextStyle style = DefaultTextStyle.of(context).style.merge(_scoreStyle(Theme.of(context)));
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    double widest = 0;
    for (final ScoreListEntry entry in entries) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: entry._scoreText, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (painter.width > widest) widest = painter.width;
      painter.dispose();
    }
    return widest.ceilToDouble().clamp(_scoreMinWidth, _scoreMaxWidth);
  }

  /// Score text style without its colour (measured by [scoreSlotWidth]).
  static TextStyle? _scoreStyle(ThemeData theme) {
    return theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700);
  }

  @override
  Widget build(BuildContext context) {
    final VoidCallback? tap = onTap;
    final Widget content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kMinTapTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: _rowInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _titleRow(context),
            const SizedBox(height: kDefaultPadding / 2),
            _barRow(context),
            ..._caption(context),
          ],
        ),
      ),
    );

    return Semantics(
      container: true,
      excludeSemantics: true,
      button: tap != null,
      label: _semanticLabel(),
      onTap: tap,
      child: tap == null
          ? content
          : InkWell(borderRadius: BorderRadius.circular(8), onTap: tap, child: content),
    );
  }

  Widget _titleRow(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? subtitle = entry.subtitle;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            entry.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface),
          ),
        ),
        if (subtitle != null && subtitle.isNotEmpty)
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: _rowInset),
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _barRow(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color fill = StatusTones.colorsOf(context, entry.tone).foreground;
    return Row(
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: entry._ratio,
              minHeight: _barHeight,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(fill),
            ),
          ),
        ),
        const SizedBox(width: kDefaultPadding),
        SizedBox(
          width: scoreWidth,
          child: Text(
            entry._scoreText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: _scoreStyle(theme)?.copyWith(color: fill),
          ),
        ),
      ],
    );
  }

  List<Widget> _caption(BuildContext context) {
    final String? caption = entry.caption;
    if (caption == null || caption.isEmpty) return const <Widget>[];
    final ThemeData theme = Theme.of(context);
    return <Widget>[
      const SizedBox(height: kDefaultPadding / 4),
      Text(
        caption,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    ];
  }

  /// [ScoreListEntry.semanticLabel], else the non-empty parts of the row
  /// joined with ", ".
  String _semanticLabel() {
    final String? custom = entry.semanticLabel;
    if (custom != null) return custom;
    final String score = "custom.score_list_card.score_semantics".tr(
      namedArgs: <String, String>{"value": entry._scoreText},
    );
    return <String?>[entry.title, entry.subtitle, score, entry.caption]
        .whereType<String>()
        .where((String part) => part.isNotEmpty)
        .join(", ");
  }
}
