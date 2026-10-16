// view_model.dart
//
// State of CollapsedGateGroup: owns the expanded flag, seeded from
// initiallyExpanded, and toggles it when the header is tapped.

part of "index.dart";

final class _CollapsedGateGroupState extends State<CollapsedGateGroup> with _ViewMixin {
  bool _isExpanded = false;

  /// Whether the feature list and the call to action are shown.
  bool get isExpanded => _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  /// Flips [isExpanded].
  void toggle() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}
