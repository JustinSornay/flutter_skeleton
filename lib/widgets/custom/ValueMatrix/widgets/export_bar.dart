// export_bar.dart
//
// _ExportBar — the bottom bar of ValueMatrix: a cs.outlineVariant top border
// and an end-aligned cs.primary OutlinedButton.icon (download icon +
// custom.value_matrix.export_csv), at least kMinTapTarget tall.

part of "../index.dart";

final class _ExportBar extends StatelessWidget {
  /// Builds and hands over the CSV.
  final VoidCallback onPressed;

  const _ExportBar({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 2, vertical: kDefaultPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text("custom.value_matrix.export_csv".tr()),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.primary,
                side: BorderSide(color: cs.primary),
                minimumSize: const Size(kMinTapTarget, kMinTapTarget),
                padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 2, vertical: kDefaultPadding),
                textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
