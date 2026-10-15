// reference_marker.dart
//
// _ReferenceMarker — the standalone reference on the axis: a 32 dp
// cs.inverseSurface square (radius 8) showing the formatted reference over
// a faint reference icon, placed by _SlotVisual in a kMinTapTarget-tall hit
// box (up to kMinTapTarget wide). A cs.primary ring shows while the
// reference is the active selection.

part of "../index.dart";

final class _ReferenceMarker extends StatelessWidget {
  /// X of the square's centre within the hit box.
  final double visualCenter;

  /// Formatted reference value.
  final String text;

  final IconData icon;

  /// The reference is the active selection.
  final bool active;

  final String semanticsLabel;

  /// Null makes the marker inert.
  final VoidCallback? onTap;

  const _ReferenceMarker({
    required this.visualCenter,
    required this.text,
    required this.icon,
    required this.active,
    required this.semanticsLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final BorderRadius radius = BorderRadius.circular(kDefaultPadding);

    return Semantics(
      container: true,
      excludeSemantics: true,
      button: onTap != null,
      selected: active,
      label: semanticsLabel,
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          child: _SlotVisual(
            centerX: visualCenter,
            size: ValueAxisLayout.referenceSize,
            child: Container(
              width: ValueAxisLayout.referenceSize,
              height: ValueAxisLayout.referenceSize,
              decoration: BoxDecoration(
                color: cs.inverseSurface,
                borderRadius: radius,
                border: Border.all(color: cs.inverseSurface, width: 2),
                boxShadow: <BoxShadow>[
                  BoxShadow(color: cs.shadow.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                  if (active) BoxShadow(color: cs.primary.withValues(alpha: 0.5), spreadRadius: 3),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Icon(icon, size: 22, color: cs.onInverseSurface.withValues(alpha: 0.3)),
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
                          color: cs.onInverseSurface,
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
}
