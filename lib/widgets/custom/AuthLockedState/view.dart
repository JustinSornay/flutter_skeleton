// view.dart
//
// Layout of AuthLockedState: a neutral StateMessageView with the icon, the
// title, the subtitle and one filled sign-in action. The async handler lives
// in index.dart.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, AuthLockedState widget) {
    return StateMessageView(
      icon: widget.icon,
      title: widget.title,
      message: widget.subtitle,
      tone: StatusTone.neutral,
      primaryAction: StateMessageAction(
        label: widget.actionLabel ?? "custom.auth_locked_state.sign_in".tr(),
        icon: Icons.login_rounded,
        onPressed: () => unawaited(widget._handleSignIn(context)),
      ),
    );
  }
}
