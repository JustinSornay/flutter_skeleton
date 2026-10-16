// view.dart
//
// _ViewMixin — widget tree of EmailVerificationPrompt: decorative icon, title,
// body with the address, the live-region error line, the "I've verified"
// button, the resend row and the optional close button, in one stretched
// column.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, _EmailVerificationPromptState state) {
    final EmailVerificationPrompt widget = state.widget;
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? errorKey = switch (state.check) {
      LoadError<void>(:final String? message) => message,
      Idle<void>() || Loading<void>() || Loaded<void>() => null,
    };
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding * 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ExcludeSemantics(
            child: Icon(Icons.mark_email_unread_outlined, size: 40, color: cs.primary),
          ),
          const SizedBox(height: kDefaultPadding * 2),
          Semantics(
            header: true,
            child: Text(
              "custom.email_verification_prompt.title".tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: kDefaultPadding),
          Text(
            "custom.email_verification_prompt.body".tr(
              namedArgs: <String, String>{"email": widget.email},
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (errorKey != null) ...<Widget>[
            const SizedBox(height: kDefaultPadding * 2),
            _errorLine(context, errorKey.tr()),
          ],
          const SizedBox(height: kDefaultPadding * 3),
          _confirmButton(state),
          const SizedBox(height: kDefaultPadding),
          _ResendRow(
            cooldownSeconds: state.cooldownSeconds,
            onResend: state.canResend ? state.resend : null,
          ),
          if (widget.onDismiss != null) _closeButton(widget.onDismiss),
        ],
      ),
    );
  }

  Widget _errorLine(BuildContext context, String message) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _confirmButton(_EmailVerificationPromptState state) {
    return FilledButton(
      onPressed: state.canConfirm ? state.confirm : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(kMinTapTarget),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: state.check.isLoading
          ? const Loader(size: 20)
          : Text("custom.email_verification_prompt.confirm".tr()),
    );
  }

  Widget _closeButton(VoidCallback? onDismiss) {
    return TextButton(
      onPressed: onDismiss,
      style: TextButton.styleFrom(
        minimumSize: const Size(kMinTapTarget, kMinTapTarget),
      ),
      child: Text("custom.email_verification_prompt.close".tr()),
    );
  }
}
