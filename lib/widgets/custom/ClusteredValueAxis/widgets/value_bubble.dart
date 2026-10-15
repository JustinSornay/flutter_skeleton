// value_bubble.dart
//
// _ValueBubble — one point on the axis: a 30 dp circle showing the
// formatted value, placed by _SlotVisual in a kMinTapTarget-tall hit box
// (up to kMinTapTarget wide) with a circular ink response. Outlined
// cs.primary on cs.surface; filled cs.primary when selected (plus a ring);
// the best point has a cs.tertiary border, a glow and a star behind its
// value, and turns cs.tertiary when selected.

part of "../index.dart";

final class _ValueBubble extends StatelessWidget {
  /// X of the circle's centre within the hit box.
  final double visualCenter;

  /// Formatted value.
  final String text;

  /// Holds the highest value.
  final bool best;

  final bool selected;

  final String semanticsLabel;

  /// Null makes the bubble inert.
  final VoidCallback? onTap;

  const _ValueBubble({
    required this.visualCenter,
    required this.text,
    required this.best,
    required this.selected,
    required this.semanticsLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final (Color background, Color foreground) = switch ((selected, best)) {
      (true, true) => (cs.tertiary, cs.onTertiary),
      (false, false) => (cs.surface, cs.primary),
      _ => (cs.primary, cs.onPrimary),
    };

    return Semantics(
      container: true,
      excludeSemantics: true,
      button: onTap != null,
      selected: selected,
      label: semanticsLabel,
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: _SlotVisual(
            centerX: visualCenter,
            size: ValueAxisLayout.bubbleSize,
            child: Container(
              width: ValueAxisLayout.bubbleSize,
              height: ValueAxisLayout.bubbleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: background,
                border: Border.all(color: best ? cs.tertiary : cs.primary, width: 2.5),
                boxShadow: _shadows(cs),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  if (best) Icon(Icons.star_rounded, size: 20, color: foreground.withValues(alpha: 0.3)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        text,
                        maxLines: 1,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: foreground,
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

  /// Best: a cs.tertiary glow; otherwise a soft drop shadow. Selected adds
  /// a 3 dp cs.primary ring (instead of the drop shadow).
  List<BoxShadow> _shadows(ColorScheme cs) {
    final BoxShadow ring = BoxShadow(color: cs.primary.withValues(alpha: 0.25), spreadRadius: 3);
    if (best) {
      return <BoxShadow>[
        BoxShadow(color: cs.tertiary.withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 3)),
        if (selected) ring,
      ];
    }
    if (selected) return <BoxShadow>[ring];
    return <BoxShadow>[
      BoxShadow(color: cs.primary.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2)),
    ];
  }
}
