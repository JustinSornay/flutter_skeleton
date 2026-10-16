// summary_skeleton.dart
//
// _SummarySkeleton — loading placeholder of AsyncSummaryCard: three 14 dp text
// lines (full, full, 200 dp) and a 140 × 12 dp footnote line, all
// SkeletonBlock with radius 4, pulsing with SkeletonPulse unless the platform
// asks to reduce motion (then static, and no ticker runs). Announced as
// custom.async_summary_card.loading.

part of "../index.dart";

final class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    const Widget lines = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SkeletonBlock(width: double.infinity, height: 14, borderRadius: 4),
        SizedBox(height: kDefaultPadding),
        SkeletonBlock(width: double.infinity, height: 14, borderRadius: 4),
        SizedBox(height: kDefaultPadding),
        SkeletonBlock(width: 200, height: 14, borderRadius: 4),
        SizedBox(height: kDefaultPadding * 2),
        SkeletonBlock(width: 140, height: 12, borderRadius: 4),
      ],
    );

    // SkeletonPulse keeps its controller repeating under reduced motion, so
    // it is not mounted at all in that case.
    return Semantics(
      container: true,
      label: "custom.async_summary_card.loading".tr(),
      child: MediaQuery.disableAnimationsOf(context) ? lines : const SkeletonPulse(child: lines),
    );
  }
}
