// view_model.dart
//
// _MaskedDigitFieldState — owns the TextEditingController and the DigitMask
// of MaskedDigitField. Forwards user edits as raw digits, and reformats the
// text when the pattern changes, notifying the host after the frame only when
// that change drops digits.

part of "index.dart";

final class _MaskedDigitFieldState extends State<MaskedDigitField> with _ViewMixin {
  /// Internal controller; never exposed to the host.
  final TextEditingController _controller = TextEditingController();

  /// Mask of the current [MaskedDigitField.pattern].
  late DigitMask _mask = DigitMask(widget.pattern);

  @override
  void didUpdateWidget(MaskedDigitField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pattern == widget.pattern) return;
    _mask = DigitMask(widget.pattern);
    final String before = DigitMask.digitsOf(_controller.text);
    final String formatted = _mask.format(before);
    if (formatted == _controller.text) return;
    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    final String after = DigitMask.digitsOf(formatted);
    if (after == before) return;
    // Deferred: the host is building, so it could not setState right now.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) widget.onChanged?.call(after);
    });
  }

  /// TextField.onChanged: fires only when the formatted text changed.
  void _onTextChanged(String text) {
    widget.onChanged?.call(DigitMask.digitsOf(text));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}
