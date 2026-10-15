// resend_row.dart
//
// _ResendRow — "Didn't receive it?" line of EmailVerificationPrompt with the
// "Resend" text button, which reads "Resend in N s" while the cooldown runs.
// Centred Wrap so it reflows on narrow cards; the button keeps a 48 dp target.

part of "../index.dart";

final class _ResendRow extends StatelessWidget {
  /// Seconds left in the cooldown; 0 shows the plain "Resend" label.
  final int cooldownSeconds;

  /// Null disables the button (send running, cooldown, or already verified).
  final VoidCallback? onResend;

  const _ResendRow({required this.cooldownSeconds, required this.onResend});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? small = theme.textTheme.bodySmall;
    final String action = cooldownSeconds > 0
        ? "custom.email_verification_prompt.resend_countdown".tr(
            namedArgs: <String, String>{"seconds": "$cooldownSeconds"},
          )
        : "custom.email_verification_prompt.resend_action".tr();
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          "custom.email_verification_prompt.resend_label".tr(),
          style: small?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        TextButton(
          onPressed: onResend,
          style: TextButton.styleFrom(
            minimumSize: const Size(kMinTapTarget, kMinTapTarget),
            textStyle: small?.copyWith(fontWeight: FontWeight.w600),
          ),
          child: Text(action),
        ),
      ],
    );
  }
}
