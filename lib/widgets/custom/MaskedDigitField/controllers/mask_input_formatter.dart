// mask_input_formatter.dart
//
// _MaskInputFormatter — TextInputFormatter applying a DigitMask on every
// keystroke of MaskedDigitField: keeps the digits, clamps them to the slot
// count and collapses the caret at the end.

part of "../index.dart";

/// Reformats each edit with [mask]; the caret always lands at the end because
/// inserted or removed separators shift positions inside the text.
final class _MaskInputFormatter extends TextInputFormatter {
  final DigitMask mask;

  const _MaskInputFormatter(this.mask);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final String formatted = mask.format(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
