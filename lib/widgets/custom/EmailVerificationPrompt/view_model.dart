// view_model.dart
//
// _EmailVerificationPromptState — send and check lifecycle of
// EmailVerificationPrompt. The check is a LoadState<void>: Idle, Loading while
// checkVerified runs, Loaded once verified, LoadError(i18n key) after a
// "not verified" answer or a failure. The first send runs in a post-frame
// callback, never during build. The resend cooldown is a one-second periodic
// Timer cancelled on dispose. Every update after an await is guarded with
// `mounted`.

part of "index.dart";

final class _EmailVerificationPromptState extends State<EmailVerificationPrompt>
    with _ViewMixin {
  /// Verification check state, rendered with an exhaustive switch.
  LoadState<void> check = const Idle<void>();

  /// Seconds left before "Resend" unlocks; 0 when no cooldown runs.
  int cooldownSeconds = 0;

  /// True while [EmailVerificationPrompt.sendEmail] runs.
  bool sending = false;

  Timer? _cooldownTimer;

  /// True when "I've verified" is enabled.
  bool get canConfirm => check is! Loading<void> && check is! Loaded<void>;

  /// True when "Resend" is enabled.
  bool get canResend => !sending && cooldownSeconds == 0 && check is! Loaded<void>;

  @override
  void initState() {
    super.initState();
    sending = true;
    // Deferred past the first frame: sendEmail is host code that may notify
    // listeners before its first await, which must not happen during build.
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) unawaited(_send());
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  /// Re-sends the verification email.
  void resend() {
    if (!canResend) return;
    setState(() => sending = true);
    unawaited(_send());
  }

  /// Runs the host check and calls [EmailVerificationPrompt.onVerified] on
  /// success.
  Future<void> confirm() async {
    if (!canConfirm) return;
    setState(() => check = const Loading<void>());
    final LoadState<void> next = await _runCheck();
    if (!mounted) return;
    setState(() => check = next);
    if (next is Loaded<void>) widget.onVerified();
  }

  Future<LoadState<void>> _runCheck() async {
    try {
      final bool verified = await widget.checkVerified();
      return verified ? const Loaded<void>(null) : const LoadError<void>(_kNotVerifiedKey);
    } catch (_) {
      return const LoadError<void>(_kCheckFailedKey);
    }
  }

  Future<void> _send() async {
    bool sent = false;
    try {
      await widget.sendEmail();
      sent = true;
    } catch (_) {
      // Swallowed: the backend may refuse a send right after another one.
      // No cooldown starts, so "Resend" stays available.
    }
    if (!mounted) return;
    setState(() {
      sending = false;
      if (sent) cooldownSeconds = _secondsOf(widget.resendCooldown);
    });
    if (cooldownSeconds > 0) _startTimer();
  }

  void _startTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }
    setState(() => cooldownSeconds -= 1);
    if (cooldownSeconds <= 0) timer.cancel();
  }

  static int _secondsOf(Duration duration) {
    if (duration <= Duration.zero) return 0;
    return (duration.inMilliseconds + 999) ~/ 1000;
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}
