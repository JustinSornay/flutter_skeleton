// group_header.dart
//
// Private header of ExpandableGroupTile: optional leading icon, title,
// optional subtitle and a chevron that rotates in accordion mode or points
// right in direct mode. One button semantics node; its expanded state and
// localised expand / collapse tap hint are exposed only in accordion mode.
// An inert header (no onTap) is dimmed like a disabled entry row.

part of "../index.dart";

/// Leading header icon size.
const double _headerIconSize = 28;

final class _GroupHeader extends StatelessWidget {
  final String title;

  /// Second line; hidden when null or empty.
  final String? subtitle;

  /// Spoken form of [subtitle]; null reads the visible text.
  final String? subtitleSemanticsLabel;

  final IconData? icon;

  /// Accordion mode (rotating chevron, expanded state) vs direct mode.
  final bool expandable;

  final bool isOpen;

  /// Null makes the header inert.
  final VoidCallback? onTap;

  const _GroupHeader({
    required this.title,
    required this.subtitle,
    required this.subtitleSemanticsLabel,
    required this.icon,
    required this.expandable,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final IconData? leading = icon;

    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      expanded: expandable ? isOpen : null,
      onTapHint: _tapHint(),
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding * 2,
              vertical: kDefaultPadding * 1.5,
            ),
            child: Opacity(
              opacity: onTap != null ? 1 : _disabledOpacity,
              child: Row(
                children: <Widget>[
                  if (leading != null) ...<Widget>[
                    Icon(leading, size: _headerIconSize, color: cs.primary),
                    const SizedBox(width: kDefaultPadding * 1.5),
                  ],
                  Expanded(child: _texts(context, cs)),
                  const SizedBox(width: kDefaultPadding),
                  _chevron(context, cs),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Expand / collapse hint in accordion mode; none for a direct row.
  String? _tapHint() {
    if (!expandable) return null;
    return isOpen ? "custom.expandable_group_tile.collapse".tr() : "custom.expandable_group_tile.expand".tr();
  }

  Widget _texts(BuildContext context, ColorScheme cs) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? second = subtitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        if (second != null && second.isNotEmpty)
          Text(
            second,
            semanticsLabel: subtitleSemanticsLabel,
            style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
      ],
    );
  }

  Widget _chevron(BuildContext context, ColorScheme cs) {
    if (!expandable) return Icon(Icons.chevron_right, color: cs.primary);
    return AnimatedRotation(
      turns: isOpen ? 0.5 : 0,
      duration: resolveMotion(context, kMotionShort),
      curve: Curves.easeInOut,
      child: Icon(Icons.keyboard_arrow_down, color: cs.primary),
    );
  }
}
