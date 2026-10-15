// view.dart
//
// Tree of MapPin: one image semantics node around a fixed-size CustomPaint,
// squashed from the top edge by the caller's drop animation when motion is
// allowed. Colours are resolved here from the ColorScheme only and injected
// into _PinPainter (widgets/pin_painter.dart).

part of "index.dart";

/// Drop progress after which the squash starts (4/7).
const double _kSquishStart = 4 / 7;

/// Vertical squash at the peak (−18 %).
const double _kSquishY = 0.18;

/// Horizontal stretch at the peak (+15 %).
const double _kSquishX = 0.15;

/// Opacity of the default `cs.onPrimary` head outline.
const double _kOutlineAlpha = 0.25;

/// Opacity of the `cs.shadow` drop shadow.
const double _kShadowAlpha = 0.12;

mixin _ViewMixin {
  Widget render(BuildContext context, MapPin widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Widget pin = SizedBox.fromSize(
      size: widget.size,
      child: CustomPaint(
        painter: _PinPainter(
          fill: widget.color ?? cs.primary,
          outline: widget.outlineColor ?? cs.onPrimary.withValues(alpha: _kOutlineAlpha),
          shadow: widget.showShadow ? cs.shadow.withValues(alpha: _kShadowAlpha) : null,
        ),
      ),
    );

    return Semantics(
      container: true,
      image: true,
      label: widget.semanticLabel ?? "custom.map_pin.label".tr(),
      child: _withDrop(context, widget.dropAnimation, pin),
    );
  }

  /// Wraps [pin] in the squash transform, or returns it unchanged when there
  /// is no animation or motion is reduced.
  Widget _withDrop(BuildContext context, Animation<double>? animation, Widget pin) {
    if (animation == null || MediaQuery.disableAnimationsOf(context)) return pin;

    return AnimatedBuilder(
      animation: animation,
      child: pin,
      builder: (BuildContext context, Widget? child) {
        final double squash = _squash(animation.value);
        return Transform.scale(
          scaleX: 1 + _kSquishX * squash,
          scaleY: 1 - _kSquishY * squash,
          alignment: Alignment.topCenter,
          child: child,
        );
      },
    );
  }
}

/// Squash amount (0..1) for drop progress [t]: 0 up to [_kSquishStart], then
/// one sine half-wave over the rest of the animation.
double _squash(double t) {
  if (t <= _kSquishStart) return 0;
  final double local = math.min((t - _kSquishStart) / (1 - _kSquishStart), 1.0);
  return math.sin(local * math.pi);
}
