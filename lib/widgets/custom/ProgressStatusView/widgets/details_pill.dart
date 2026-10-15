// details_pill.dart
//
// Private pill of ProgressStatusView: the host's short context facts joined
// by " · " on a rounded cs.surfaceContainer background with a
// cs.outlineVariant border. Long text wraps and stays centred.

part of "../index.dart";

final class _DetailsPill extends StatelessWidget {
  /// Pre-formatted, non-empty facts; never an empty list (the view drops
  /// empty entries and hides the pill when none remain).
  final List<String> details;

  const _DetailsPill({required this.details});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding * 1.5,
        vertical: kDefaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        details.join(" · "),
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
