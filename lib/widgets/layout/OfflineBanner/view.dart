// view.dart
//
// _ViewMixin — full UI implementation for OfflineBanner.
//
// Uses an AnimatedSlide combined with an AnimatedOpacity so the banner
// smoothly enters and exits (kMotionShort, easeOutCubic). Both durations
// collapse to zero when the platform requests reduced motion.
//
// Accessibility: Semantics(liveRegion: true) makes screen readers announce
// the offline state as soon as it becomes visible.

part of "index.dart";

mixin _ViewMixin {
  /// Renders the animated offline banner. Returns an empty box when online.
  Widget render(BuildContext context, OfflineBanner widget) {
    final bool isOffline = context.watch<ConnectivityProvider>().isOffline;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Duration duration = resolveMotion(context, kMotionShort);

    return AnimatedSlide(
      offset: isOffline ? Offset.zero : const Offset(0, -1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: isOffline ? 1.0 : 0.0,
        duration: duration,
        child: isOffline
            ? Semantics(
                liveRegion: true,
                label: "offline.banner".tr(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding * 2,
                    vertical: kDefaultPadding * 1.5,
                  ),
                  color: cs.error,
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.cloud_off, color: cs.onError, size: 18),
                      const SizedBox(width: kDefaultPadding),
                      Expanded(
                        child: ExcludeSemantics(
                          child: Text(
                            "offline.banner".tr(),
                            style: TextStyle(
                              color: cs.onError,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
