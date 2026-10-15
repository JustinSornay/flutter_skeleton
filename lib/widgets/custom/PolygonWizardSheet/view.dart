// view.dart
//
// _ViewMixin — widget tree of PolygonWizardSheet: the step indicator, the
// current step's body in an AnimatedSwitcher (one widgets/ part per step
// kind), the inline submit error and the Back / Next / Submit bar.

part of "index.dart";

/// Cross-fade between step bodies.
const Duration _kStepMotion = Duration(milliseconds: 220);

mixin _ViewMixin {
  Widget render(BuildContext context, _PolygonWizardSheetState state) {
    final PolygonWizardSheet widget = state.widget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: kDefaultPadding),
        _StepIndicator(steps: widget.steps, current: state.step),
        const SizedBox(height: kDefaultPadding),
        Expanded(
          child: AnimatedSwitcher(
            duration: resolveMotion(context, _kStepMotion),
            layoutBuilder: _expandedLayout,
            child: KeyedSubtree(
              key: ValueKey<int>(state.step),
              child: _body(state),
            ),
          ),
        ),
        if (state.submission.hasError)
          _InlineError(
            text:
                widget.submitErrorText ??
                "custom.polygon_wizard_sheet.submit_error".tr(),
            padding: const EdgeInsets.fromLTRB(
              kDefaultPadding * 2,
              kDefaultPadding,
              kDefaultPadding * 2,
              0,
            ),
          ),
        _WizardNavigationBar(state: state),
      ],
    );
  }

  /// Body of the current step.
  Widget _body(_PolygonWizardSheetState state) {
    final PolygonWizardStep step = state.currentStep;
    return switch (step.kind) {
      PolygonWizardStepKind.name => _NameStep(state: state, step: step),
      PolygonWizardStepKind.polygon => _PolygonStep(state: state, step: step),
      PolygonWizardStepKind.selection => _SelectionStep(
        state: state,
        step: step,
      ),
      PolygonWizardStepKind.summary => _SummaryStep(state: state, step: step),
    };
  }
}

/// Stacks the outgoing and incoming bodies, each filling the area.
Widget _expandedLayout(Widget? current, List<Widget> previous) {
  return Stack(fit: StackFit.expand, children: <Widget>[...previous, ?current]);
}
