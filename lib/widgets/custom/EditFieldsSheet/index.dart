// index.dart
//
// EditFieldsSheet — sheet content for editing a few text values and saving
// them with an async call: a title and optional subtitle, one labelled text
// field per EditSheetField, an inline error and a cancel / save action bar.
// Save is enabled only while a value differs from its initial value. State
// lives in view_model.dart, the tree in view.dart and the private pieces in
// widgets/.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/utils/load_state.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";

part "view_model.dart";
part "view.dart";
part "widgets/action_bar.dart";
part "widgets/field_block.dart";
part "widgets/sheet_header.dart";

/// One editable text field of an [EditFieldsSheet].
@immutable
final class EditSheetField {
  /// Key of this field in the values map passed to [EditFieldsSheet.onSubmit].
  /// Must be unique within [EditFieldsSheet.fields].
  final String id;

  /// Visible label, rendered uppercase above the field; also the spoken label
  /// of the text field.
  final String label;

  /// Placeholder shown while the field is empty; none when null.
  final String? hint;

  /// Starting text, and the reference for dirty detection.
  final String initialValue;

  /// Minimum visible lines of a multi-line field.
  final int minLines;

  /// 1 = single line (default); null = grows with its content.
  final int? maxLines;

  /// Caps the input and shows a character counter when set.
  final int? maxLength;

  const EditSheetField({
    required this.id,
    required this.label,
    this.hint,
    this.initialValue = "",
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
  }) : assert(minLines > 0),
       assert(maxLines == null || maxLines >= minLines),
       assert(maxLength == null || maxLength > 0);
}

/// Form panel that edits the text values described by [fields] and commits
/// them with [onSubmit], hosted in a modal bottom sheet or an `AppModal`.
///
/// Renders, top to bottom:
/// - [title] (18, w800, `cs.onSurface`, header semantics) and the optional
///   [subtitle] (`textTheme.bodySmall`, `cs.onSurfaceVariant`);
/// - one block per [EditSheetField], in order: its `label` uppercase
///   (10, w700, tracking 0.6, `cs.onSurfaceVariant`) above an outlined text
///   field (radius 10) showing `hint`, seeded with `initialValue`, with
///   `minLines` / `maxLines` and a counter when `maxLength` is set. Label and
///   field form one semantics node labelled with `label`;
/// - the inline error after a failed save (`cs.error`, live region);
/// - the action bar: an outlined cancel button and a filled save button,
///   equal widths, 48 dp tall, radius 10.
///
/// When the panel is too short (many fields, a short screen, an open
/// keyboard) the header and the field blocks scroll together; the inline
/// error and the action bar stay pinned below them.
///
/// Save is enabled only while at least one field's text differs from its
/// `initialValue` (untrimmed comparison). It calls [onSubmit] once with every
/// field's trimmed text keyed by `id` (changed or not). While [onSubmit]
/// runs, the fields and both buttons are disabled and the save button shows a
/// [Loader]. On success [onSaved] receives the same values; on failure the
/// form is re-enabled and the inline error shows [errorMessage] for that
/// error, or `custom.edit_fields_sheet.save_failed` when [errorMessage] is
/// null or returns null. The next save attempt clears it. The cancel button
/// calls [onCancel].
///
/// The widget never closes itself: the host dismisses its container in
/// [onSaved] and [onCancel]. Content only: no drag handle, no background, no
/// route handling. Host it with [EditFieldsSheet.show] (modal bottom sheet
/// with the M3 drag handle, resolves with the saved values) or inside
/// `AppModal`. It needs a bounded height (both hosts provide one) and a
/// [Material] ancestor.
///
/// The text fields' selection handles and toolbar need an [Overlay]
/// ancestor (a routed page or a modal).
///
/// Built-in strings: `custom.edit_fields_sheet.cancel` and
/// `custom.edit_fields_sheet.save` (default button labels, replaced by
/// [cancelLabel] / [submitLabel]) and `custom.edit_fields_sheet.save_failed`
/// (default error message).
final class EditFieldsSheet extends StatefulWidget {
  /// Header text, already localised.
  final String title;

