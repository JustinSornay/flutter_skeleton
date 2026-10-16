// score_list_skeleton.dart
//
// _ScoreListSkeleton — loading placeholder of ScoreListCard: rowCount 48 dp
// SkeletonBlock rows, pulsing with SkeletonPulse unless the platform asks to
// reduce motion (then static, and no ticker runs). Announced as
// custom.score_list_card.loading.

part of "../index.dart";

final class _ScoreListSkeleton extends StatelessWidget {
  final int rowCount;

  const _ScoreListSkeleton({required this.rowCount});

  @override
  Widget build(BuildContext context) {
    final Widget rows = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List<Widget>.generate(
        rowCount,
        (int _) => const Padding(
          padding: EdgeInsets.only(bottom: kDefaultPadding),
          child: SkeletonBlock(width: double.infinity, height: kDefaultPadding * 6),
        ),
      ),
    );

    // SkeletonPulse keeps its controller repeating under reduced motion, so
    // it is not mounted at all in that case.
    return Semantics(
      container: true,
      label: "custom.score_list_card.loading".tr(),
      child: MediaQuery.disableAnimationsOf(context) ? rows : SkeletonPulse(child: rows),
    );
  }
}
