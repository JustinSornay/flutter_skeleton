// index.dart
//
// MaskedDigitField — digit text field driven by a '#' pattern: '#' is a digit
// slot, any other character a separator written automatically between digits
// as the user types. Input stops at the slot count, non-digits are rejected
// and the caller only receives raw digits. The pure DigitMask formatter lives
// in controllers/digit_mask.dart, the keystroke formatter in
// controllers/mask_input_formatter.dart, state in view_model.dart and the
// TextField in view.dart.

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "controllers/digit_mask.dart";
part "controllers/mask_input_formatter.dart";
part "view_model.dart";
part "view.dart";

/// Outlined text field that formats digits into [pattern] as the user types.
///
/// - [pattern]: `#` marks one digit slot; any other character is a separator
///   written only when a digit follows it, e.g. `"# ## ## ## ##"` (phone),
///   `"#### #### #### ####"` (card), `"##/##/####"` (date as digits). Typing
///   `612345678` in `"# ## ## ## ##"` shows `6 12 34 56 78`. Input stops at
///   the number of `#` slots; letters and symbols, typed or pasted, are
///   dropped. The caret always returns to the end after an edit.
/// - [onChanged]: raw digits (no separators) after every user edit that
///   changes them, and once after the frame when a new [pattern] truncates
///   the current value (so a host may call `setState` in it). A [pattern]
///   change that keeps every digit reformats the text without notifying.
/// - [hintText]: placeholder, already localised by the host. Defaults to
///   [DigitMask.sample] (`"# ## ## ## ##"` → `1 23 45 67 89`).
/// - [labelText]: visible floating label and accessible name. Hosts should
///   pass it (or a descriptive [hintText]): without a label the hint becomes
///   the accessible name, so a screen reader would announce the default
///   sample (`1 23 45 67 89`) as the field's name.
/// - [errorText]: validation message under the field; the field and the
///   message turn `cs.error`.
/// - [keyboardType]: soft keyboard; pass [TextInputType.phone] for phone
///   numbers.
///
/// The widget owns its text controller; use [DigitMask.format] to display a
/// stored value with the same grouping. Any prefix (such as a dial-code
/// picker) is composed by the host next to the field:
///
/// ```dart
/// Row(
///   children: <Widget>[
///     dialCodePicker, // host widget
///     const SizedBox(width: kDefaultPadding),
///     Expanded(
///       child: MaskedDigitField(
///         pattern: "# ## ## ## ##",
///         labelText: numberLabel, // localised by the host; accessible name
///         keyboardType: TextInputType.phone,
///         onChanged: (String digits) => setState(() => _digits = digits),
///       ),
///     ),
///   ],
/// )
/// ```
///
/// Borders: `cs.outline` at rest and `cs.primary` (1.5) on focus, radius 8.
/// The field is at least [kMinTapTarget] tall.
///
/// Needs an `Overlay` ancestor (a routed page or a modal): the inner
/// [TextField] shows its selection handles and context menu there.
final class MaskedDigitField extends StatefulWidget {
  /// `#` = one digit slot; any other character is a separator.
  final String pattern;

  /// Raw digits after each change (see the class documentation).
  final ValueChanged<String>? onChanged;

  /// Placeholder; defaults to `DigitMask(pattern).sample()`. Without
  /// [labelText] it is also the accessible name, so make it descriptive then.
  final String? hintText;

  /// Visible floating label and accessible name. Pass it: otherwise the hint
  /// (by default the sample number) is announced as the field's name.
  final String? labelText;

  /// Validation message shown under the field in `cs.error`.
  final String? errorText;

  /// Soft keyboard type.
  final TextInputType keyboardType;

  const MaskedDigitField({
    super.key,
    required this.pattern,
    this.onChanged,
    this.hintText,
    this.labelText,
    this.errorText,
    this.keyboardType = TextInputType.number,
  });

  @override
  State<MaskedDigitField> createState() => _MaskedDigitFieldState();
}
