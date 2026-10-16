// view.dart
//
// Tree of ConfirmCard: padded column with the header title, the optional
// message and an end-aligned button row.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, ConfirmCard widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final String? message = widget.message;
    const Size minTarget = Size(kMinTapTarget, kMinTapTarget);

    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding * 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(widget.title, style: text.titleLarge?.copyWith(color: cs.onSurface)),
          ),
          if (message != null && message.isNotEmpty) ...<Widget>[
            const SizedBox(height: kDefaultPadding * 2),
            Text(message, style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ],
          const SizedBox(height: kDefaultPadding * 3),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: kDefaultPadding,
              runSpacing: kDefaultPadding,
              children: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(minimumSize: minTarget),
                  onPressed: widget.onCancel,
                  child: Text(widget.cancelLabel),
                ),
                FilledButton(
                  style: widget.destructive
                      ? FilledButton.styleFrom(
                          minimumSize: minTarget,
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError,
                        )
                      : FilledButton.styleFrom(minimumSize: minTarget),
                  onPressed: widget.onConfirm,
                  child: Text(widget.confirmLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
