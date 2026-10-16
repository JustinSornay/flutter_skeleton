// north_badge.dart
//
// Private north-arrow badge of MapExportOverlay: a translucent
// inverse-surface circle with the short north glyph, exposed to screen
// readers as one node carrying the full word.

part of "../index.dart";

/// Diameter of the north badge.
const double _badgeSize = 32;

/// Font size of the north glyph.
const double _glyphFontSize = 13;

final class _NorthBadge extends StatelessWidget {
  const _NorthBadge();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Semantics(
      label: "custom.map_export_overlay.north".tr(),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: _badgeSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.inverseSurface.withValues(alpha: _chipAlpha),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              "custom.map_export_overlay.north_short".tr(),
              maxLines: 1,
              style: _overlayTextStyle(
                context,
                fontSize: _glyphFontSize,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
