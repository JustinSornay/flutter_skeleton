// timeline_dot.dart
//
// _TimelineDot — one entry of HistoryTimeline: a kMinTapTarget-tall hit box
// (as wide as the view gives it, at most kMinTapTarget) holding the dot on
// the axis line at centerX and its date caption centred below. Current:
// 12 dp cs.primary dot with a halo and a bold cs.primary caption. Past: 8 dp
// outlined dot (cs.surface / cs.onSurfaceVariant) that turns cs.primary on
// hover when tappable. One semantics node ("label, caption" + hint, selected
// when current, button when tappable) and an inverse-surface Tooltip centred
// on the dot.

part of "../index.dart";

final class _TimelineDot extends StatelessWidget {
  /// Distance from the left edge of the hit box to the dot centre.
  final double centerX;

  /// Date caption under the dot.
  final String caption;

  /// Entry text; empty shows the hint alone in the tooltip.
  final String label;

  /// Tooltip and semantics hint.
  final String hint;

  /// Whether this is the current (newest) entry.
  final bool current;

  /// Whether the mouse is over this dot.
  final bool hovered;

  /// Tap handler; null makes the dot inert.
  final VoidCallback? onTap;

  /// Mouse entered (true) or left (false) the hit box.
  final void Function(bool inside) onHover;

  const _TimelineDot({
    required this.centerX,
    required this.caption,
    required this.label,
    required this.hint,
    required this.current,
    required this.hovered,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool tappable = onTap != null;
    final double size = current ? _kCurrentDotSize : _kPastDotSize;

    return Semantics(
      container: true,
      excludeSemantics: true,
      button: tappable,
      selected: current,
      label: label.isEmpty ? caption : "$label, $caption",
      hint: hint,
      onTap: onTap,
      child: Tooltip(
        message: label.isEmpty ? hint : "$label · $hint",
        excludeFromSemantics: true,
        preferBelow: false,
        verticalOffset: 20,
        positionDelegate: _centreOnDot,
        decoration: BoxDecoration(
          color: cs.inverseSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: cs.onInverseSurface,
        ),
        child: MouseRegion(
          cursor: tappable ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (PointerEnterEvent _) => onHover(true),
          onExit: (PointerExitEvent _) => onHover(false),
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            child: SizedBox.expand(
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: centerX - size / 2,
                    top: _kAxisY - size / 2,
                    child: SizedBox.square(
                      dimension: size,
                      child: DecoratedBox(decoration: _decoration(cs, active: current || (hovered && tappable))),
                    ),
                  ),
                  // Unconstrained width: a caption wider than the hit box
                  // stays on one line, centred under the dot.
                  Positioned(
                    left: centerX,
                    top: _kCaptionTop,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: Text(
                        caption,
                        maxLines: 1,
                        softWrap: false,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                          color: current ? cs.primary : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Default tooltip placement, moved from the hit box centre to the dot
  /// centre (the two differ when a close neighbour cuts the hit box).
  Offset _centreOnDot(TooltipPositionContext position) {
    return positionDependentBox(
      size: position.overlaySize,
      childSize: position.tooltipSize,
      target: position.target + Offset(centerX - position.targetSize.width / 2, 0),
      verticalOffset: position.verticalOffset,
      preferBelow: position.preferBelow,
    );
  }

  /// Circle fill, border and (current only) halo; [active] paints it primary.
  BoxDecoration _decoration(ColorScheme cs, {required bool active}) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: active ? cs.primary : cs.surface,
      border: Border.all(color: active ? cs.primary : cs.onSurfaceVariant, width: 2),
      boxShadow: current
          ? <BoxShadow>[BoxShadow(color: cs.primary.withValues(alpha: 0.15), spreadRadius: 4)]
          : null,
    );
  }
}
