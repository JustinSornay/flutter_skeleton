// swimlane_tile.dart
//
// _SwimlaneTile — one tile of SwimlaneCard: an animated rounded box (opaque
// accent-tinted fill and accent outline when selected) around an InkWell
// holding the scaled-down value, the caption and the optional StatusPill
// badge, exposed as a single semantics node.

part of "../index.dart";

/// Corner radius of the tile and of its ink splash.
const double _tileRadius = 8;

/// Width of the tile outline (transparent when not selected, so the content
/// never shifts on selection).
const double _outlineWidth = 1.5;

/// Opacity of the accent tint composited over `cs.surfaceContainer` for the
/// selected tile. Kept low so the tone `foreground` value text stays at
/// least 4.5:1 on the tinted fill (`ToneColors.foreground` only guarantees it
/// on the untinted surfaces).
const double _selectedFillAlpha = 0.08;

/// Size of the headline value.
const double _valueFontSize = 18;

final class _SwimlaneTile<T> extends StatelessWidget {
  const _SwimlaneTile({
    required this.item,
    required this.width,
    required this.selected,
    required this.onTap,
  });

  final SwimlaneItem<T> item;

  /// Fixed tile width; the height comes from the lane.
  final double width;

  final bool selected;

  /// Null when the lane is read-only.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final StatusTone? tone = item.tone;
    final Color accent = tone == null ? cs.primary : StatusTones.colorsOf(context, tone).foreground;
    final bool interactive = onTap != null;
    // Opaque: the tint is composited over the tile's own surface, so the
    // value contrast never depends on what lies under the tile.
    final Color fill = selected
        ? Color.alphaBlend(accent.withValues(alpha: _selectedFillAlpha), cs.surfaceContainer)
        : cs.surfaceContainer;

    // The content is excluded (not the InkWell) so the node keeps its tap
    // action and focus, and reads only the composed label.
    return Semantics(
      container: true,
      button: interactive,
      inMutuallyExclusiveGroup: interactive,
      selected: selected,
      label: _semanticsLabel(),
      child: AnimatedContainer(
        duration: resolveMotion(context, kMotionShort),
        curve: Curves.easeOutCubic,
        width: width,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(_tileRadius),
          border: Border.all(color: selected ? accent : Colors.transparent, width: _outlineWidth),
        ),
        // Transparent Material so the ink paints above the tile fill.
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(_tileRadius),
            child: Padding(
              padding: const EdgeInsets.all(kDefaultPadding),
              child: ExcludeSemantics(child: _content(context, tone)),
            ),
          ),
        ),
      ),
    );
  }

  /// Value, caption and badge spread from top to bottom.
  Widget _content(BuildContext context, StatusTone? tone) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String badge = item.badge ?? "";

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            item.value,
            maxLines: 1,
            style: TextStyle(
              fontSize: _valueFontSize,
              fontWeight: FontWeight.w800,
              color: tone == null ? cs.onSurface : StatusTones.colorsOf(context, tone).foreground,
            ),
          ),
        ),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(color: cs.onSurfaceVariant),
        ),
        if (badge.isNotEmpty) StatusPill(label: badge, tone: tone ?? StatusTone.neutral, dense: true),
      ],
    );
  }

  /// [SwimlaneItem.semanticsLabel], else the non-empty visible texts joined.
  String _semanticsLabel() {
    final String? custom = item.semanticsLabel;
    if (custom != null && custom.isNotEmpty) return custom;
    return <String>[item.label, item.value, item.badge ?? ""]
        .where((String part) => part.isNotEmpty)
        .join(", ");
  }
}
