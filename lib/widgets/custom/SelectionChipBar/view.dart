// view.dart
//
// Tree of SelectionChipBar: the slide + fade visibility wrapper and the
// guards that make a hidden bar inert (IgnorePointer, ExcludeFocus,
// ExcludeSemantics), the inverse-surface bar, the wrapping row of _ItemChip
// (widgets/item_chip.dart) and the width-capped FilledButton action. Colours
// come from the ColorScheme only.

part of "index.dart";

/// Bar corner radius.
const double _barRadius = 12;

/// Bar elevation (shadow in `cs.shadow`).
const double _barElevation = 6;

/// Corner radius of the action button (matches the chips).
const double _buttonRadius = 8;

/// Width always left to the chips beside the action button: one removable
/// chip (12 dp padding + 48 dp remove button) plus a short label.
const double _minChipsWidth = kDefaultPadding * 15;

/// Opacity of the disabled button fill / text on the inverse surface
/// (Material 3 disabled container / content).
const double _disabledFillAlpha = 0.12;
const double _disabledTextAlpha = 0.38;

mixin _ViewMixin<T> {
  Widget render(BuildContext context, SelectionChipBar<T> widget) {
    final bool visible = widget.items.isNotEmpty;
    final Duration duration = resolveMotion(context, kMotionShort);

    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        // A hidden bar is inert: no pointer, no keyboard focus (focus held by
        // the action is dropped) and no semantics, also during the fade-out.
        child: IgnorePointer(
          ignoring: !visible,
          child: ExcludeFocus(
            excluding: !visible,
            child: ExcludeSemantics(
              excluding: !visible,
              child: _bar(context, widget),
            ),
          ),
        ),
      ),
    );
  }

  /// Inverse-surface card: wrapping chips on the left, the action on the right.
  Widget _bar(BuildContext context, SelectionChipBar<T> widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ValueChanged<T>? onRemove = widget.onRemove;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding * 2,
        vertical: kDefaultPadding * 1.5,
      ),
      child: Material(
        color: cs.inverseSurface,
        elevation: _barElevation,
        shadowColor: cs.shadow,
        borderRadius: BorderRadius.circular(_barRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding * 1.5,
            vertical: kDefaultPadding,
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) => Row(
              children: <Widget>[
                Expanded(
                  child: Wrap(
                    spacing: kDefaultPadding,
                    runSpacing: kDefaultPadding * 0.75,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      for (final ChoiceOption<T> item in widget.items)
                        _ItemChip<T>(item: item, onRemove: onRemove),
                    ],
                  ),
                ),
                const SizedBox(width: kDefaultPadding),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: math.max(
                      kMinTapTarget,
                      constraints.maxWidth - kDefaultPadding - _minChipsWidth,
                    ),
                  ),
                  child: _actionButton(cs, widget),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Primary action, enabled once enough items are selected. A label wider
  /// than the cap set by [_bar] is ellipsised on one line.
  Widget _actionButton(ColorScheme cs, SelectionChipBar<T> widget) {
    final bool canAct = widget.items.length >= widget.minItems;

    return FilledButton(
      onPressed: canAct ? widget.onAction : null,
      style: FilledButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        disabledBackgroundColor: cs.onInverseSurface.withValues(alpha: _disabledFillAlpha),
        disabledForegroundColor: cs.onInverseSurface.withValues(alpha: _disabledTextAlpha),
        minimumSize: const Size(kMinTapTarget, kMinTapTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding * 2,
          vertical: kDefaultPadding * 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_buttonRadius)),
      ),
      child: Text(
        widget.actionLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}
