// slot_controls.dart
//
// Slot visuals of ComparisonPicker: the slot colours, the 16 dp slot dot,
// the 48 dp A / B radio and the locked slot-A dot of locked-A mode.

part of "../index.dart";

/// Diameter of the visible slot dot.
const double _dotSize = 16;

/// Ring width of the slot dot.
const double _dotStroke = 1.5;

/// Opacity of a disabled radio.
const double _disabledOpacity = 0.28;

/// Accent of [slot]: `cs.primary` for A, `cs.tertiary` for B.
Color _slotColor(ColorScheme cs, _Slot slot) {
  return switch (slot) {
    _Slot.a => cs.primary,
    _Slot.b => cs.tertiary,
  };
}

/// Content colour on [_slotColor].
Color _onSlotColor(ColorScheme cs, _Slot slot) {
  return switch (slot) {
    _Slot.a => cs.onPrimary,
    _Slot.b => cs.onTertiary,
  };
}

/// 16 dp circle: filled with the slot accent when [filled], an `cs.outline`
/// ring otherwise. Decorative.
final class _SlotDot extends StatelessWidget {
  final _Slot slot;

  final bool filled;

  const _SlotDot({required this.slot, required this.filled});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color accent = _slotColor(cs, slot);
    return SizedBox.square(
      dimension: _dotSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: filled ? accent : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: filled ? accent : cs.outline, width: _dotStroke),
        ),
      ),
    );
  }
}

/// A / B radio with a [kMinTapTarget] square hit area. A null [onTap]
/// disables it: dimmed dot, forbidden cursor, disabled semantics.
final class _SlotRadio extends StatelessWidget {
  final _Slot slot;

  final bool selected;

  final String semanticsLabel;

  final VoidCallback? onTap;

  const _SlotRadio({required this.slot, required this.selected, required this.semanticsLabel, this.onTap});

  @override
  Widget build(BuildContext context) {
    final VoidCallback? onTap = this.onTap;
    final Widget dot = _SlotDot(slot: slot, filled: selected);

    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: onTap != null,
      label: semanticsLabel,
      child: SizedBox.square(
        dimension: kMinTapTarget,
        child: onTap == null
            ? MouseRegion(
                cursor: SystemMouseCursors.forbidden,
                child: Center(
                  child: Opacity(opacity: _disabledOpacity, child: dot),
                ),
              )
            : InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Center(child: dot),
              ),
      ),
    );
  }
}

/// Slot-A dot of the primary row in locked-A mode. While the row holds slot
/// A ([locked]) it is filled and read as `custom.comparison_picker.locked_a`;
/// otherwise (slot A moved elsewhere or emptied) it is a decorative empty
/// ring, so it never announces a slot the row does not hold.
final class _LockedSlotDot extends StatelessWidget {
  final String itemLabel;

  /// Whether the row currently holds slot A.
  final bool locked;

  const _LockedSlotDot({required this.itemLabel, required this.locked});

  @override
  Widget build(BuildContext context) {
    if (!locked) return const _SlotDot(slot: _Slot.a, filled: false);
    return Semantics(
      container: true,
      label: "custom.comparison_picker.locked_a".tr(namedArgs: <String, String>{"label": itemLabel}),
      child: const _SlotDot(slot: _Slot.a, filled: true),
    );
  }
}
