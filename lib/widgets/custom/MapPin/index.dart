// index.dart
//
// MapPin — theme-aware teardrop location pin (round head + tapered wick, tip
// at the bottom centre of its box) for marking a point on a map, an image or
// a diagram. An optional squash-and-stretch is driven by an animation the
// caller owns. Plain CustomPaint, no map-package dependency; the tree lives
// in view.dart and the painter in widgets/pin_painter.dart.

import "dart:math" as math;

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";

part "view.dart";
part "widgets/pin_painter.dart";

/// Teardrop pin: a circular head of diameter `size.width` at the top and a
/// tapered wick whose tip sits at `(size.width / 2, size.height)`.
///
/// To pin it to a coordinate, anchor the box with [Alignment.topCenter]
/// relative to the point (its tip then touches the point). With `flutter_map`:
///
/// ```dart
/// Marker(
///   point: point,
///   width: MapPin.defaultSize.width,
///   height: MapPin.defaultSize.height,
///   alignment: Alignment.topCenter,
///   child: const MapPin(),
/// )
/// ```
///
/// - Fill: [color], else `cs.primary`.
/// - Head outline (1.5 dp stroke): [outlineColor], else `cs.onPrimary` at
///   25 % opacity.
/// - [showShadow] draws a soft shadow that follows the pin shape
///   (`cs.shadow` at 12 % opacity, blur radius 8, offset (0, 2)).
/// - [dropAnimation] adds a squash-and-stretch from the top edge when the pin
///   lands. The widget only listens to it: the caller creates, runs and
///   disposes it. It is ignored when the platform asks to reduce motion
///   (`MediaQuery.disableAnimationsOf`), and the pin is then drawn static.
///
/// Accessibility: one image semantics node labelled [semanticLabel], else
/// `"custom.map_pin.label".tr()`. Wrap a purely decorative copy (for example
/// a drag preview that follows the pointer) in [ExcludeSemantics].
///
/// Uses no tooltip or overlay, so it needs no `Overlay` ancestor.
final class MapPin extends StatelessWidget with _ViewMixin {
  /// Default box size (28 × 40 dp).
  static const Size defaultSize = Size(28, 40);

  /// Pin fill. Defaults to `cs.primary`.
  final Color? color;

  /// Head outline colour. Defaults to `cs.onPrimary` at 25 % opacity.
  final Color? outlineColor;

  /// Overall box. The head diameter is `size.width`; the wick half-width is
  /// `width * 5 / 28` and the wick starts at `y = width * 24 / 28`, so the
  /// geometry scales with the width. `size.height` should exceed
  /// `size.width`.
  final Size size;

  /// Draws the soft drop shadow under the pin.
  final bool showShadow;

  /// Optional 0..1 drop progress owned by the caller (for example an
  /// [AnimationController] run with `forward(from: 0)` when a point is
  /// chosen). No deformation up to t = 4/7; after that
  /// `squash = sin(((t - 4/7) / (3/7)) * pi)`, `scaleY = 1 - 0.18 * squash`,
  /// `scaleX = 1 + 0.15 * squash`, anchored at the top centre. Values outside
  /// 0..1 are clamped. Ignored under reduced motion.
  final Animation<double>? dropAnimation;

  /// Screen-reader label, already localised by the host. Defaults to
  /// `"custom.map_pin.label".tr()`.
  final String? semanticLabel;

  const MapPin({
    super.key,
    this.color,
    this.outlineColor,
    this.size = MapPin.defaultSize,
    this.showShadow = true,
    this.dropAnimation,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}
