// view.dart
//
// _ViewMixin — widget tree of FileUploadPanel: optional header, the pick
// button, the selected files with the clear action, the status area and the
// upload button, in one stretched column.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, _FileUploadPanelState state) {
    final FileUploadPanel widget = state.widget;
    final bool busy = state.isUploading;
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding * 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (widget.title != null || widget.hint != null)
            _PanelHeader(title: widget.title, hint: widget.hint),
          _pickButton(context, busy ? null : state.pick),
          if (state.files.isNotEmpty)
            _FileList(files: state.files, onClear: busy ? null : state.clear),
          const SizedBox(height: kDefaultPadding * 2),
          _UploadStatus(state: state.uploadState),
          _submitButton(context, state.canSubmit ? state.submit : null),
        ],
      ),
    );
  }

  Widget _pickButton(BuildContext context, VoidCallback? onPressed) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.attach_file_rounded, size: 18),
      label: Text("custom.file_upload_panel.pick".tr()),
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.primary,
        side: onPressed == null ? null : BorderSide(color: cs.primary),
        minimumSize: const Size(kMinTapTarget, kMinTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 2),
        // Standard density keeps the 48 dp height on desktop, where the
        // adaptive density would shrink the button to 40 dp.
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }

  Widget _submitButton(BuildContext context, VoidCallback? onPressed) {
    final TextStyle? labelStyle = Theme.of(context).textTheme.labelLarge;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(kMinTapTarget, kMinTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 2),
        textStyle: labelStyle?.copyWith(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Text("custom.file_upload_panel.submit".tr()),
    );
  }
}
