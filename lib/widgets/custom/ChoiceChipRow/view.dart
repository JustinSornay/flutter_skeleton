// view.dart
//
// Tree of ChoiceChipRow: the optional caption, then a Wrap of _OptionChip
// (widgets/option_chip.dart). Colours come from the ColorScheme only.

part of "index.dart";

/// Caption font size (small uppercase-style label above the chips).
const double _captionFontSize = 9;

/// Caption letter spacing.
const double _captionLetterSpacing = 1;

mixin _ViewMixin<T> {
  Widget render(BuildContext context, ChoiceChipRow<T> widget) {
    final String? label = widget.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label != null) ...<Widget>[
          _caption(context, label),
          const SizedBox(height: kDefaultPadding),
        ],
        // Run spacing keeps a visible gap between rows of pills even when a
        // large text scale makes the pill fill its 48 dp hit area.
        Wrap(
          spacing: kDefaultPadding,
          runSpacing: kDefaultPadding,
          children: <Widget>[
            for (final ChoiceOption<T> option in widget.options)
              _OptionChip<T>(
                option: option,
                selected: option.value == widget.selectedValue,
                onSelected: widget.onSelected,
              ),
          ],
        ),
      ],
    );
  }

  /// Small muted caption, shown exactly as passed.
  Widget _caption(BuildContext context, String label) {
    final ThemeData theme = Theme.of(context);

    return Text(
      label,
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: _captionFontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: _captionLetterSpacing,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
