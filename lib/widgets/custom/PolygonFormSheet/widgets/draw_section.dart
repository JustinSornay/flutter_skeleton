// draw_section.dart
//
// _DrawSection — the drawing block of PolygonFormSheet: the section label
// with undo / reset buttons (shown once a vertex exists, 48 dp targets) above
// the _MapArea. The row keeps its height, so the map does not jump on the
// first vertex; the buttons take their natural width up to 75 % of the row
// and stack (then ellipsize) when long labels or large text do not fit.
// Undo and reset go through the MapPolygonEditorController; shapeValid and
// the optional attribution are passed on to the map.

part of "../index.dart";

/// Corner radius of the undo / reset buttons.
const double _kToolRadius = 8;

/// Largest share of the row width the undo / reset buttons may take.
const double _kToolsMaxShare = 0.75;

final class _DrawSection extends StatelessWidget {
  final String label;
  final MapPolygonEditorController controller;
  final bool shapeValid;
  final TileLayer tileLayer;
  final LatLng initialCenter;
  final double initialZoom;
  final Widget? attribution;

  const _DrawSection({
    required this.label,
    required this.controller,
    required this.shapeValid,
    required this.tileLayer,
    required this.initialCenter,
    required this.initialZoom,
    required this.attribution,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) => Row(
              children: <Widget>[
                Expanded(child: _SectionLabel(text: label)),
                if (!controller.isEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * _kToolsMaxShare,
                    ),
                    child: _tools(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: kDefaultPadding),
        _MapArea(
          controller: controller,
          shapeValid: shapeValid,
          tileLayer: tileLayer,
          initialCenter: initialCenter,
          initialZoom: initialZoom,
          attribution: attribution,
        ),
      ],
    );
  }

  /// Undo and reset side by side, stacked when they do not fit.
  Widget _tools() {
    return OverflowBar(
      spacing: kDefaultPadding,
      alignment: MainAxisAlignment.end,
      overflowAlignment: OverflowBarAlignment.end,
      children: <Widget>[
        _tool(
          icon: Icons.undo,
          label: "custom.polygon_form_sheet.undo".tr(),
          onPressed: controller.undo,
        ),
        _tool(
          icon: Icons.refresh,
          label: "custom.polygon_form_sheet.reset".tr(),
          onPressed: controller.reset,
        ),
      ],
    );
  }

  Widget _tool({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
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
