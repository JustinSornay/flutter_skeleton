// view_model.dart
//
// _SearchFieldState — tracks focus and "has text" for SearchField. Listens to
// the caller's controller and to the focus node (caller's or internal), moves
// those listeners when the parent swaps either one, and disposes the focus
// node only when it is internal.

part of "index.dart";

final class _SearchFieldState extends State<SearchField> with _ViewMixin {
  /// The caller's node, or an internal one when [SearchField.focusNode] is null.
  late FocusNode _focusNode;

  /// Whether [_focusNode] has focus; drives the border and glow.
  bool _focused = false;

  /// Whether the controller holds text; drives the clear button.
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focused = _focusNode.hasFocus;
    _hasText = widget.controller.text.isNotEmpty;
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void didUpdateWidget(SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChange);
      widget.controller.addListener(_onTextChange);
      _hasText = widget.controller.text.isNotEmpty;
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      if (oldWidget.focusNode == null) _focusNode.dispose();
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChange);
      _focused = _focusNode.hasFocus;
    }
  }

  void _onFocusChange() {
    final bool focused = _focusNode.hasFocus;
    if (focused != _focused) setState(() => _focused = focused);
  }

  void _onTextChange() {
    final bool hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}
