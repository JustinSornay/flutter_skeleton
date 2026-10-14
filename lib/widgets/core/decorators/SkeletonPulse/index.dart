// index.dart
//
// SkeletonPulse — animation decorator that pulses a skeleton child between
// opacity 0.3 and 0.7 to indicate loading activity.
//
// Two modes:
//   Autonomous  — no controller provided; owns an internal AnimationController
//                 that repeats with reverse (ping-pong) for a continuous pulse.
//   Controlled  — an external AnimationController is passed in (e.g. shared across
//                 a list of rows so they pulse in sync).
//
// Always respects MediaQuery.disableAnimations — returns the child as-is when true.
//
// Related: view_model.dart owns the internal controller lifecycle.
//          view.dart renders the conditional animation wrapper.

import "package:flutter/material.dart";

part "view_model.dart";
part "view.dart";

/// Wraps [child] in an opacity pulse animation to indicate loading state.
///
/// Pass [controller] to synchronise the pulse with an external animation
/// (e.g. a controller owned by the parent state). Omit [controller] for a
/// self-contained pulse that loops continuously.
final class SkeletonPulse extends StatefulWidget {
  final Widget child;
  final AnimationController? controller;

  const SkeletonPulse({
    super.key,
    required this.child,
    this.controller,
  });

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}
