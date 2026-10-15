// polygon_step.dart
//
// _PolygonStep — the polygon step of PolygonWizardSheet: the suggestion
// rows, the centred step header, undo / reset buttons (48 dp targets,
// disabled while the polygon is empty or the sheet is locked) and the
// crossing-edge hint, above the full-width _MapArea that fills the rest of
// the step (locked with the sheet).

part of "../index.dart";

/// Corner radius of the undo / reset buttons.
const double _kToolRadius = 8;

final class _PolygonStep extends StatelessWidget {
  final _PolygonWizardSheetState state;
  final PolygonWizardStep step;

  const _PolygonStep({required this.state, required this.step});

  @override
  Widget build(BuildContext context) {
    final PolygonWizardSheet widget = state.widget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            kDefaultPadding * 2,
            kDefaultPadding * 2,
            kDefaultPadding * 2,
            kDefaultPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _SuggestionsBar(state: state),
              _StepHeader(step: step, centered: true),
              const SizedBox(height: kDefaultPadding),
              _tools(),
              if (state.edgesCross)
                _InlineError(
                  text: "custom.polygon_wizard_sheet.crossing_edges".tr(),
                  padding: const EdgeInsets.only(top: kDefaultPadding / 2),
                ),
            ],
          ),
        ),
        Expanded(
          child: _MapArea(
            controller: state.polygon,
            shapeValid: state.shapeValid,
            locked: state.busy,
            tileLayer: widget.tileLayer,
            initialCenter: widget.initialCenter,
            initialZoom: widget.initialZoom,
            attribution: widget.attribution,
          ),
        ),
      ],
    );
  }

  /// Undo and reset, end-aligned; both disabled while there is no vertex
  /// and while the sheet is locked.
  Widget _tools() {
    final bool enabled = !state.polygon.isEmpty && !state.busy;
    return OverflowBar(
      spacing: kDefaultPadding,
      alignment: MainAxisAlignment.end,
      overflowAlignment: OverflowBarAlignment.end,
      children: <Widget>[
        _tool(
          icon: Icons.undo,
          label: "custom.polygon_wizard_sheet.undo".tr(),
          onPressed: enabled ? state.polygon.undo : null,
        ),
        _tool(
          icon: Icons.refresh,
          label: "custom.polygon_wizard_sheet.reset".tr(),
          onPressed: enabled ? state.polygon.reset : null,
        ),
      ],
    );
  }

  Widget _tool({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: TextButton.styleFrom(
        minimumSize: const Size.square(kMinTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kToolRadius),
        ),
      ),
    );
  }
}
