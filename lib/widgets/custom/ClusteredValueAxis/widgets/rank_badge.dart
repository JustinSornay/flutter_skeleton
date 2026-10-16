// rank_badge.dart
//
// _RankBadge — the 22 dp leading badge of a popover row: a member's rank in
// a cs.primary-bordered circle (filled cs.primary with a cs.tertiary border
// for the best value), or the reference icon in a cs.inverseSurface square.

part of "../index.dart";

final class _RankBadge extends StatelessWidget {
  static const double _size = 22;

  /// Rank by value (1 = highest); null for the reference badge.
  final int? rank;

  /// Reference icon; null for a rank badge.
  final IconData? icon;

  /// The member holds the best value.
  final bool best;

  const _RankBadge.rank(int this.rank, {required this.best}) : icon = null;

  const _RankBadge.reference(IconData this.icon) : rank = null, best = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    if (icon case final IconData glyph) {
      return SizedBox.square(
        dimension: _size,
        child: DecoratedBox(
          decoration: BoxDecoration(color: cs.inverseSurface, borderRadius: BorderRadius.circular(4)),
          child: Icon(glyph, size: 12, color: cs.onInverseSurface),
        ),
      );
    }
    return SizedBox.square(
      dimension: _size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: best ? cs.primary : cs.surface,
          shape: BoxShape.circle,
          border: Border.all(color: best ? cs.tertiary : cs.primary, width: 2),
        ),
        child: Center(
          child: Text(
            "$rank",
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: best ? cs.onPrimary : cs.primary,
            ),
          ),
        ),
      ),
    );
  }
}
