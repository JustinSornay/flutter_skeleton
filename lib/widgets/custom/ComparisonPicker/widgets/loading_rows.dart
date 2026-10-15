// loading_rows.dart
//
// Loading placeholder of ComparisonPicker's secondary section: 3 row-sized
// SkeletonBlocks pulsing together in one SkeletonPulse. Under reduced motion
// no SkeletonPulse is mounted, so nothing keeps animating.

part of "../index.dart";

/// Number and height of the placeholder rows.
const int _skeletonRowCount = 3;
const double _skeletonRowHeight = kDefaultPadding * 5;

final class _LoadingRows extends StatelessWidget {
  const _LoadingRows();

  @override
  Widget build(BuildContext context) {
    final Widget rows = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(
        _skeletonRowCount,
        (int _) => const Padding(
          padding: EdgeInsets.only(bottom: _rowGap),
          child: SkeletonBlock(height: _skeletonRowHeight, borderRadius: _rowRadius),
        ),
      ),
    );

    return Semantics(
      container: true,
      label: "custom.comparison_picker.loading".tr(),
      child: MediaQuery.disableAnimationsOf(context) ? rows : SkeletonPulse(child: rows),
    );
  }
}
