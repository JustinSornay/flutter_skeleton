// segmented_bar.dart
//
// Segment row of LevelProgressBar: one 6 dp pill per level, filled with
// cs.primary up to the current level, track colour (surfaceContainerHighest)
// beyond. Purely decorative: the summary semantics node describes it.

part of "../index.dart";

/// Segment thickness (6 dp, as in the original look).
const double _segmentHeight = 6;

/// Row of [segmentCount] equal pills; the first [filledCount] are filled.
final class _SegmentedBar extends StatelessWidget {
  const _SegmentedBar({required this.segmentCount, required this.filledCount});

  /// Number of segments (one per level).
  final int segmentCount;

  /// Number of filled segments, from the left.
  final int filledCount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        for (int i = 0; i < segmentCount; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: _segmentGap),
          Expanded(
            child: SizedBox(
              height: _segmentHeight,
              child: DecoratedBox(
                key: ValueKey<String>("level_progress_bar.segment.$i"),
                decoration: BoxDecoration(
                  color: i < filledCount ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
