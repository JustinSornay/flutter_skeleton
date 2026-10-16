// choice_card.dart
//
// _ChoiceCard — one card of ThumbnailChoicePicker: the bordered thumbnail
// frame (selection border, ring and check badge) above its caption, inside
// an InkWell, exposed as one button semantics node of a mutually exclusive
// group. Disabled cards are dimmed and ignore taps.

part of "../index.dart";

/// Corner radius of the frame and of the ink splash.
const double _frameRadius = 8;

/// Width of the frame border.
const double _frameBorderWidth = 2;

/// Spread and opacity of the selection ring drawn around the frame.
const double _ringSpread = 3;
const double _ringAlpha = 0.15;

/// Check badge diameter, icon size and inset from the top-right corner.
const double _badgeSize = 16;
const double _badgeIconSize = 10;
const double _badgeInset = kDefaultPadding / 2;

/// Gap between the frame and the caption.
const double _captionGap = kDefaultPadding * 0.75;

/// Maximum caption lines (ellipsized beyond).
const int _captionMaxLines = 2;

/// Opacity of a disabled card (Material 3 disabled content).
const double _disabledOpacity = 0.38;

final class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.semanticsLabel,
    required this.selected,
    required this.size,
    required this.thumbnail,
    required this.onTap,
  });

  /// Visible caption.
  final String label;

  /// Spoken label of the card.
  final String semanticsLabel;

  final bool selected;

  /// Frame size, border included; also the card width.
  final Size size;

  /// Frame content, filling the area inside the border.
  final Widget thumbnail;

  /// Null when the card is disabled.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    final ColorScheme cs = Theme.of(context).colorScheme;

    // The content is excluded (not the InkWell) so the node keeps its tap
    // action and reads only semanticsLabel.
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: semanticsLabel,
      child: Opacity(
        opacity: enabled ? 1 : _disabledOpacity,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_frameRadius),
          child: SizedBox(
            width: size.width,
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _frame(cs),
                  const SizedBox(height: _captionGap),
                  _caption(context, cs),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Bordered, clipped thumbnail with the ring and badge when selected.
  Widget _frame(ColorScheme cs) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        border: Border.all(
          color: selected ? cs.primary : cs.outlineVariant,
          width: _frameBorderWidth,
        ),
        borderRadius: BorderRadius.circular(_frameRadius),
        boxShadow: selected
            ? <BoxShadow>[
                BoxShadow(
                  color: cs.primary.withValues(alpha: _ringAlpha),
                  spreadRadius: _ringSpread,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_frameRadius - _frameBorderWidth),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            thumbnail,
            if (selected)
              Positioned(
                top: _badgeInset,
                right: _badgeInset,
                child: _badge(cs),
              ),
          ],
        ),
      ),
    );
  }

  /// Check in a primary circle, the non-colour cue of the selection.
  Widget _badge(ColorScheme cs) {
    return Container(
      width: _badgeSize,
      height: _badgeSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
      child: Icon(Icons.check_rounded, size: _badgeIconSize, color: cs.onPrimary),
    );
  }

  Widget _caption(BuildContext context, ColorScheme cs) {
    return Text(
      label,
      textAlign: TextAlign.center,
      maxLines: _captionMaxLines,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? cs.primary : cs.onSurfaceVariant,
          ),
    );
  }
}
