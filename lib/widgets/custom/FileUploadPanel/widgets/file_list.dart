// file_list.dart
//
// _FileList — selected files of FileUploadPanel (one _FileRow each: icon,
// name, formatted size, one semantics label) and the right-aligned 48 dp
// "Clear" action, disabled while an upload runs.

part of "../index.dart";

final class _FileList extends StatelessWidget {
  final List<SelectedFile> files;

  /// null disables the clear action.
  final VoidCallback? onClear;

  const _FileList({required this.files, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? locale = Localizations.maybeLocaleOf(context)?.toLanguageTag();
    return Padding(
      padding: const EdgeInsets.only(top: kDefaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final SelectedFile file in files) _FileRow(file: file, locale: locale),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                foregroundColor: cs.onSurfaceVariant,
                minimumSize: const Size(kMinTapTarget, kMinTapTarget),
                textStyle: theme.textTheme.labelMedium,
                // Keeps the 48 dp target on desktop (see view.dart).
                visualDensity: VisualDensity.standard,
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: Text("custom.file_upload_panel.clear".tr()),
            ),
          ),
        ],
      ),
    );
  }
}

final class _FileRow extends StatelessWidget {
  final SelectedFile file;

  /// BCP 47 tag of the current locale, for the size number format.
  final String? locale;

  const _FileRow({required this.file, required this.locale});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final FileUploadSize size = FileUploadSize.of(file.size, locale: locale);
    final String sizeText = size.key.tr(namedArgs: <String, String>{"value": size.value});
    return Semantics(
      container: true,
      label: "${file.name}, $sizeText",
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: kDefaultPadding / 2),
        child: Row(
          children: <Widget>[
            Icon(Icons.insert_drive_file_rounded, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: kDefaultPadding),
            Expanded(
              child: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface),
              ),
            ),
            const SizedBox(width: kDefaultPadding),
            Text(
              sizeText,
              style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
