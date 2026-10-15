// index.dart
//
// PolygonFormSheet — one-page sheet content that creates a named polygon on a
// map, optionally tied to one item picked first in a host-built picker.
// Composes MapPolygonEditor (drawing) and EditableValueRow (picked item).
// Declares the PolygonFormSelection / PolygonFormResult value classes. State
// lives in view_model.dart, the tree in view.dart, the crossing-edge check in
// controllers/ and the private pieces in widgets/.

import "dart:math" as math;

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_skeleton/utils/load_state.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/EditableValueRow/index.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";
import "package:flutter_skeleton/widgets/custom/MapPolygonEditor/index.dart";
import "package:latlong2/latlong.dart";
import "package:logger/logger.dart";

part "controllers/polygon_shape.dart";
part "view_model.dart";
part "view.dart";
part "widgets/draw_section.dart";
part "widgets/map_area.dart";
part "widgets/section_label.dart";
part "widgets/selection_card.dart";
part "widgets/sheet_header.dart";
part "widgets/submit_button.dart";

/// Lowest camera zoom of the drawing map.
const double _kMinZoom = 2;

/// Highest camera zoom of the drawing map.
const double _kMaxZoom = 18;

/// Builds the picker shown before the form. Call [onPicked] with the id of
/// the item the user chose.
typedef PolygonFormPickerBuilder = Widget Function(
  BuildContext context,
  ValueChanged<String> onPicked,
);

/// Item picked in the first phase of a [PolygonFormSheet], as the sheet
/// displays it.
@immutable
final class PolygonFormSelection {
  /// Id the picker reported through `onPicked`.
  final String id;

  /// Primary text of the selection row.
  final String title;

  /// Secondary text of the selection row; hidden when null or empty.
  final String? subtitle;

  /// Renders [subtitle] in italic (scientific names, codes…).
  final bool subtitleItalic;

  const PolygonFormSelection({
    required this.id,
    required this.title,
    this.subtitle,
    this.subtitleItalic = false,
  });
}

/// Payload handed to [PolygonFormSheet.onSubmit].
@immutable
final class PolygonFormResult {
  /// The picked item; null when the sheet has no picker phase.
  final PolygonFormSelection? selection;

  /// Three or more vertices in polygon order, with no crossing or touching
  /// edges (unmodifiable).
  final List<LatLng> points;

  /// Trimmed name; empty when the optional field was left blank.
  final String name;

  const PolygonFormResult({
    required this.selection,
    required this.points,
    required this.name,
  });
}

/// Single-page form that draws a polygon on a map, names it and submits it.
///
/// Flow:
/// 1. Optional picker phase, when [pickerBuilder] is set: the host's picker
///    fills the space under the header. When it reports an id, the sheet
///    resolves it with [loadSelection] and switches to the form, showing a
///    [Loader] in the selection section meanwhile. If [loadSelection] throws,
///    the sheet goes back to the picker with an inline error
///    (`custom.polygon_form_sheet.selection_error`, live region).
/// 2. The form, in a scrolling list:
///    - with a picker: the picked item as an [EditableValueRow] card
///      ([selectionIcon]); tapping it goes back to the picker;
///    - a 280 dp [MapPolygonEditor]: tap to add a vertex, tap an edge to
///      insert one, drag a vertex to move it (a vertex drag never scrolls
///      the form). Vertices stay in polygon order (tap order for plain
///      taps). A hint overlay shows while the polygon is empty, then a point
///      counter (with a check icon once the shape is valid) and undo / reset
///      buttons;
///    - when two edges cross or touch, an inline hint under the map
///      (`custom.polygon_form_sheet.crossing_edges`, live region);
///    - an optional name field ([nameHint] placeholder);
///    - the submit button, enabled once the polygon has 3 or more points, no
///      crossing edges and, with a picker, an item is selected.
///
/// Submitting calls [onSubmit] once with a [PolygonFormResult]; the button
/// shows a [Loader] meanwhile. On success the form stays locked and the sheet
/// calls [onClose], unless its route is no longer the current one (already
/// closing, or covered by another route). On failure the button is enabled
/// again and an inline error (live region) shows [submitErrorText]; the next
/// attempt clears it. A return to the picker keeps the form mounted behind
/// it, so the drawn points, the map camera and the name survive. The close
/// button calls [onClose] at any time; a running [onSubmit] is not
/// cancelled.
///
/// Content only: no drag handle, no background, no route handling. Give it a
/// bounded height (the header sits above an `Expanded` body), for example:
///
/// ```dart
/// showModalBottomSheet<void>(
///   context: context,
///   isScrollControlled: true,
///   useSafeArea: true,
///   showDragHandle: true,
///   builder: (BuildContext sheetContext) => Padding(
///     padding: EdgeInsets.only(
///       bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
///     ),
///     child: FractionallySizedBox(
///       heightFactor: 0.92,
///       child: PolygonFormSheet(
///         title: title,
///         tileLayer: tileLayer,
///         onSubmit: save,
///         onClose: () => Navigator.of(sheetContext).pop(),
///       ),
///     ),
///   ),
/// );
/// ```
///
/// or inside `ModalProvider.show(AppModal(...))` with a sized box.
///
/// The name field's selection handles and toolbar need an [Overlay] ancestor
/// (a routed page or a modal). No Tooltip is used.
///
/// Built-in strings (`custom.polygon_form_sheet.*`): `close`,
/// `selection_label`, `change_selection`, `selection_error`, `draw_label`,
/// `draw_hint`, `undo`, `reset`, `point_count` (namedArg `count`),
/// `crossing_edges`, `name_label`, `submit`, `submit_error`. The label
/// parameters below replace the matching defaults.
final class PolygonFormSheet extends StatefulWidget {
  /// Header text (both phases), already localised.
  final String title;

