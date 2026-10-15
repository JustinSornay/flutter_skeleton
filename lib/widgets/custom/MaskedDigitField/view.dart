// view.dart
//
// Layout of MaskedDigitField: one outlined TextField (radius 8, cs.outline at
// rest, cs.primary on focus, cs.error with an error) with the mask formatter,
// letter-spaced text, the pattern sample as default hint and kDefaultPadding
// based padding. ColorScheme tokens only.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, _MaskedDigitFieldState state) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final MaskedDigitField widget = state.widget;
    final BorderRadius radius = BorderRadius.circular(8);
    final OutlineInputBorder restBorder = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: cs.outline),
    );

    return TextField(
      controller: state._controller,
      keyboardType: widget.keyboardType,
      inputFormatters: <TextInputFormatter>[_MaskInputFormatter(state._mask)],
      onChanged: state._onTextChanged,
      // Merged into the TextField default (bodyLarge, cs.onSurface).
      style: const TextStyle(letterSpacing: 1),
      decoration: InputDecoration(
        labelText: widget.labelText,
        errorText: widget.errorText,
        hintText: widget.hintText ?? state._mask.sample(),
        hintStyle: TextStyle(color: cs.onSurfaceVariant, letterSpacing: 1),
        // With an error, the decorator recolours this border with cs.error.
        border: restBorder,
        enabledBorder: restBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(kDefaultPadding * 2),
        constraints: const BoxConstraints(minHeight: kMinTapTarget),
      ),
    );
  }
}
