// slot_header.dart
//
// Radio-mode header of ComparisonPicker: the A and B letter badges, each
// centred above its radio column, then the optional column title.

part of "../index.dart";

/// Size and radius of a letter badge.
const double _badgeWidth = kDefaultPadding * 3;
const double _badgeHeight = kDefaultPadding * 2;
const double _badgeRadius = 4;

final class _SlotHeader extends StatelessWidget {
  /// Column title, already localised. Null or empty shows the badges only.
  final String? label;

  const _SlotHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? label = this.label;

    // Same horizontal inset as the rows so each badge sits over its radio.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
      child: Row(
        children: <Widget>[
          _badge(context, _Slot.a, "custom.comparison_picker.slot_a".tr()),
          _badge(context, _Slot.b, "custom.comparison_picker.slot_b".tr()),
          if (label != null && label.isNotEmpty) ...<Widget>[
            const SizedBox(width: kDefaultPadding),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(BuildContext context, _Slot slot, String letter) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return SizedBox(
      width: kMinTapTarget,
      child: Center(
        child: Container(
          width: _badgeWidth,
          height: _badgeHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: _slotColor(cs, slot), borderRadius: BorderRadius.circular(_badgeRadius)),
          child: Text(
            letter,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _onSlotColor(cs, slot),
            ),
          ),
        ),
      ),
    );
  }
}
