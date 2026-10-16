// action_bar.dart
//
// _ActionBar — the bottom bar of PolygonEditorPanel: Reset and Undo text
// buttons (cs.onSurface, wrapping on narrow widths) on the left and the Save
// button on the right, replaced by a Loader while the save runs. The Save
// slot takes at most half of the bar (a longer label wraps), so Reset / Undo
// always keep the other half. cs.surface background with a cs.outlineVariant
// top border; 48 dp targets. A null callback disables its button.

part of "../index.dart";

/// Corner radius of the bar's buttons.
const double _kButtonRadius = 8;

/// Icon size of the Reset / Undo buttons.
const double _kToolIconSize = 16;

/// Diameter of the Loader shown while saving.
const double _kLoaderSize = 18;

/// Width of the Loader slot, close to the Save button's.
const double _kLoaderSlotWidth = kDefaultPadding * 10;

/// Largest share of the bar's width the Save slot may take.
const double _kSaveMaxWidthFactor = 0.5;

final class _ActionBar extends StatelessWidget {
  final LoadState<void> saveState;
  final String saveLabel;
  final VoidCallback? onReset;
  final VoidCallback? onUndo;
  final VoidCallback? onSave;

  const _ActionBar({
    required this.saveState,
    required this.saveLabel,
    required this.onReset,
    required this.onUndo,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Row(
              children: <Widget>[
                Expanded(
                  child: Wrap(
                    spacing: kDefaultPadding,
                    children: <Widget>[
                      _tool(
                        cs: cs,
                        icon: Icons.delete_outline,
                        label: "custom.polygon_editor_panel.reset".tr(),
                        onPressed: onReset,
                      ),
                      _tool(
                        cs: cs,
                        icon: Icons.undo,
                        label: "custom.polygon_editor_panel.undo".tr(),
                        onPressed: onUndo,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: kDefaultPadding),
                // Laid out before the Wrap: capped so a long label or large
                // text cannot squeeze Reset / Undo out of the bar.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * _kSaveMaxWidthFactor,
                  ),
                  child: _saveSlot(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tool({
    required ColorScheme cs,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: _kToolIconSize),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: cs.onSurface,
        minimumSize: const Size.square(kMinTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kButtonRadius),
        ),
      ),
    );
  }

  Widget _saveSlot() {
    return switch (saveState) {
      Loading<void>() => const SizedBox(
        width: _kLoaderSlotWidth,
        height: kMinTapTarget,
        child: Center(child: Loader(size: _kLoaderSize)),
      ),
      Idle<void>() || Loaded<void>() || LoadError<void>() => FilledButton(
        onPressed: onSave,
        style: FilledButton.styleFrom(
          minimumSize: const Size.square(kMinTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding * 2,
            vertical: kDefaultPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kButtonRadius),
          ),
        ),
        // Wraps (centred) rather than cut when it is wider than the cap.
        child: Text(saveLabel, textAlign: TextAlign.center),
      ),
    };
  }
}
