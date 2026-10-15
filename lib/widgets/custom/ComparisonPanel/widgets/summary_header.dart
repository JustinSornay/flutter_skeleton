// summary_header.dart
//
// _SummaryHeader — the always-visible top of a ComparisonPanel: the current
// side, the central swap badge, the candidate side and, when the panel has
// detail to show, the rotating chevron badge. One semantics node that reads
// "{current} compared with {candidate}" and, when tappable, exposes a button
// with an expanded state.

part of "../index.dart";

/// Diameter of the central swap badge.
const double _swapBadgeSize = 28;

/// Diameter of the chevron badge.
const double _chevronBadgeSize = 24;

final class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.current,
    required this.candidate,
    required this.isExpanded,
    required this.icon,
    required this.onToggle,
  });

  final ComparisonSide current;

  final ComparisonSide candidate;

  final bool isExpanded;

  /// Icon of the central badge.
  final IconData icon;

  /// Null when the panel has no detail: no chevron, inert header.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final VoidCallback? onToggle = this.onToggle;
    final bool toggleable = onToggle != null;

    return Semantics(
      container: true,
      excludeSemantics: true,
      button: toggleable,
      expanded: toggleable ? isExpanded : null,
      label: _summaryLabel(),
      hint: toggleable ? _hint() : null,
      onTap: onToggle,
      child: Material(
        color: cs.surfaceContainerLow,
        child: InkWell(
          onTap: onToggle,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTapTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding * 1.5,
                vertical: kDefaultPadding * 1.25,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(child: _SideSummary(side: current, color: cs.primary, alignEnd: false)),
                  const SizedBox(width: kDefaultPadding * 1.25),
                  _SwapBadge(icon: icon),
                  const SizedBox(width: kDefaultPadding * 1.25),
                  Expanded(child: _SideSummary(side: candidate, color: cs.tertiary, alignEnd: true)),
                  if (toggleable) ...<Widget>[
                    const SizedBox(width: kDefaultPadding),
                    _ChevronBadge(isExpanded: isExpanded),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _summaryLabel() {
    return "custom.comparison_panel.summary_semantics".tr(
      namedArgs: <String, String>{"current": _describe(current), "candidate": _describe(candidate)},
    );
  }

  /// "title (subtitle)", or the title alone.
  String _describe(ComparisonSide side) {
    final String? subtitle = side.subtitle;
    return subtitle == null ? side.title : "${side.title} ($subtitle)";
  }

  String _hint() {
    return isExpanded
        ? "custom.comparison_panel.hide_details".tr()
        : "custom.comparison_panel.show_details".tr();
  }
}

/// Tag, title and optional subtitle of one side, start- or end-aligned.
final class _SideSummary extends StatelessWidget {
  const _SideSummary({required this.side, required this.color, required this.alignEnd});

  final ComparisonSide side;

  /// Identity colour of the side (tag).
  final Color color;

  /// True for the candidate side (right column).
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? subtitle = side.subtitle;
    final TextAlign align = alignEnd ? TextAlign.end : TextAlign.start;

    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          side.tag.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: color),
        ),
        Text(
          side.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cs.onSurface),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
          ),
      ],
    );
  }
}

/// Decorative `cs.tertiary` disc with the panel icon, between the sides.
final class _SwapBadge extends StatelessWidget {
  const _SwapBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: _swapBadgeSize,
      height: _swapBadgeSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: cs.tertiary, shape: BoxShape.circle),
      child: Icon(icon, size: 16, color: cs.onTertiary),
    );
  }
}

/// Chevron in a circle: outlined when collapsed, filled and turned half a
/// turn when expanded.
final class _ChevronBadge extends StatelessWidget {
  const _ChevronBadge({required this.isExpanded});

  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return AnimatedRotation(
      turns: isExpanded ? 0.5 : 0,
      duration: resolveMotion(context, kMotionShort),
      curve: Curves.easeOutCubic,
      child: Container(
        width: _chevronBadgeSize,
        height: _chevronBadgeSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isExpanded ? cs.tertiary : cs.surface,
          border: Border.all(color: cs.tertiary),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 14,
          color: isExpanded ? cs.onTertiary : cs.tertiary,
        ),
      ),
    );
  }
}