  /// Base map tiles; the host owns the tile URL, user agent and caching.
  final TileLayer tileLayer;

  /// Persists the polygon. Throw to keep the sheet open with an inline error;
  /// complete to make the sheet call [onClose]. Put follow-up work (reload…)
  /// here.
  final Future<void> Function(PolygonFormResult result) onSubmit;

  /// Close button, and called after a successful submit. The host closes its
  /// container (pops the sheet route, dismisses the modal…).
  final VoidCallback onClose;

  /// Picker shown before the form. Null: no picker phase and no selection
  /// section, so 3 points are enough to submit. Set together with
  /// [loadSelection].
  final PolygonFormPickerBuilder? pickerBuilder;

  /// Resolves a picked id into what the selection row displays. Throw to send
  /// the user back to the picker with an inline error.
  final Future<PolygonFormSelection> Function(String id)? loadSelection;

  /// Section header above the selection row; defaults to
  /// `custom.polygon_form_sheet.selection_label`.
  final String? selectionLabel;

  /// Icon in the selection row badge.
  final IconData selectionIcon;

  /// Section header above the map; defaults to
  /// `custom.polygon_form_sheet.draw_label`.
  final String? drawLabel;

  /// Section header above the name field; defaults to
  /// `custom.polygon_form_sheet.name_label`.
  final String? nameLabel;

  /// Placeholder of the name field; none when null.
  final String? nameHint;

  /// Submit button text; defaults to `custom.polygon_form_sheet.submit`.
  final String? submitLabel;

  /// Inline error after a failed submit; defaults to
  /// `custom.polygon_form_sheet.submit_error`.
  final String? submitErrorText;

  /// Camera centre of the map before the first vertex.
  final LatLng initialCenter;

  /// Camera zoom of the map, between 2 and 18.
  final double initialZoom;

  /// Optional last map layer, e.g. the attribution the tile source requires.
  /// The point counter covers the bottom-end corner of the map, so align it
  /// elsewhere (for example `SimpleAttributionWidget(alignment:
  /// Alignment.bottomLeft, …)`).
  final Widget? attribution;

  const PolygonFormSheet({
    super.key,
    required this.title,
    required this.tileLayer,
    required this.onSubmit,
    required this.onClose,
    this.pickerBuilder,
    this.loadSelection,
    this.selectionLabel,
    this.selectionIcon = Icons.label_outline_rounded,
    this.drawLabel,
    this.nameLabel,
    this.nameHint,
    this.submitLabel,
    this.submitErrorText,
    this.initialCenter = const LatLng(0, 0),
    this.initialZoom = _kMinZoom,
    this.attribution,
  }) : assert(
         (pickerBuilder == null) == (loadSelection == null),
         "pickerBuilder and loadSelection must be set together",
       ),
       assert(initialZoom >= _kMinZoom && initialZoom <= _kMaxZoom);

  @override
  State<PolygonFormSheet> createState() => _PolygonFormSheetState();
}
