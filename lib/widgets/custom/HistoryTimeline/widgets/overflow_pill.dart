// overflow_pill.dart
//
// _OverflowPill — the "+N earlier" pill at the right end of HistoryTimeline: a
// small cs.outlineVariant-bordered stadium with its own stadium ink response,
// centred in a kMinTapTarget hit area (taps around the pill also count),
// announced as a button labelled custom.history_timeline.show_older. Tapping
// it expands the strip.

part of "../index.dart";

final class _OverflowPill extends StatelessWidget {
  /// Number of collapsed entries.
  final int count;

  /// Expands the strip.
  final VoidCallback onTap;

  const _OverflowPill({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      label: "custom.history_timeline.show_older".tr(namedArgs: <String, String>{"count": "$count"}),
      onTap: onTap,
      // The 48 dp target around the pill; the ink stays on the pill itself.
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: kMinTapTarget, minHeight: kMinTapTarget),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  customBorder: const StadiumBorder(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: 2),
                      child: Text(
                        "+$count ${"custom.history_timeline.older".tr()}",
                        maxLines: 1,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
