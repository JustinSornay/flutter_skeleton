// view.dart
//
// Tree of SourceBadge: an outlined, dense PillBadge carrying the description
// as its tap tooltip, under one Semantics node labelled "source: description"
// that hides the Tooltip's own semantics so the description is read once.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, SourceBadge widget) {
    final String description = widget.description;

    // The label already carries the description: excluding the subtree drops
    // PillBadge's node and the Tooltip's `tooltip` property, which would make
    // screen readers announce the description a second time.
    return Semantics(
      label: description.isEmpty ? widget.source : "${widget.source}: $description",
      excludeSemantics: true,
      child: PillBadge(
        label: widget.source,
        outlined: true,
        dense: true,
        tooltip: description,
      ),
    );
  }
}
