// view.dart
//
// Render for PolygonEditorPanel: the MapPolygonEditor filling the space
// above the action bar (widgets/action_bar.dart), with the hint pill
// (widgets/hint_pill.dart) over the map while the polygon is empty.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, _PolygonEditorPanelState state) {
    final PolygonEditorPanel widget = state.widget;
    final MapPolygonEditorController polygon = state.polygon;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: MapPolygonEditor(
                  controller: polygon,
                  tileLayer: widget.tileLayer,
                  initialCenter: widget.initialCenter,
                  initialZoom: widget.initialZoom,
                  minZoom: _kMinZoom,
                  maxZoom: _kMaxZoom,
                  attribution: widget.attribution,
                ),
              ),
              if (polygon.isEmpty)
                Positioned(
                  top: kDefaultPadding * 2,
                  left: kDefaultPadding * 2,
                  right: kDefaultPadding * 2,
                  // Taps under the hint still reach the map.
                  child: IgnorePointer(
                    child: Center(
                      child: _HintPill(
                        text:
                            widget.hint ??
                            "custom.polygon_editor_panel.hint".tr(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _ActionBar(
          saveState: state.saveState,
          saveLabel:
              widget.saveLabel ?? "custom.polygon_editor_panel.save".tr(),
          onReset: polygon.isEmpty ? null : polygon.reset,
          onUndo: polygon.isEmpty ? null : polygon.undo,
          onSave: state.canSave ? state.save : null,
        ),
      ],
    );
  }
}
