// locate_row.dart
//
// _LocateRow — the "my location" action: a full-width row at least
// kMinTapTarget tall, announced as one button, with its own transparent
// Material so its ink shows above any coloured host background. While busy it
// ignores taps, is announced as disabled and shows a Loader; when the platform
// asks to reduce motion (the Loader spins forever) a static muted hourglass
// carrying the Loader's `common.loading` label replaces it.

part of "../index.dart";

final class _LocateRow extends StatelessWidget {
  /// True while the current-location call runs.
  final bool busy;

  /// Starts the current-location call.
  final VoidCallback onTap;

  const _LocateRow({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: !busy,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: busy ? null : onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kMinTapTarget),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: _kSideInset),
                child: Row(
                  children: <Widget>[
                    _leading(context, cs),
                    const SizedBox(width: kDefaultPadding),
                    Flexible(
                      child: Text(
                        "custom.location_bar.my_location".tr(),
                        style: theme.textTheme.labelLarge?.copyWith(color: cs.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Idle: the primary locate icon. Busy: a Loader, or under reduced motion a
  /// static hourglass with the same label as the Loader.
  Widget _leading(BuildContext context, ColorScheme cs) {
    if (!busy) return Icon(Icons.my_location_rounded, size: 16, color: cs.primary);
    if (!MediaQuery.disableAnimationsOf(context)) return const Loader(size: 16);
    return Icon(
      Icons.hourglass_top_rounded,
      size: 16,
      color: cs.onSurfaceVariant,
      semanticLabel: "common.loading".tr(),
    );
  }
}
