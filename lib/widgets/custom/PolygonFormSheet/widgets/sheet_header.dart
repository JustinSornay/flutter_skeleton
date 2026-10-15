// sheet_header.dart
//
// _SheetHeader — centred title (header semantics) between a spacer and the
// close button of PolygonFormSheet: a 28 dp round badge inside a 48 dp hit
// area. No Tooltip, so no Overlay is needed here.

part of "../index.dart";

/// Width of the slots on both sides of the title.
const double _kHeaderSlotWidth = 56;

/// Diameter of the visible close badge.
const double _kCloseBadgeSize = 28;

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
      padding: const EdgeInsets.only(bottom: kDefaultPadding),
      child: Row(
        children: <Widget>[
          const SizedBox(width: _kHeaderSlotWidth),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
          SizedBox(
            width: _kHeaderSlotWidth,
            child: Center(
              child: Semantics(
                button: true,
                label: "custom.polygon_form_sheet.close".tr(),
                child: InkResponse(
                  onTap: onClose,
                  radius: kMinTapTarget / 2,
                  child: SizedBox.square(
                    dimension: kMinTapTarget,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainer,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(
                          dimension: _kCloseBadgeSize,
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
