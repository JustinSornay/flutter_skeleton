// skeleton_row.dart
//
// _SkeletonRow — one static placeholder row of MasterListPanel's loading
// state, mirroring the item row layout: title + trailing bars, a subtitle
// bar and three tag pills (SkeletonBlock). The bars of a line shrink in
// proportion to their width, so a narrow panel never overflows. The panel
// wraps each row in SkeletonPulse.

part of "../index.dart";

/// One placeholder row: title + trailing bars, a subtitle bar, three pills.
final class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 2, vertical: kDefaultPadding * 1.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[_bar(140, 12, 4), _bar(60, 10, 4)],
          ),
          const SizedBox(height: kDefaultPadding * 0.75),
          const SkeletonBlock(width: 120, height: 10, borderRadius: 4),
          const SizedBox(height: kDefaultPadding * 0.75),
          Row(
            children: <Widget>[
              _bar(45, 14, 999),
              const SizedBox(width: _textGap),
              _bar(55, 14, 999),
              const SizedBox(width: _textGap),
              _bar(40, 14, 999),
            ],
          ),
        ],
      ),
    );
  }

  /// A [SkeletonBlock] [width] wide at most, shrinking with its flex share
  /// (proportional to [width]) when the line is too narrow.
  static Widget _bar(double width, double height, double borderRadius) {
    return Flexible(
      flex: width.round(),
      child: SkeletonBlock(width: width, height: height, borderRadius: borderRadius),
    );
  }
}
