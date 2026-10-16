// card_frame.dart
//
// _CardFrame — shared frame of every AsyncSummaryCard state: a full-width
// cs.surfaceContainerLow Material (ink surface for the retry button), radius
// 16, 1 dp cs.outlineVariant border, children clipped to the corners.

part of "../index.dart";

final class _CardFrame extends StatelessWidget {
  /// Inner padding; null lets the child pad itself (loaded state).
  final EdgeInsetsGeometry? padding;

  final Widget child;

  const _CardFrame({this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final EdgeInsetsGeometry? padding = this.padding;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        animationDuration: resolveMotion(context, kThemeChangeDuration),
        child: padding == null ? child : Padding(padding: padding, child: child),
      ),
    );
  }
}
