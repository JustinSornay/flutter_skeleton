// view_model.dart
//
// _FileUploadPanelState — selection and upload lifecycle of FileUploadPanel.
// The upload is a LoadState<void>: Idle, Loading while onUpload runs,
// Loaded after a success, LoadError(key) after a read error or a failure (the
// i18n key, translated by the view so a locale switch re-translates it).
// Every update and callback after an await is guarded with `mounted`.

part of "index.dart";

final class _FileUploadPanelState extends State<FileUploadPanel> with _ViewMixin {
  /// Current selection, in picker order.
  List<SelectedFile> files = const <SelectedFile>[];

  /// Upload state, rendered by the status area with an exhaustive switch.
  LoadState<void> uploadState = const Idle<void>();

  /// True while [FileUploadPanel.onUpload] runs.
  bool get isUploading => uploadState.isLoading;

  /// True when "Upload" is enabled: files are selected, no upload runs and
  /// the current selection was not uploaded yet.
  bool get canSubmit => files.isNotEmpty && !isUploading && uploadState is! Loaded<void>;

  /// Opens the picker and replaces the selection with its non-null result.
  /// A picker failure goes to [FileUploadPanel.onError] and changes nothing.
  Future<void> pick() async {
    if (isUploading) return;
    final List<SelectedFile>? picked;
    try {
      picked = await widget.pickFiles(
        allowedExtensions: widget.allowedExtensions,
        allowMultiple: widget.allowMultiple,
      );
    } catch (error) {
      if (mounted) widget.onError?.call(error);
      return;
    }
    if (!mounted || picked == null || isUploading) return;
    final List<SelectedFile> selection = List<SelectedFile>.unmodifiable(picked);
    setState(() {
      files = selection;
      uploadState = const Idle<void>();
    });
  }

  /// Empties the selection and resets the status.
  void clear() {
    if (isUploading) return;
    setState(() {
      files = const <SelectedFile>[];
      uploadState = const Idle<void>();
    });
  }

  /// Uploads the readable files of the selection.
  Future<void> submit() async {
    if (!canSubmit) return;
    final List<SelectedFile> readable = List<SelectedFile>.unmodifiable(
      files.where((SelectedFile file) => file.bytes != null),
    );
    if (readable.isEmpty) {
      setState(() => uploadState = const LoadError<void>("custom.file_upload_panel.read_error"));
      return;
    }

    setState(() => uploadState = const Loading<void>());
    try {
      await widget.onUpload(readable);
    } catch (error) {
      if (!mounted) return;
      setState(() => uploadState = const LoadError<void>("custom.file_upload_panel.failed"));
      widget.onError?.call(error);
      return;
    }
    if (!mounted) return;
    setState(() => uploadState = const Loaded<void>(null));
    widget.onSuccess?.call();
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}
