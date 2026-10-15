// state_message.dart
//
// _StateMessage — body of ScoreListCard when there are no rows: the empty
// text (cs.onSurfaceVariant), or the error row (danger icon + text announced
// as a live region + a kMinTapTarget custom.score_list_card.retry button).

part of "../index.dart";

final class _StateMessage extends StatelessWidget {
  final String text;

  /// Retry of the error state; null for the empty state.
  final VoidCallback? onRetry;

  const _StateMessage.empty({required this.text}) : onRetry = null;

  const _StateMessage.error({required this.text, required VoidCallback this.onRetry});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? style = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final VoidCallback? retry = onRetry;
    if (retry == null) return Text(text, style: style);

    return Row(
      children: <Widget>[
        Icon(
          StatusTone.danger.icon,
          size: 16,
          color: StatusTones.colorsOf(context, StatusTone.danger).foreground,
        ),
        const SizedBox(width: kDefaultPadding),
        Expanded(
          child: Semantics(liveRegion: true, child: Text(text, style: style)),
        ),
        const SizedBox(width: kDefaultPadding),
        TextButton(
          onPressed: retry,
          style: TextButton.styleFrom(minimumSize: const Size(kMinTapTarget, kMinTapTarget)),
          child: Text("custom.score_list_card.retry".tr()),
        ),
      ],
    );
  }
}
