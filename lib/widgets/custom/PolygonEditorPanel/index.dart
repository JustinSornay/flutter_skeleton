// index.dart
//
// PolygonEditorPanel — a ready-to-use panel for drawing one area on a map
// and saving it: a MapPolygonEditor (tap to add, snapping, edge insert,
// draggable vertices) with a hint pill while the polygon is empty, above an
// action bar with Reset, Undo and Save. Save calls the host's async onSave
// and reports through onSaved / onSaveError. State lives in view_model.dart,
// the tree in view.dart and the private pieces in widgets/.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_skeleton/utils/load_state.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";
import "package:flutter_skeleton/widgets/custom/MapPolygonEditor/index.dart";
import "package:latlong2/latlong.dart";

part "view_model.dart";
part "view.dart";
part "widgets/action_bar.dart";
part "widgets/hint_pill.dart";

/// Lowest camera zoom of the map.
const double _kMinZoom = 2;

/// Highest camera zoom of the map.
const double _kMaxZoom = 18;

/// Map panel for drawing one polygon and saving it.
///
/// - A [MapPolygonEditor] fills the space above the action bar: tap the map
///   to add a vertex, tap an edge to insert one, drag a vertex to move it.
/// - While there is no vertex, a hint pill ([hint]) floats over the top of
///   the map; it lets taps through to the map.
/// - The action bar holds Reset and Undo (enabled from one vertex) and Save
///   (enabled from 3 vertices).
///
/// Save calls [onSave] once with the vertices and shows a [Loader] in place
/// of the button until it completes. It then calls [onSaved], or
/// [onSaveError] with the thrown error, and the button comes back. Neither
/// is called when the panel was removed in the meantime. The panel shows no
/// message itself: the host reports the outcome (toast, inline text…).
///
/// [initialPoints] are read once, when the panel is first built; give the
/// panel a new `key` to load other points.
///
/// Give it a bounded height (the map is `Expanded`). Uses no Tooltip or
/// other overlay: it needs no `Overlay` ancestor.
///
/// Built-in strings (`custom.polygon_editor_panel.*`): `hint`, `reset`,
/// `undo`, `save`. [hint] and [saveLabel] replace the matching defaults.
final class PolygonEditorPanel extends StatefulWidget {
  /// Base map tiles; the host owns the tile URL, user agent and caching.
  final TileLayer tileLayer;

  /// Persists the polygon. Receives 3 or more vertices in polygon order (an
  /// unmodifiable copy); the host maps them to its own format. Throw to
  /// report a failure.
  final Future<void> Function(List<LatLng> points) onSave;

  /// Called with the error thrown by [onSave], so a failure is never silent.
  final void Function(Object error) onSaveError;

  /// Called after [onSave] completed (follow-up work: reload, close…).
  final VoidCallback? onSaved;

  /// Vertices shown on mount; with 3 or more, the camera fits them.
  final List<LatLng>? initialPoints;

  /// Hint shown over the empty map, already localised; defaults to
  /// `custom.polygon_editor_panel.hint`.
  final String? hint;

  /// Save button text, already localised; defaults to
  /// `custom.polygon_editor_panel.save`.
  final String? saveLabel;

  /// Camera centre before any fit.
  final LatLng initialCenter;

  /// Camera zoom before any fit, between 2 and 18.
  final double initialZoom;

  /// Optional last map layer, e.g. the attribution the tile source requires.
  final Widget? attribution;

  const PolygonEditorPanel({
    super.key,
    required this.tileLayer,
    required this.onSave,
    required this.onSaveError,
    this.onSaved,
    this.initialPoints,
    this.hint,
    this.saveLabel,
    this.initialCenter = const LatLng(0, 0),
    this.initialZoom = _kMinZoom,
    this.attribution,
  }) : assert(initialZoom >= _kMinZoom && initialZoom <= _kMaxZoom);

  @override
  State<PolygonEditorPanel> createState() => _PolygonEditorPanelState();
}
