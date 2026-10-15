// dimmed_preview.dart
//
// Private dimmed preview of FeatureGate (GateDisplayMode.dimmed): the real
// child at 40 % opacity, out of reach of pointer, keyboard focus and screen
// readers, with the lock badge in its top-right corner. When onUnlock is set
// the whole area is one InkWell of at least 48 × 48 dp.

part of "../index.dart";

/// Opacity of the dimmed child and of the teaser preview.
const double _dimmedOpacity = 0.4;

final class _DimmedPreview extends StatelessWidget {
  /// The lock badge, placed in the top-right corner.
  final Widget badge;

  final VoidCallback? onUnlock;

  /// The gated content, shown dimmed.
  final Widget child;

  const _DimmedPreview({
    required this.badge,
    required this.onUnlock,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final Widget preview = Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Opacity(
          opacity: _dimmedOpacity,
          // Inert for pointer, screen readers and keyboard focus (Tab).
          child: IgnorePointer(child: ExcludeSemantics(child: ExcludeFocus(child: child))),
        ),
        Positioned(
          top: kDefaultPadding / 2,
          right: kDefaultPadding / 2,
          child: badge,
        ),
      ],
    );

    final VoidCallback? onUnlock = this.onUnlock;
    if (onUnlock == null) return preview;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onUnlock,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: kMinTapTarget, minHeight: kMinTapTarget),
          child: preview,
        ),
      ),
    );
  }
}
