// lock_card.dart
//
// Private lock card of FeatureGate (GateDisplayMode.lockCard): a centred
// lock icon, the locked label and, when onUnlock is set, a 48 dp TextButton.
// The label is excluded from semantics because the gate's node carries it.

part of "../index.dart";

/// Lock icon size.
const double _cardIconSize = 32;

final class _LockCard extends StatelessWidget {
  final String label;

  /// Resolved button text (host value or the default key).
  final String actionLabel;

  final VoidCallback? onUnlock;

  const _LockCard({
    required this.label,
    required this.actionLabel,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final VoidCallback? onUnlock = this.onUnlock;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding * 3,
          vertical: kDefaultPadding * 5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.lock_outline_rounded, size: _cardIconSize, color: cs.onSurfaceVariant),
            const SizedBox(height: kDefaultPadding * 1.5),
            ExcludeSemantics(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            if (onUnlock != null) ...<Widget>[
              const SizedBox(height: kDefaultPadding * 2),
              TextButton(
                onPressed: onUnlock,
                style: TextButton.styleFrom(
                  foregroundColor: cs.primary,
                  minimumSize: const Size(kMinTapTarget, kMinTapTarget),
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding * 1.5,
                    vertical: kDefaultPadding / 2,
                  ),
                  textStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
