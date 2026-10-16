// field_block.dart
//
// _FieldBlock — one EditSheetField of EditFieldsSheet: the uppercase label
// above an outlined text field, merged into one semantics node labelled
// with the field label. Multi-line fields use a roomier text style. The view
// keys each block by field id so focus and input follow the field.

part of "../index.dart";

/// Text field corner radius.
const double _fieldRadius = 10;

final class _FieldBlock extends StatelessWidget {
  final EditSheetField field;
  final TextEditingController controller;
  final bool enabled;

  const _FieldBlock({
    super.key,
    required this.field,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool multiline = field.maxLines != 1;
    final TextStyle? inputStyle = multiline
        ? theme.textTheme.bodyMedium?.copyWith(fontSize: 13.5, height: 1.4, color: cs.onSurface)
        : theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            field.label.toUpperCase(),
            semanticsLabel: field.label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: kDefaultPadding),
          TextField(
            controller: controller,
            enabled: enabled,
            minLines: field.minLines,
            maxLines: field.maxLines,
            maxLength: field.maxLength,
            style: inputStyle,
            decoration: InputDecoration(
              hintText: field.hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(_fieldRadius)),
              contentPadding: const EdgeInsets.all(kDefaultPadding * 1.5),
              counterStyle: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
