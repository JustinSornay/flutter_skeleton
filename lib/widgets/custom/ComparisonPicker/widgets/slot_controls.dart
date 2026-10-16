// slot_controls.dart
//
// Slot visuals of ComparisonPicker: the slot colours and letters, the 16 dp
// slot dot (a filled dot shows its letter), the 48 dp A / B radio, and the
// two read-only dots of locked-A mode (the locked slot A, and a slot a row
// holds but cannot toggle).

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

/// Letter of [slot] ("A" / "B"), shared by the header badges and the dots.
String _slotLetter(_Slot slot) {
  return switch (slot) {
    _Slot.a => "custom.comparison_picker.slot_a".tr(),
    _Slot.b => "custom.comparison_picker.slot_b".tr(),
  };
}

/// 16 dp circle: filled with the slot accent and showing the slot letter
/// when [filled] (so the slot is never told by colour alone), an
/// `cs.outline` ring otherwise. Decorative: the letter is excluded from
/// semantics, the enclosing control or label speaks for it.
final class _SlotDot extends StatelessWidget {
  final _Slot slot;

  final bool filled;

  const _SlotDot({required this.slot, required this.filled});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Color accent = _slotColor(cs, slot);
    return SizedBox.square(
      dimension: _dotSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: filled ? accent : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: filled ? accent : cs.outline, width: _dotStroke),
        ),
        child: filled
            ? ExcludeSemantics(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _slotLetter(slot),
                      maxLines: 1,
                      softWrap: false,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: _onSlotColor(cs, slot),
                      ),
                    ),
                  ),
                ),
              )
            : null,
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

/// Filled slot-A dot of the primary row in locked-A mode while it holds
/// slot A, read as `custom.comparison_picker.locked_a`. The view shows it
/// only then, so it never announces a slot the row does not hold.
final class _LockedSlotDot extends StatelessWidget {
  final String itemLabel;

  const _LockedSlotDot({required this.itemLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: "custom.comparison_picker.locked_a".tr(namedArgs: <String, String>{"label": itemLabel}),
      child: const _SlotDot(slot: _Slot.a, filled: true),
    );
  }
}

/// Filled dot of a locked-A row holding a slot it cannot toggle itself (a
/// secondary row holding slot A, or the primary row holding slot B). It is
/// one checked, disabled node of the slot group labelled [semanticsLabel]
/// ("Select {label} as A"), and its letter names the slot on screen.
final class _HeldSlotDot extends StatelessWidget {
  final _Slot slot;

  final String semanticsLabel;

  const _HeldSlotDot({required this.slot, required this.semanticsLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: true,
      enabled: false,
      label: semanticsLabel,
      child: _SlotDot(slot: slot, filled: true),
    );
  }
}
