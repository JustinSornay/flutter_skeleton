// lock_badge.dart
//
// Private lock badge of FeatureGate: a dense PillBadge with a lock icon,
// cs.onPrimary on cs.primary (the same pill as CollapsedGateGroup's rows).
// Purely decorative: it is never a tap target of its own.

part of "../index.dart";

final class _LockBadge extends StatelessWidget {
  /// Resolved badge text (host value or the default key).
  final String label;

  const _LockBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return PillBadge(
      label: label,
      icon: Icons.lock_outline_rounded,
      dense: true,
      color: cs.onPrimary,
      backgroundColor: cs.primary,
    );
  }
}
