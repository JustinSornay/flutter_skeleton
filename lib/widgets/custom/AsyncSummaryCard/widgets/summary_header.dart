// summary_header.dart
//
// _SummaryHeader — header of a loaded AsyncSummaryCard on cs.surfaceContainer:
// decorative icon (cs.secondary), the title as a semantic header (takes the
// free width and wraps), then the optional dense StatusPill badge (capped at
// 160 dp, ellipsised beyond; hidden with its gap when the label is empty)
// and the optional host trailing widget.

part of "../index.dart";

/// Widest the header badge may get (160 dp); a longer label is ellipsised by
/// PillBadge, while its semantics label still carries the full text. A fixed
/// cap (not a LayoutBuilder fraction) keeps the card's intrinsic sizes
/// available to hosts.
const double _badgeMaxWidth = kDefaultPadding * 20;

final class _SummaryHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final AsyncSummaryBadge? badge;
  final Widget? trailing;

  const _SummaryHeader({
    required this.icon,
    required this.title,
    required this.badge,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncSummaryBadge? badge = this.badge;
    final Widget? trailing = this.trailing;
    return ColoredBox(
      color: cs.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding * 2),
        child: Row(
          children: <Widget>[
            Icon(icon, color: cs.secondary, size: 18),
            const SizedBox(width: kDefaultPadding),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            if (badge != null && badge.label.isNotEmpty) ...<Widget>[
              const SizedBox(width: kDefaultPadding),
              // A non-flex Row child gets an unbounded width, so the cap is
              // what lets PillBadge's ellipsis engage; the badge stays flush
              // right because the title alone is flexible.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _badgeMaxWidth),
                child: StatusPill(
                  label: badge.label,
                  tone: badge.tone ?? StatusTone.neutral,
                  dense: true,
                  semanticsLabel: badge.semanticsLabel,
                ),
              ),
            ],
            if (trailing != null) ...<Widget>[
              const SizedBox(width: kDefaultPadding),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}
