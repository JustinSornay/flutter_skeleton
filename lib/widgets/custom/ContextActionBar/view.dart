// view.dart
//
// Tree of ContextActionBar: the visibility guards (ExcludeSemantics +
// IgnorePointer while hidden), the labelled semantics group and the row of
// _ActionButton (widgets/action_button.dart), one per item.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, _ContextActionBarState state) {
    final ContextActionBar widget = state.widget;
    final bool hidden = !widget.visible;

    return ExcludeSemantics(
      excluding: hidden,
      child: IgnorePointer(
        ignoring: hidden,
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          label: widget.semanticLabel ?? "custom.context_action_bar.semantics_label".tr(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < widget.actions.length; i++)
                _ActionButton(
                  item: widget.actions[i],
                  animation: state._animations[i],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
