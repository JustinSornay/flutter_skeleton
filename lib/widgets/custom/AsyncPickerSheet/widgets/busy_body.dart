// busy_body.dart
//
// _BusyBody — the caller's picker body of AsyncPickerSheet. While a submit
// runs it absorbs taps and is covered by a translucent overlay with the
// skeleton Loader, announced as a live region.

part of "../index.dart";

final class _BusyBody extends StatelessWidget {
  final bool busy;
  final Widget child;

  const _BusyBody({
    required this.busy,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        AbsorbPointer(absorbing: busy, child: child),
        if (busy)
          ColoredBox(
            color: cs.surfaceContainerLow.withValues(alpha: 0.6),
            child: Center(
              child: Semantics(
                liveRegion: true,
                container: true,
                child: const Loader(size: 24),
              ),
            ),
          ),
      ],
    );
  }
}
