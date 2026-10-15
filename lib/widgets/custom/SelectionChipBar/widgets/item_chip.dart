// item_chip.dart
//
// Private chip of SelectionChipBar: optional leading icon, one-line label and,
// when the bar is removable, a trailing _RemoveButton (widgets/
// remove_button.dart). Disabled items are dimmed and cannot be removed.

part of "../index.dart";

/// Chip corner radius (matches the action button).
const double _chipRadius = 8;

/// Height of a read-only chip (Material 3 chip height). A removable chip is
/// as tall as its 48 dp remove button.
const double _chipMinHeight = kDefaultPadding * 4;

/// Leading icon size.
const double _chipIconSize = 16;

/// Opacity of a disabled chip (Material 3 disabled content).
const double _disabledChipOpacity = 0.38;

final class _ItemChip<T> extends StatelessWidget {
  final ChoiceOption<T> item;

  /// Null renders a read-only chip without a remove button.
  final ValueChanged<T>? onRemove;

  const _ItemChip({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color foreground = cs.onSecondaryContainer;
    final ValueChanged<T>? onRemove = this.onRemove;
    final IconData? icon = item.icon;

    final Widget chip = Semantics(
      container: true,
      child: Material(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(_chipRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _chipMinHeight),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: kDefaultPadding * 1.5,
              end: onRemove == null ? kDefaultPadding * 1.5 : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: _chipIconSize, color: foreground),
                  const SizedBox(width: kDefaultPadding / 2),
                ],
                Flexible(
                  child: Text(
                    item.label,
                    semanticsLabel: item.semanticsLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                if (onRemove != null)
                  _RemoveButton(
                    label: item.label,
                    color: foreground,
                    onPressed: item.enabled ? () => onRemove(item.value) : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return item.enabled ? chip : Opacity(opacity: _disabledChipOpacity, child: chip);
  }
}
