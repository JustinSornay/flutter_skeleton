// selection_card.dart
//
// _SelectionCard — the picked item of PolygonFormSheet: an EditableValueRow
// in a bordered card (cs.surfaceContainerLowest, cs.outlineVariant, radius
// 12). Tapping the card goes back to the picker; a null onTap disables it.

part of "../index.dart";

/// Card corner radius.
const double _kCardRadius = 12;

final class _SelectionCard extends StatelessWidget {
  final PolygonFormSelection selection;
  final IconData icon;
  final VoidCallback? onTap;

  const _SelectionCard({
    required this.selection,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kCardRadius),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding * 1.5),
          child: EditableValueRow(
            icon: icon,
            title: selection.title,
            subtitle: selection.subtitle,
            subtitleItalic: selection.subtitleItalic,
            semanticsLabel: "custom.polygon_form_sheet.change_selection".tr(),
          ),
        ),
      ),
    );
  }
}
