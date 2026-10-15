// index.dart
//
// EmailVerificationPrompt — modal content asking the user to verify their
// email through a link. Sends the email once mounted, locks "Resend" behind a
// countdown, and runs a host-provided check behind "I've verified". Every
// backend call is a callback, so it works with any auth provider. State lives
// in view_model.dart, the tree in view.dart and the resend row in widgets/.
//
// Usage with ModalProvider:
//   final ModalProvider modal = context.read<ModalProvider>();
//   modal.show(AppModal(
//     isVisible: true,
//     onDismiss: modal.dismiss,
//     child: EmailVerificationPrompt(
//       email: maskedEmail,
//       sendEmail: auth.sendVerificationEmail,
//       checkVerified: auth.reloadAndCheckVerified,
//       onVerified: () { modal.dismiss(); /* continue the flow */ },
//       onDismiss: modal.dismiss,
//     ),
//   ));

import "dart:async";

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/utils/load_state.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";

part "view_model.dart";
part "view.dart";
part "widgets/resend_row.dart";

const String _kNotVerifiedKey = "custom.email_verification_prompt.not_verified";
const String _kCheckFailedKey = "custom.email_verification_prompt.check_failed";

/// Prompt asking the user to open the verification link sent to [email].
///
/// Renders, top to bottom, in a stretched column (outer padding
/// `kDefaultPadding * 3`):
/// - a decorative mail icon (`cs.primary`, excluded from semantics);
/// - the title (`titleMedium`, w700, header semantics) and a body naming
///   [email] (`bodyMedium`, `cs.onSurfaceVariant`);
/// - after a failed check, an error line (`cs.error`) announced as a live
///   region;
/// - the "I've verified" filled button, showing a [Loader] while
///   [checkVerified] runs;
/// - a "Didn't receive it?" line with a "Resend" text button, which reads
///   "Resend in N s" during the cooldown;
/// - a "Close" text button when [onDismiss] is set.
///
/// Behaviour:
/// - [sendEmail] is called once, right after the first frame (never during
///   build, so it may notify listeners synchronously). "Resend" is disabled
///   until that send ends. When it completes, "Resend" is locked for
///   [resendCooldown]. When it throws, the error is swallowed, no cooldown
///   starts and "Resend" stays available. "Resend" is disabled while a send
///   runs, so sends never overlap.
/// - "I've verified" calls [checkVerified] and is disabled while it runs. A
///   new attempt clears the previous error. `false` shows a "not verified yet,
///   check your spam folder" error, a throw shows a generic "check failed"
///   error, and `true` calls [onVerified] once. Both buttons then stay
///   disabled: the host dismisses the prompt in [onVerified].
/// - Nothing is called back once the prompt is unmounted; the cooldown timer
///   is cancelled on dispose.
///
/// Content only: no card, no drag handle, no route handling. Host it in
/// `ModalProvider.show(AppModal(...))` (recommended) or
/// `showModalBottomSheet(showDragHandle: true, …)`; the widget never opens or
/// closes routes. Needs a [Material] ancestor (both hosts provide one) but no
/// [Overlay]. Every button is at least [kMinTapTarget] tall.
final class EmailVerificationPrompt extends StatefulWidget {
  /// Address shown in the body exactly as given. Mask it first if needed.
  final String email;

  /// Sends (or re-sends) the verification email. Called once after the first
  /// frame and on every tap on "Resend". A throw is swallowed (for example when the backend
  /// rate-limits because a mail was just sent) and starts no cooldown.
  final Future<void> Function() sendEmail;

  /// Tells whether the address is verified now (for example: reload the
  /// signed-in user, refresh its token, then read its verified flag). Any
  /// sync the app needs after verification can run here before returning
  /// `true`.
  final Future<bool> Function() checkVerified;

  /// Called once after [checkVerified] returned `true`. The host dismisses
  /// the prompt and continues its flow here.
  final VoidCallback onVerified;

  /// When set, shows a "Close" button that calls it. Gives an accessible way
  /// out, since a scrim tap has no semantics.
  final VoidCallback? onDismiss;

  /// How long "Resend" stays locked after a successful send, counted in
  /// whole seconds (rounded up). [Duration.zero] disables the cooldown. A new
  /// value applies from the next send.
  final Duration resendCooldown;

  const EmailVerificationPrompt({
    super.key,
    required this.email,
    required this.sendEmail,
    required this.checkVerified,
    required this.onVerified,
    this.onDismiss,
    this.resendCooldown = const Duration(seconds: 60),
  });

  @override
  State<EmailVerificationPrompt> createState() => _EmailVerificationPromptState();
}
