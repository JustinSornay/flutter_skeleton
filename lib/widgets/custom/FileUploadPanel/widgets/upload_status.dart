// upload_status.dart
//
// _UploadStatus — status area of FileUploadPanel, an exhaustive switch on the
// upload LoadState: nothing when idle, the progress bar and "Uploading…" while
// loading, then a success or danger _StatusLine (tone icon + text; the error
// carries an i18n key, translated here on every build). Every
// non-idle state is announced as a live region. The indeterminate bar is
// omitted under reduced motion (it repeats forever).

part of "../index.dart";

final class _UploadStatus extends StatelessWidget {
  final LoadState<void> state;

  const _UploadStatus({required this.state});

  @override
  Widget build(BuildContext context) {
    final Widget? content = switch (state) {
      Idle<void>() => null,
      Loading<void>() => const _UploadingIndicator(),
      Loaded<void>() => _StatusLine(
          tone: StatusTone.success,
          text: "custom.file_upload_panel.success".tr(),
        ),
      LoadError<void>(:final String? message) => _StatusLine(
          tone: StatusTone.danger,
          text: (message ?? "custom.file_upload_panel.failed").tr(),
        ),
    };
    if (content == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: kDefaultPadding * 2),
        child: content,
      ),
    );
  }
}

final class _UploadingIndicator extends StatelessWidget {
  const _UploadingIndicator();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!reduceMotion) ...<Widget>[
          const LinearProgressIndicator(),
          const SizedBox(height: kDefaultPadding),
        ],
        Text(
          "custom.file_upload_panel.uploading".tr(),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

final class _StatusLine extends StatelessWidget {
  final StatusTone tone;
  final String text;

  const _StatusLine({required this.tone, required this.text});

  @override
  Widget build(BuildContext context) {
    final Color color = StatusTones.colorsOf(context, tone).foreground;
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(tone.icon, size: 18, color: color),
        const SizedBox(width: kDefaultPadding),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}
