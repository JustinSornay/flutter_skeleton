// sheet_header.dart
//
// _SheetHeader — title (semantics header) and the 48 dp close button of
// SingleSelectSheet. The close button's Tooltip needs an Overlay ancestor.

part of "../index.dart";

final class _SheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _SheetHeader({
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kDefaultPadding * 3,
        kDefaultPadding,
        kDefaultPadding * 2,
        kDefaultPadding,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: "custom.single_select_sheet.close".tr(),
            onPressed: onClose,
            color: cs.onSurfaceVariant,
            style: IconButton.styleFrom(
              minimumSize: const Size.square(kMinTapTarget),
            ),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
