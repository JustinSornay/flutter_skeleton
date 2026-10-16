// polygon_step.dart
//
// _PolygonStep — the polygon step of PolygonWizardSheet: the suggestion
// rows, the centred step header, undo / reset buttons (48 dp targets,
// disabled while the polygon is empty or the sheet is locked) and the
// crossing-edge hint, above the full-width _MapArea that fills the rest of
// the step (locked with the sheet). On a short sheet the map keeps
// _kMinMapHeight, or half the step when the step is shorter than twice
// that: the tools and the hint stay pinned above it, and the rows and the
// header scroll, anchored at the header (on a tiny step the tools scroll
// too, anchored at the hint).

part of "../index.dart";

/// Corner radius of the undo / reset buttons.
const double _kToolRadius = 8;

/// Height the map keeps on a short sheet (unless the step is shorter than
/// twice this); the rows and the header above it scroll instead.
const double _kMinMapHeight = kDefaultPadding * 20;

final class _PolygonStep extends StatelessWidget {
  final _PolygonWizardSheetState state;
  final PolygonWizardStep step;

  const _PolygonStep({required this.state, required this.step});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Everything above the map takes its natural height but leaves the
        // map _kMinMapHeight, or half a step shorter than twice that.
        final double topMaxHeight = math.max(
          constraints.maxHeight - _kMinMapHeight,
          constraints.maxHeight / 2,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: topMaxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Gets the room the tools leave. Both scroll views are
                  // anchored at the map: the rows give way before the
                  // header, and on a tiny step the tools before the hint.
                  Flexible(
                    child: SingleChildScrollView(reverse: true, child: _top()),
                  ),
                  // The tools and the hint change while drawing: pinned;
                  // they scroll only when they alone exceed the room.
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: topMaxHeight),
                    child: SingleChildScrollView(
                      reverse: true,
                      child: _pinned(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _map()),
          ],
        );
      },
    );
  }

  /// Suggestion rows and header.
  Widget _top() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kDefaultPadding * 2,
        kDefaultPadding * 2,
        kDefaultPadding * 2,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SuggestionsBar(state: state),
          _StepHeader(step: step, centered: true),
        ],
      ),
    );
  }

  /// Undo / reset and the crossing-edge hint.
  Widget _pinned() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kDefaultPadding * 2,
        kDefaultPadding,
        kDefaultPadding * 2,
        kDefaultPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _tools(),
          if (state.edgesCross)
            _InlineError(
              text: "custom.polygon_wizard_sheet.crossing_edges".tr(),
              padding: const EdgeInsets.only(top: kDefaultPadding / 2),
            ),
        ],
      ),
    );
  }

  Widget _map() {
    final PolygonWizardSheet widget = state.widget;
    return _MapArea(
      controller: state.polygon,
      shapeValid: state.shapeValid,
      locked: state.busy,
      tileLayer: widget.tileLayer,
      initialCenter: widget.initialCenter,
      initialZoom: widget.initialZoom,
      attribution: widget.attribution,
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
          onPressed: enabled ? state.undoVertex : null,
        ),
        _tool(
          icon: Icons.refresh,
          label: "custom.polygon_wizard_sheet.reset".tr(),
          onPressed: enabled ? state.resetPolygon : null,
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
