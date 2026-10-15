// index.dart
//
// FileUploadPanel — self-contained panel to pick files, list them with their
// sizes, clear the selection and upload it through a host callback, with an
// inline progress / success / failure status. The host injects the file
// picker and the upload transport. State lives in view_model.dart, the tree
// in view.dart, the private pieces in widgets/ and the size formatting in
// controllers/. Value class: SelectedFile.

import "dart:typed_data";

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/utils/load_state.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "controllers/file_upload_size.dart";
part "view_model.dart";
part "view.dart";
part "widgets/file_list.dart";
part "widgets/panel_header.dart";
part "widgets/upload_status.dart";

/// A file returned by the host's picker.
@immutable
final class SelectedFile {
  /// File name shown in the list (and handed back to the upload callback).
  final String name;

  /// Size in bytes, shown next to the name (B / KB / MB).
  final int size;

  /// File content, or null when the platform could not read it. Such files
  /// are listed but never uploaded.
  final Uint8List? bytes;

  const SelectedFile({
    required this.name,
    required this.size,
    this.bytes,
  }) : assert(size >= 0);
}

/// Opens the host's file picker. Resolves with null when the user cancels.
/// A thrown error (a platform or permission failure) is handed to
/// [FileUploadPanel.onError] and leaves the selection unchanged.
///
/// [allowedExtensions] lists extensions without a leading dot (`"csv"`);
/// null means any file type.
typedef FilePickerCallback = Future<List<SelectedFile>?> Function({
  List<String>? allowedExtensions,
  required bool allowMultiple,
});

/// Panel that picks files, lists them and uploads them through [onUpload].
///
/// Renders, top to bottom (outer padding `kDefaultPadding * 3`):
/// - [title] (`titleMedium`, w700, header semantics) and [hint]
///   (`bodySmall`, `cs.onSurfaceVariant`), each omitted when null;
/// - a "Select files" outlined button that calls [pickFiles] with
///   [allowedExtensions] and [allowMultiple]. A non-null result replaces the
///   selection and resets the status; null (cancelled) changes nothing; a
///   throw goes to [onError] and changes nothing;
/// - the selected files ([SelectedFile.name] and its formatted
///   [SelectedFile.size], one semantics label per row) and a "Clear" action;
/// - the status area, a live region: an indeterminate progress bar and an
///   "Uploading…" line while [onUpload] runs (the bar is omitted when the
///   platform asks to reduce motion), then a success line
///   (`StatusTone.success`) or an error line (`StatusTone.danger`), each with
///   its tone icon;
/// - an "Upload" filled button.
///
/// Upload flow:
/// - Only the files whose [SelectedFile.bytes] is non-null are passed to
///   [onUpload]. When none is readable, an inline read error shows and
///   [onUpload] is not called.
/// - While [onUpload] runs, every button is disabled.
/// - When it completes, the success line shows, "Upload" stays disabled
///   until the selection changes, and [onSuccess] is called (the host closes
///   the sheet or reloads here).
/// - When it throws, the failure line shows, [onError] receives the error
///   (the host shows a toast or logs it here) and "Upload" is enabled again
///   for a retry.
/// - [onSuccess] and [onError] are not called once the panel is unmounted
///   (for a picker failure either).
///
/// Content only: no drag handle, no background, no route handling. Host it in
/// `showModalBottomSheet(showDragHandle: true, …)`, `AppModal` or a page
/// section. The column sizes to its content: wrap the panel in a scroll view
/// when the selection may be long. Needs a [Material] ancestor (the buttons'
/// ink) but no [Overlay].
///
/// Buttons are at least [kMinTapTarget] tall on every platform: they pin the
/// standard visual density and a padded tap target, which desktop themes
/// would otherwise shrink to 40 dp.
final class FileUploadPanel extends StatefulWidget {
  /// Opens the file picker. The host wires its picker plugin here.
  final FilePickerCallback pickFiles;

  /// Uploads the readable files (every [SelectedFile.bytes] is non-null).
  /// Throw to signal a failure.
  final Future<void> Function(List<SelectedFile> files) onUpload;

  /// Called once after [onUpload] completed.
  final VoidCallback? onSuccess;

  /// Called with the error thrown by [onUpload] or by [pickFiles].
  final ValueChanged<Object>? onError;

  /// Header title, already localised by the host.
  final String? title;

  /// Helper text under the title (which files to select), already localised.
  final String? hint;

  /// Extensions accepted by the picker, without a leading dot. null = any.
  final List<String>? allowedExtensions;

  /// Whether the picker allows several files.
  final bool allowMultiple;

  const FileUploadPanel({
    super.key,
    required this.pickFiles,
    required this.onUpload,
    this.onSuccess,
    this.onError,
    this.title,
    this.hint,
    this.allowedExtensions,
    this.allowMultiple = true,
  });

  @override
  State<FileUploadPanel> createState() => _FileUploadPanelState();
}
