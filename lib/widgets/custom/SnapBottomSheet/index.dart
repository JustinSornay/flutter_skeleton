// index.dart
//
// SnapBottomSheet — persistent bottom sheet resting at three heights
// (collapsed / mid / full) above a full-screen background. A 48 dp handle
// cycles the heights on tap or from the keyboard, the handle and the pinned
// header drag the sheet, and the body is a scrollable built from the
// sheet's own ScrollController. The collapsed height rises to fit the
// handle and the header. A caller-owned SnapBottomSheetController
// (snap_controller.dart) drives it and is written back after user drags.
// State lives in view_model.dart, the tree in view.dart, the snap maths in
// controllers/ and the handle and the grip / body layout in widgets/.

import "dart:async";
import "dart:math" as math;

import "package:easy_localization/easy_localization.dart";
import "package:flutter/gestures.dart" show kMinFlingVelocity;
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "controllers/snap_stops.dart";
part "snap_controller.dart";
part "view_model.dart";
part "view.dart";
part "widgets/sheet_handle.dart";
part "widgets/sheet_layout.dart";

/// Duration of every snap animation, before [resolveMotion].
const Duration _kSnapDuration = Duration(milliseconds: 320);

/// Snap duration of a released drag under reduced motion.
/// [DraggableScrollableSheet] asserts it is above zero; 1 ms ends within a
/// single frame.
const Duration _kInstantSnap = Duration(milliseconds: 1);

/// Top corners of the sheet, also the shape of the handle's ink.
const BorderRadius _kSheetRadius = BorderRadius.vertical(top: Radius.circular(2 * kDefaultPadding));

/// A persistent bottom sheet that rests at three heights (collapsed, mid and
/// full) above a full-screen background such as a map, a canvas or media.
///
/// Put it in a [Stack] above the background. It fills its parent and draws
/// the sheet from the bottom edge. Taps above the sheet reach the background.
///
/// - [controller]: owned by the caller, who creates and disposes it. It sets
///   the initial height and moves the sheet from code
///   ([SnapBottomSheetController.setSnap], [SnapBottomSheetController.stepDown]).
///   User drags write the resting height back into it, so
///   [SnapBottomSheetController.snap] always matches the sheet once it
///   settles. The parent can swap it for another controller.
/// - [builder]: builds the body. It **must** attach the given
///   [ScrollController] to its primary scrollable (`ListView`,
///   `CustomScrollView`…). Dragging that list then drags the sheet. Until
///   that scrollable is attached (a loader shown first, for instance) the
///   sheet cannot move: a height requested meanwhile, from code or from the
///   handle, is applied as soon as it attaches, and so is a move cut short
///   when the body replaces its scrollable.
/// - [header]: pinned between the handle and the body (a title, a counter…).
///   The collapsed height rises to fit it (see below).
/// - [collapsedFraction], [midFraction], [fullFraction]: the three heights
///   as fractions of the parent height
///   (`0 < collapsed < mid < full <= 1`).
///
/// The collapsed height is the larger of [collapsedFraction] and the height
/// of the handle plus the [header], so the header stays in full view at
/// every resting height. That rise stops half-way to the mid height: a
/// taller grip is cut at the sheet's edge instead of overflowing, and the
/// body then gets no height. The grip is measured as it lays out, so the
/// collapsed height follows a header size change one frame later.
///
/// The top handle is a full-width, [kMinTapTarget]-tall [InkWell] holding a
/// 40 × 4 pill. It is announced with the label
/// `custom.snap_bottom_sheet.handle` and the tap hint
/// `custom.snap_bottom_sheet.expand` (or `custom.snap_bottom_sheet.collapse`
/// at full height). Tapping it, or pressing Enter or Space while it has
/// keyboard focus, cycles collapsed → mid → full → collapsed.
/// Dragging the handle or the header moves the sheet. On release it settles
/// on the nearest height, or on the next height in the direction of a fling.
/// Every snap animates over `resolveMotion(context, 320 ms)` with
/// [Curves.easeOutCubic]. Under reduced motion, moves from code jump and
/// released drags snap within one frame.
///
/// Changing a fraction (or the parent height) keeps the controller's height:
/// the sheet moves to that height under the new fractions, without
/// notifying the controller.
///
/// Colours: `cs.surfaceContainerLow` with a soft `cs.shadow` and 16 dp top
/// corners. The pill is `cs.onSurfaceVariant` at 40 %. A transparent
/// [Material] hosts the content, so ink splashes in the body show on the
/// sheet.
///
/// Back button: from the host's `PopScope`, call
/// [SnapBottomSheetController.stepDown] and let the route pop only when it
/// returns false.
///
/// The sheet needs no `Overlay` ancestor (no tooltip or popup of its own).
/// The [header] and the body may need one.
final class SnapBottomSheet extends StatefulWidget {
  /// Caller-owned controller: initial height, moves from code, drag sync.
  final SnapBottomSheetController controller;

  /// Builds the body. It must attach `scrollController` to its primary
  /// scrollable.
  final Widget Function(BuildContext context, ScrollController scrollController) builder;

  /// Pinned between the handle and the body. The collapsed height rises to
  /// fit it.
  final Widget? header;

  /// Collapsed height as a fraction of the parent height, raised to fit the
  /// handle and the [header].
  final double collapsedFraction;

  /// Mid height as a fraction of the parent height.
  final double midFraction;

  /// Full height as a fraction of the parent height.
  final double fullFraction;

  const SnapBottomSheet({
    super.key,
    required this.controller,
    required this.builder,
    this.header,
    this.collapsedFraction = 0.09,
    this.midFraction = 0.45,
    this.fullFraction = 0.95,
  }) : assert(
         collapsedFraction > 0 &&
             collapsedFraction < midFraction &&
             midFraction < fullFraction &&
             fullFraction <= 1,
         "Expected 0 < collapsedFraction < midFraction < fullFraction <= 1.",
       );

  @override
  State<SnapBottomSheet> createState() => _SnapBottomSheetState();
}
