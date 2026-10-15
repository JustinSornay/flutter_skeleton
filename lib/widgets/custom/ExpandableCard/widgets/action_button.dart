// action_button.dart
//
// Private compact icon + label button of the ExpandableCard action row: a
// 28 dp TextButton (radius 8) whose tap target is padded to 48 dp. Neutral:
// cs.surfaceContainerLowest fill, cs.outlineVariant border,
// cs.onSurfaceVariant content. Destructive: cs.error fill, cs.onError
// content. Null onPressed renders it disabled.

part of "../index.dart";

/// Visual height of an action button (the tap target stays 48 dp).
const double _actionHeight = kDefaultPadding * 3.5;

/// Action corner radius.
const double _actionRadius = 8;

/// Action glyph size.
const double _actionIconSize = kDefaultPadding * 1.5;

/// Action label size.
const double _actionLabelSize = 10;

/// Opacity of disabled content and fill (Material 3 values).
const double _disabledContentAlpha = 0.38;
const double _disabledFillAlpha = 0.12;

final class _ActionButton extends StatelessWidget {
  final ExpandableCardAction action;

  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextStyle base = Theme.of(context).textTheme.labelSmall ?? const TextStyle();
    final bool destructive = action.destructive;

    return TextButton.icon(
      onPressed: action.onPressed,
      icon: Icon(action.icon, size: _actionIconSize),
      label: Text(action.label),
      style: TextButton.styleFrom(
        foregroundColor: destructive ? cs.onError : cs.onSurfaceVariant,
        backgroundColor: destructive ? cs.error : cs.surfaceContainerLowest,
        disabledForegroundColor: cs.onSurface.withValues(alpha: _disabledContentAlpha),
        disabledBackgroundColor: destructive
            ? cs.onSurface.withValues(alpha: _disabledFillAlpha)
            : cs.surfaceContainerLowest,
        iconSize: _actionIconSize,
        textStyle: base.copyWith(fontSize: _actionLabelSize, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
        minimumSize: const Size(0, _actionHeight),
        visualDensity: VisualDensity.standard,
        // Padded: the hit area grows to 48 x 48 around the 28 dp pill.
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_actionRadius),
          side: destructive ? BorderSide.none : BorderSide(color: cs.outlineVariant),
        ),
      ),
    );
  }
}
