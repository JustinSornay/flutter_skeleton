// section_header.dart
//
// Private header of CollapsibleSectionCard: optional tinted icon tile,
// optional uppercase overline, title with a collapsed-only "· subtitle",
// optional summary slot and a rotating chevron. One button semantics node
// with an expanded state and a localised tap hint.

part of "../index.dart";

/// Leading tile side.
const double _tileSize = 32;

/// Leading tile corner radius.
const double _tileRadius = 10;

/// Leading tile background opacity over `cs.primary`.
const double _tileAlpha = 0.10;

/// Icon size inside the leading tile.
const double _tileIconSize = 16;

/// Overline letter spacing.
const double _overlineTracking = 0.8;

final class _SectionHeader extends StatelessWidget {
  final String title;

  final bool isOpen;

  final VoidCallback onToggle;

  final IconData? icon;

  final String? overline;

  final String? subtitle;

  final Widget? summary;

  const _SectionHeader({
    required this.title,
    required this.isOpen,
    required this.onToggle,
    required this.icon,
    required this.overline,
    required this.subtitle,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final IconData? leading = icon;
    final Widget? trailing = summary;
    final String hint = isOpen
        ? "custom.collapsible_section_card.collapse".tr()
        : "custom.collapsible_section_card.expand".tr();

    return Semantics(
      container: true,
      button: true,
      expanded: isOpen,
      onTapHint: hint,
      child: InkWell(
        onTap: onToggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding * 2,
              vertical: kDefaultPadding * 1.5,
            ),
            child: Row(
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  _tile(leading, cs),
                  const SizedBox(width: kDefaultPadding),
                ],
                Expanded(child: _texts(context, cs)),
                const SizedBox(width: kDefaultPadding),
                if (trailing != null) ...<Widget>[
                  trailing,
                  const SizedBox(width: kDefaultPadding),
                ],
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: resolveMotion(context, kMotionShort),
                  curve: Curves.easeInOut,
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Decorative 32 dp tile tinted with the primary colour.
  Widget _tile(IconData leading, ColorScheme cs) {
    return Container(
      width: _tileSize,
      height: _tileSize,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: _tileAlpha),
        borderRadius: BorderRadius.circular(_tileRadius),
      ),
      child: Icon(leading, size: _tileIconSize, color: cs.primary),
    );
  }

  /// Overline above the title row.
  Widget _texts(BuildContext context, ColorScheme cs) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? label = overline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label != null && label.isNotEmpty)
          Text(
            label.toUpperCase(),
            semanticsLabel: label,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: _overlineTracking,
              color: cs.onSurfaceVariant,
            ),
          ),
        _titleRow(textTheme, cs),
      ],
    );
  }

  /// Title, then "· subtitle" while collapsed; both ellipsize on one line.
  Widget _titleRow(TextTheme textTheme, ColorScheme cs) {
    final String? inline = subtitle;
    final bool showSubtitle = !isOpen && inline != null && inline.isNotEmpty;

    return Row(
      children: <Widget>[
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface),
          ),
        ),
        if (showSubtitle) ...<Widget>[
          const SizedBox(width: kDefaultPadding / 2),
          Flexible(
            child: Text(
              "· $inline",
              semanticsLabel: inline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500, color: cs.primary),
            ),
          ),
        ],
      ],
    );
  }
}
