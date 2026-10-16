// view_model.dart
//
// State of ExpandableCard: the expanded flag, seeded from
// `initiallyExpanded` and flipped by a header tap, which is reported to
// `onExpandedChanged`. Rendering is delegated to view.dart.

part of "index.dart";

final class _ExpandableCardState extends State<ExpandableCard> with _ViewMixin {
  late bool _expanded = widget.initiallyExpanded;

  /// Flips the expanded state and reports the new value to the host.
  void _toggle() {
    setState(() => _expanded = !_expanded);
    widget.onExpandedChanged?.call(_expanded);
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}