  /// Optional line under the title; omitted when null or empty.
  final String? subtitle;

  /// Editable fields in display order. Ids must be unique. A field whose id
  /// is new on rebuild gets a fresh text controller; the others keep the
  /// user's text, focus and input connection, even when fields are inserted
  /// or removed around them.
  final List<EditSheetField> fields;

  /// Commits the trimmed values keyed by [EditSheetField.id]. Throw to keep
  /// the panel open with an inline error.
  final Future<void> Function(Map<String, String> values) onSubmit;

  /// Called with the submitted values once [onSubmit] completed.
  final ValueChanged<Map<String, String>> onSaved;

  /// Called by the cancel button.
  final VoidCallback onCancel;

  /// Maps a thrown error to the inline message; null (or a null result)
  /// shows `custom.edit_fields_sheet.save_failed`.
  final String? Function(Object error)? errorMessage;

  /// Replaces the default save label (`custom.edit_fields_sheet.save`).
  final String? submitLabel;

  /// Replaces the default cancel label (`custom.edit_fields_sheet.cancel`).
  final String? cancelLabel;

  const EditFieldsSheet({
    super.key,
    required this.title,
    required this.fields,
    required this.onSubmit,
    required this.onSaved,
    required this.onCancel,
    this.subtitle,
    this.errorMessage,
    this.submitLabel,
    this.cancelLabel,
  });

  /// Share of the screen height the sheet content may take in [show].
  static const double _maxHeightFactor = 0.7;

  /// Sheet enter / exit durations in [show] (the Material defaults), resolved
  /// with [resolveMotion].
  static const Duration _sheetEnterDuration = Duration(milliseconds: 250);
  static const Duration _sheetExitDuration = Duration(milliseconds: 200);

  /// Opens the panel in a modal bottom sheet (`showDragHandle: true`, theme
  /// surface, top radius 16, scroll-controlled, safe area) that follows the
  /// keyboard and takes at most 70 % of the screen height. The sheet slides
  /// in and out without animation when the platform asks to reduce motion.
  ///
  /// Resolves with the saved values, or null when the sheet is closed by the
  /// cancel button, a scrim tap or a drag without a successful save. Mount
  /// the widget yourself to change the button labels.
  static Future<Map<String, String>?> show({
    required BuildContext context,
    required String title,
    required List<EditSheetField> fields,
    required Future<void> Function(Map<String, String> values) onSubmit,
    String? subtitle,
    String? Function(Object error)? errorMessage,
  }) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      clipBehavior: Clip.antiAlias,
      sheetAnimationStyle: AnimationStyle(
        duration: resolveMotion(context, _sheetEnterDuration),
        reverseDuration: resolveMotion(context, _sheetExitDuration),
      ),
      builder: (BuildContext sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * _maxHeightFactor,
          ),
          child: EditFieldsSheet(
            title: title,
            subtitle: subtitle,
            fields: fields,
            onSubmit: onSubmit,
            errorMessage: errorMessage,
            onSaved: (Map<String, String> values) => _popSheet(sheetContext, values),
            onCancel: () => _popSheet(sheetContext, null),
          ),
        ),
      ),
    );
  }

  /// Pops the sheet's own route, only while it is still the current route
  /// (a save that completes during the closing animation must not pop the
  /// page underneath).
  static void _popSheet(BuildContext sheetContext, Map<String, String>? result) {
    final ModalRoute<Object?>? route = ModalRoute.of(sheetContext);
    if (route == null || !route.isCurrent) return;
    Navigator.of(sheetContext).pop<Map<String, String>>(result);
  }

  @override
  State<EditFieldsSheet> createState() => _EditFieldsSheetState();
}
