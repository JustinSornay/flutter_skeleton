// state_message.dart
//
// _StateMessage — the centred message of ValueMatrix when there is no table:
// the error state (cs.error custom.value_matrix.load_error, announced as a
// live region, plus a kMinTapTarget custom.value_matrix.retry button) or the
// empty state (cs.onSurfaceVariant custom.value_matrix.empty).
// Kept as a light inline message rather than composing StateMessageView: the
// matrix often sits in a small panel, where that full-area badge + title +
// filled button would be heavier than the table, and the widget has no
// dependency on other custom widgets besides Loader.

part of "../index.dart";

final class _StateMessage extends StatelessWidget {
  /// Retry of the error state; null for the empty state.
  final VoidCallback? onRetry;

  const _StateMessage.error({required VoidCallback this.onRetry});

  const _StateMessage.empty() : onRetry = null;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final VoidCallback? retry = onRetry;

    if (retry == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding * 4),
          child: Text(
            "custom.value_matrix.empty".tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding * 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                "custom.value_matrix.load_error".tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.error),
              ),
            ),
            const SizedBox(height: kDefaultPadding),
            TextButton(
              onPressed: retry,
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
                minimumSize: const Size(kMinTapTarget, kMinTapTarget),
              ),
              child: Text("custom.value_matrix.retry".tr()),
            ),
          ],
        ),
      ),
    );
  }
}
