// selection_chip.dart
//
// _SelectionChip — one removable selection of the PolygonWizardSheet
// multi-select band: a 32 dp cs.secondaryContainer pill with the title and
// a close icon whose 48 dp target overhangs the pill vertically. The remove
// target is labelled "custom.polygon_wizard_sheet.remove_item".

part of "../index.dart";

/// Visible height of the pill.
const double _kPillHeight = 32;

/// Widest chip label before it is ellipsized.
const double _kSelectionLabelMaxWidth = 200;

final class _SelectionChip extends StatelessWidget {
  final String label;
  final VoidCallback? onRemove;

  const _SelectionChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // The pill is drawn in the middle 32 dp of the 48 dp row.
        Positioned.fill(
          top: (kMinTapTarget - _kPillHeight) / 2,
          bottom: (kMinTapTarget - _kPillHeight) / 2,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: cs.secondaryContainer,
              shape: StadiumBorder(side: BorderSide(color: cs.outlineVariant)),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(width: kDefaultPadding * 1.5),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _kSelectionLabelMaxWidth,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSecondaryContainer,
                ),
              ),
            ),
            _remove(cs),
          ],
        ),
      ],
    );
  }

  Widget _remove(ColorScheme cs) {
    return Semantics(
      container: true,
      button: true,
      enabled: onRemove != null,
      label: "custom.polygon_wizard_sheet.remove_item".tr(
        namedArgs: <String, String>{"label": label},
      ),
      child: InkResponse(
        onTap: onRemove,
        radius: kMinTapTarget / 2,
        child: SizedBox.square(
          dimension: kMinTapTarget,
          child: Icon(Icons.close, size: 16, color: cs.onSecondaryContainer),
        ),
      ),
    );
  }
}
