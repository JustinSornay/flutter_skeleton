// option_chip.dart
//
// Private chip of ChoiceChipRow: one pill ChoiceChip for a ChoiceOption<T>,
// coloured from the ColorScheme, inside a 48 dp hit area, with select /
// enable transitions that honour reduced motion.

part of "../index.dart";

/// Chip label font size.
const double _chipFontSize = 12;

/// Leading avatar icon size (Material 3 chip avatar).
const double _chipIconSize = 18;

/// Opacity of a disabled label (Material 3 disabled content).
const double _disabledLabelAlpha = 0.38;

/// Minimum label width. With the fixed chip padding and label padding
/// (4 × [kDefaultPadding]) plus the 1 dp border on each side, every chip is
/// at least 50 dp wide, so even a one-glyph label keeps a 48 dp target.
const double _minLabelWidth = kMinTapTarget - kDefaultPadding * 4;

final class _OptionChip<T> extends StatelessWidget {
  final ChoiceOption<T> option;

  /// Whether this option is the row's selected value.
  final bool selected;

  final ValueChanged<T> onSelected;

  const _OptionChip({required this.option, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Color labelColor = _labelColor(cs);
    final IconData? icon = option.icon;
    final AnimationStyle motion = AnimationStyle(duration: resolveMotion(context, kMotionShort));

    // `padded` alone gives a 40 dp hit area under the compact density; the
    // min height restores 48 dp, and the chip redirects taps above and below
    // its compact visual to itself.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kMinTapTarget),
      child: ChoiceChip(
        avatar: icon == null ? null : Icon(icon, size: _chipIconSize, color: labelColor),
        label: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: _minLabelWidth),
          child: Text(option.label, semanticsLabel: option.semanticsLabel, textAlign: TextAlign.center),
        ),
        selected: selected,
        onSelected: option.enabled ? (bool _) => onSelected(option.value) : null,
        selectedColor: cs.primary,
        backgroundColor: cs.surfaceContainer,
        disabledColor: cs.surfaceContainer,
        side: BorderSide(color: selected ? cs.primary : cs.outlineVariant),
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          fontSize: _chipFontSize,
          fontWeight: FontWeight.w600,
          color: labelColor,
        ),
        padding: const EdgeInsets.all(kDefaultPadding),
        labelPadding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
        shape: const StadiumBorder(),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        chipAnimationStyle: ChipAnimationStyle(
          selectAnimation: motion,
          enableAnimation: motion,
          avatarDrawerAnimation: motion,
        ),
      ),
    );
  }

  /// Disabled → muted onSurface; selected → onPrimary; otherwise onSurface.
  Color _labelColor(ColorScheme cs) {
    if (!option.enabled) return cs.onSurface.withValues(alpha: _disabledLabelAlpha);
    return selected ? cs.onPrimary : cs.onSurface;
  }
}
