// navigation_bar.dart
//
// _WizardNavigationBar — bottom bar of PolygonWizardSheet above a
// cs.outlineVariant rule: Back (hidden on the first step, disabled while
// locked) and the Next / Submit filled button (arrow or check icon; a
// _BusyIndicator while onSubmit runs, the label kept as its accessible name;
// the label again, disabled, after success). Both have 48 dp targets; long
// labels are ellipsized instead of overflowing.

part of "../index.dart";

/// Corner radius of the Next / Submit button.
const double _kButtonRadius = 12;

/// Diameter of the busy indicator inside the button.
const double _kButtonLoaderSize = 18;

final class _WizardNavigationBar extends StatelessWidget {
  final _PolygonWizardSheetState state;

  const _WizardNavigationBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding * 2,
            vertical: kDefaultPadding * 1.5,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              if (state.step > 0)
                Flexible(child: _back(cs))
              else
                const SizedBox.shrink(),
              const SizedBox(width: kDefaultPadding),
              Flexible(child: _next()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _back(ColorScheme cs) {
    return TextButton.icon(
      onPressed: state.busy ? null : state.back,
      style: TextButton.styleFrom(
        foregroundColor: cs.onSurfaceVariant,
        minimumSize: const Size.square(kMinTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 1.5),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
      label: Text(
        "custom.polygon_wizard_sheet.back".tr(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _next() {
    final bool last = state.isLastStep;
    final String label = last
        ? state.widget.submitLabel ?? "custom.polygon_wizard_sheet.submit".tr()
        : "custom.polygon_wizard_sheet.next".tr();
    return FilledButton(
      onPressed: state.canGoNext ? state.next : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size.square(kMinTapTarget),
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding * 3,
          vertical: kDefaultPadding * 1.5,
        ),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kButtonRadius),
        ),
      ),
      child: state.submitting
          ? Semantics(
              label: label,
              child: const ExcludeSemantics(
                child: _BusyIndicator(size: _kButtonLoaderSize),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: kDefaultPadding * 0.75),
                Icon(
                  last ? Icons.check_rounded : Icons.arrow_forward_ios_rounded,
                  size: 14,
                ),
              ],
            ),
    );
  }
}
