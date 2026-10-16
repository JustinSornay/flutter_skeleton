// option_card.dart
//
// _OptionCard — one bordered card of OptionPickerSheet: optional leading
// icon, label, optional description and a trailing check (selected) or
// chevron. One button semantics node per card that exposes the selected
// state; disabled cards are dimmed and ignore taps.

part of "../index.dart";

/// Card corner radius.
const double _cardRadius = 12;

/// Minimum card height (above [kMinTapTarget]).
const double _cardMinHeight = 72;

/// Leading icon size.
const double _leadingIconSize = 24;

/// Trailing check / chevron size.
const double _trailingIconSize = 20;

/// Opacity of a disabled card (Material 3 disabled content).
const double _disabledOpacity = 0.38;

final class _OptionCard<T> extends StatelessWidget {
  final ChoiceOption<T> option;
  final bool isSelected;
  final ValueChanged<T> onSelected;

  const _OptionCard({
    required this.option,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? semanticsLabel = option.semanticsLabel;
    final BorderRadius radius = BorderRadius.circular(_cardRadius);

    // The visible texts are excluded (not the InkWell) so the node keeps its
    // tap action when semanticsLabel replaces them.
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding),
      child: Semantics(
        container: true,
        button: true,
        selected: isSelected,
        inMutuallyExclusiveGroup: true,
        enabled: option.enabled,
        label: semanticsLabel,
        child: InkWell(
          onTap: option.enabled ? () => onSelected(option.value) : null,
          borderRadius: radius,
          child: Container(
            constraints: const BoxConstraints(minHeight: _cardMinHeight),
            padding: const EdgeInsets.all(kDefaultPadding * 2),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: isSelected ? cs.primary : cs.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Opacity(
              opacity: option.enabled ? 1 : _disabledOpacity,
              child: ExcludeSemantics(
                excluding: semanticsLabel != null,
                child: _content(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Row of the optional icon, the texts and the trailing check or chevron.
  Widget _content(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final IconData? icon = option.icon;

    return Row(
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: _leadingIconSize, color: cs.primary),
          const SizedBox(width: kDefaultPadding * 2),
        ],
        Expanded(child: _texts(context)),
        const SizedBox(width: kDefaultPadding),
        if (isSelected)
          Icon(Icons.check_circle_rounded, size: _trailingIconSize, color: cs.primary)
        else
          Icon(Icons.chevron_right_rounded, size: _trailingIconSize, color: cs.onSurfaceVariant),
      ],
    );
  }

  /// Label and, when non-empty, the description under it.
  Widget _texts(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? description = option.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          option.label,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        if (description != null && description.isNotEmpty)
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
      ],
    );
  }
}
