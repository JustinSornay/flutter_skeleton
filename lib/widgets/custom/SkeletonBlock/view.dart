// view.dart
//
// _ViewMixin — rendering for SkeletonBlock: one Container filled with
// cs.surfaceContainerHighest and rounded by borderRadius.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, SkeletonBlock widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
    );
  }
}
