// action_button.dart
//
// Private button of StateMessageView: a FilledButton (primary) or an
// OutlinedButton (secondary), with an optional leading icon, at least
// kMinTapTarget tall. The parent column stretches it to its width.

part of "../index.dart";

final class _ActionButton extends StatelessWidget {
  /// Label, callback and optional icon.
  final StateMessageAction action;

  /// true → FilledButton, false → OutlinedButton.
  final bool filled;

  const _ActionButton({required this.action, required this.filled});

  static const Size _minimumSize = Size(kMinTapTarget, kMinTapTarget);

  @override
  Widget build(BuildContext context) {
    final IconData? icon = action.icon;
    final Widget label = Text(action.label, textAlign: TextAlign.center);

    if (filled) {
      final ButtonStyle style = FilledButton.styleFrom(minimumSize: _minimumSize);
      return icon == null
          ? FilledButton(onPressed: action.onPressed, style: style, child: label)
          : FilledButton.icon(
              onPressed: action.onPressed,
              style: style,
              icon: Icon(icon, size: 18),
              label: label,
            );
    }

    final ButtonStyle style = OutlinedButton.styleFrom(minimumSize: _minimumSize);
    return icon == null
        ? OutlinedButton(onPressed: action.onPressed, style: style, child: label)
        : OutlinedButton.icon(
            onPressed: action.onPressed,
            style: style,
            icon: Icon(icon, size: 18),
            label: label,
          );
  }
}
