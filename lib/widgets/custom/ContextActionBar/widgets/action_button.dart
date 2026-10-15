// action_button.dart
//
// Private button of ContextActionBar: an elevated round IconButton (40 dp
// circle in a 48 dp padded tap target) whose fade and slide follow the
// animation handed over by the state. Colours come from the ColorScheme.

part of "../index.dart";

/// Diameter of the visible circle. The padded tap target around it is
/// [kMinTapTarget], which leaves 8 dp between neighbouring circles.
const double _buttonDiameter = kDefaultPadding * 5;

/// Icon size inside the circle.
const double _iconSize = kDefaultPadding * 2.5;

/// Elevation of the circle (shadow in `cs.shadow`).
const double _buttonElevation = 3;

/// Start offset of the enter slide, as a fraction of the button size.
const Offset _slideFrom = Offset(0, 0.25);

/// Opacity of a disabled icon (Material 3 disabled content).
const double _disabledAlpha = 0.38;

final class _ActionButton extends StatelessWidget {
  final ContextActionBarItem item;

  /// 0 = hidden, 1 = in place. Drives both the fade and the slide.
  final Animation<double> animation;

  const _ActionButton({required this.item, required this.animation});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animation.drive(Tween<Offset>(begin: _slideFrom, end: Offset.zero)),
        child: IconButton(
          tooltip: item.label,
          onPressed: item.onPressed,
          icon: Icon(item.icon),
          style: IconButton.styleFrom(
            backgroundColor: cs.surfaceContainerHigh,
            disabledBackgroundColor: cs.surfaceContainerHigh,
            foregroundColor: item.destructive ? cs.error : cs.onSurface,
            disabledForegroundColor: cs.onSurface.withValues(alpha: _disabledAlpha),
            elevation: _buttonElevation,
            shadowColor: cs.shadow,
            shape: const CircleBorder(),
            fixedSize: const Size.square(_buttonDiameter),
            iconSize: _iconSize,
            // Overrides a compact density set by a host `iconButtonTheme`,
            // which would shrink the target below 48 dp. The Material 3
            // default is already standard (ThemeData.visualDensity is not
            // read by IconButton).
            visualDensity: VisualDensity.standard,
            // Keeps the 48 dp target on desktop platforms, whose
            // ThemeData.materialTapTargetSize defaults to shrinkWrap.
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
        ),
      ),
    );
  }
}
