// option_row.dart
//
// _OptionRow — one radio row of SingleSelectSheet: radio icon, label and the
// optional trailing hint (one line, capped at half of the row width), on a
// bordered rounded Material. One semantics node per row (button in a mutually
// exclusive group, checked state); disabled rows are dimmed and ignore taps.

part of "../index.dart";

/// Row corner radius.
const double _rowRadius = 10;

/// Radio icon size.
const double _radioIconSize = 20;

/// Background opacity of the selected row (over `cs.primary`).
const double _selectedFillAlpha = 0.08;

/// Border width of the selected row.
const double _selectedBorderWidth = 1.5;

/// Opacity of a disabled row (Material 3 disabled content).
const double _disabledOpacity = 0.38;

/// Share of the row content width the trailing hint may take at most.
const double _trailingMaxWidthFactor = 0.5;

final class _OptionRow<T extends Object> extends StatelessWidget {
  final ChoiceOption<T> option;
  final bool isSelected;
  final ValueChanged<T> onSelected;

  const _OptionRow({
    required this.option,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ShapeBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_rowRadius),
      side: BorderSide(
        color: isSelected ? cs.primary : cs.outlineVariant,
        width: isSelected ? _selectedBorderWidth : 1,
      ),
    );

    // The visible texts are excluded (not the InkWell) so the node keeps its
    // tap action while carrying the combined label.
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding),
      child: Semantics(
        container: true,
        button: true,
        checked: isSelected,
        inMutuallyExclusiveGroup: true,
        enabled: option.enabled,
        label: _semanticsLabel(),
        child: Material(
          color: isSelected ? cs.primary.withValues(alpha: _selectedFillAlpha) : Colors.transparent,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: option.enabled ? () => onSelected(option.value) : null,
            customBorder: shape,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kMinTapTarget),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding * 2,
                  vertical: kDefaultPadding,
                ),
                child: Opacity(
                  opacity: option.enabled ? 1 : _disabledOpacity,
                  child: ExcludeSemantics(
                    child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) =>
                          _content(context, constraints.maxWidth),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// [ChoiceOption.semanticsLabel], or the label followed by the trailing hint.
  String _semanticsLabel() {
    final String? trailing = option.trailing;
    if (option.semanticsLabel case final String label) return label;
    if (trailing == null || trailing.isEmpty) return option.label;
    return "${option.label}, $trailing";
  }

  /// Radio icon, label and the optional trailing hint (at most half of
  /// [rowWidth], one line, ellipsized).
  Widget _content(BuildContext context, double rowWidth) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? trailing = option.trailing;

    return Row(
      children: <Widget>[
        Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          size: _radioIconSize,
          color: isSelected ? cs.primary : cs.onSurfaceVariant,
        ),
        const SizedBox(width: kDefaultPadding),
        Expanded(
          child: Text(
            option.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
        if (trailing != null && trailing.isNotEmpty) ...<Widget>[
          const SizedBox(width: kDefaultPadding),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: rowWidth * _trailingMaxWidthFactor),
            child: Text(
              trailing,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
