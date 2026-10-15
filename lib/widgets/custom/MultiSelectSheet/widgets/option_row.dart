// option_row.dart
//
// _OptionRow — one checkbox row of MultiSelectSheet: checkbox, one-line
// label and the optional trailing badge. The row and its checkbox both
// toggle; a disabled row (option disabled or cap reached) ignores taps and
// mutes its label. One merged semantics node per row.

part of "../index.dart";

/// Checkbox corner radius.
const double _checkboxRadius = 4;

final class _OptionRow<K> extends StatelessWidget {
  final ChoiceOption<K> option;
  final bool isSelected;
  final bool isDisabled;
  final ValueChanged<ChoiceOption<K>> onToggle;

  const _OptionRow({
    required this.option,
    required this.isSelected,
    required this.isDisabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        selected: isSelected,
        enabled: !isDisabled,
        child: InkWell(
          onTap: isDisabled ? null : () => onToggle(option),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTapTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
                vertical: kDefaultPadding,
              ),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) =>
                    _content(context, constraints.maxWidth),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Checkbox, one-line label and the optional badge (at most half of
  /// [rowWidth]).
  Widget _content(BuildContext context, double rowWidth) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? trailing = option.trailing;

    return Row(
      children: <Widget>[
        Checkbox(
          value: isSelected,
          onChanged: isDisabled ? null : (bool? _) => onToggle(option),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(_checkboxRadius)),
          ),
        ),
        const SizedBox(width: kDefaultPadding),
        Expanded(
          child: Text(
            option.label,
            semanticsLabel: option.semanticsLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDisabled ? cs.onSurfaceVariant : cs.onSurface,
            ),
          ),
        ),
        if (trailing != null && trailing.isNotEmpty) ...<Widget>[
          const SizedBox(width: kDefaultPadding),
          ExcludeSemantics(
            excluding: option.semanticsLabel != null,
            child: _Pill(
              text: trailing,
              radius: _badgeRadius,
              rowWidth: rowWidth,
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
                vertical: kDefaultPadding / 4,
              ),
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }
}
