// ranked_list_row.dart
//
// _RankedListRow — one row of RankedList: rank circle, label + optional
// detail, optional active badge (PillBadge), optional score (dense
// StatusPill in the entry's tone) and optional decorative trailing icon
// circle. A single button semantics node, selected when active. At least
// kMinTapTarget tall; the rank circle grows with the text scale.

part of "../index.dart";

/// Corner radius of a row.
const double _rowRadius = 10;

/// Diameter of the rank circle at the default text scale (22 dp); also its
/// minimum.
const double _rankSize = kDefaultPadding * 2.75;

/// Size of the rank when the theme's labelSmall has none (11 sp).
const double _rankFontSize = 11;

/// Diameter of the trailing icon circle (26 dp).
const double _trailingSize = kDefaultPadding * 3.25;

/// Size of the trailing icon.
const double _trailingIconSize = 16;

/// Widest the active badge may grow before it ellipsises (96 dp).
const double _badgeMaxWidth = kDefaultPadding * 12;

/// Inner padding of a row (12 / 10 dp).
const EdgeInsets _rowPadding = EdgeInsets.symmetric(
  horizontal: kDefaultPadding * 1.5,
  vertical: kDefaultPadding * 1.25,
);

final class _RankedListRow<T> extends StatelessWidget {
  final RankedListEntry<T> entry;

  /// Rank drawn in the circle.
  final int rank;

  /// Whether this row is the highlighted one.
  final bool active;

  /// Badge text of the active row; null or empty → no badge.
  final String? activeBadgeLabel;

  /// Decorative trailing icon; null hides it.
  final IconData? trailingIcon;

  final VoidCallback onTap;

  const _RankedListRow({
    required this.entry,
    required this.rank,
    required this.active,
    required this.activeBadgeLabel,
    required this.trailingIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(_rowRadius);
    final String? scoreText = _scoreText(context);

    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      selected: active,
      label: _semanticsLabel(scoreText),
      onTap: onTap,
      child: Material(
        color: active ? cs.tertiaryContainer : cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: active ? cs.tertiary : cs.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTapTarget),
            child: Padding(
              padding: _rowPadding,
              child: Row(
                children: <Widget>[
                  _rankCircle(context),
                  const SizedBox(width: kDefaultPadding * 1.25),
                  Expanded(child: _texts(context)),
                  ..._badge(context),
                  ..._score(scoreText),
                  ..._trailing(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The circle grows by the same factor as the rank's font under the text
  /// scaler (never below 22 dp), so the rank scales with the rest of the row;
  /// the FittedBox only shrinks ranks too wide for the circle (3+ digits).
  Widget _rankCircle(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final TextStyle style = (theme.textTheme.labelSmall ?? const TextStyle(fontSize: _rankFontSize)).copyWith(
      fontWeight: FontWeight.w800,
      color: active ? cs.onTertiary : cs.onTertiaryContainer,
    );
    final double fontSize = style.fontSize ?? _rankFontSize;
    final double fontScale = MediaQuery.textScalerOf(context).scale(fontSize) / fontSize;
    return SizedBox.square(
      dimension: math.max(_rankSize, _rankSize * fontScale),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? cs.tertiary : cs.tertiaryContainer,
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding / 4),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text("$rank", maxLines: 1, style: style),
            ),
          ),
        ),
      ),
    );
  }

  Widget _texts(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? detail = entry.detail;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          entry.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: active ? cs.onTertiaryContainer : cs.onSurface,
          ),
        ),
        if (detail != null && detail.isNotEmpty)
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: active ? cs.onTertiaryContainer : cs.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  List<Widget> _badge(BuildContext context) {
    final String? label = activeBadgeLabel;
    if (!active || label == null || label.isEmpty) return const <Widget>[];
    final ColorScheme cs = Theme.of(context).colorScheme;
    return <Widget>[
      const SizedBox(width: kDefaultPadding),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _badgeMaxWidth),
        child: PillBadge(label: label, color: cs.tertiary, backgroundColor: cs.surface, dense: true),
      ),
    ];
  }

  List<Widget> _score(String? scoreText) {
    if (scoreText == null) return const <Widget>[];
    return <Widget>[
      const SizedBox(width: kDefaultPadding),
      StatusPill(label: scoreText, tone: entry.tone, dense: true),
    ];
  }

  List<Widget> _trailing(BuildContext context) {
    final IconData? icon = trailingIcon;
    if (icon == null) return const <Widget>[];
    final ColorScheme cs = Theme.of(context).colorScheme;
    return <Widget>[
      const SizedBox(width: kDefaultPadding),
      SizedBox.square(
        dimension: _trailingSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: active ? cs.tertiary : cs.surface,
            border: Border.all(color: active ? cs.tertiary : cs.outlineVariant),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: _trailingIconSize, color: active ? cs.onTertiary : cs.onSurfaceVariant),
        ),
      ),
    ];
  }

  /// Locale-formatted percentage of the score, or null when there is none.
  String? _scoreText(BuildContext context) {
    final double? score = entry.score;
    if (score == null || !score.isFinite) return null;
    final String? locale = numberLocaleOf(context);
    return NumberFormat.percentPattern(locale).format(score);
  }

  /// [RankedListEntry.semanticsLabel], else rank + label, detail, score and
  /// the active badge joined with ", ".
  String _semanticsLabel(String? scoreText) {
    final String? custom = entry.semanticsLabel;
    if (custom != null) return custom;
    final String head = "custom.ranked_list.item_semantics".tr(
      namedArgs: <String, String>{"rank": "$rank", "label": entry.label},
    );
    return <String?>[head, entry.detail, scoreText, if (active) activeBadgeLabel]
        .whereType<String>()
        .where((String part) => part.isNotEmpty)
        .join(", ");
  }
}
