// index.dart
//
// PolygonWizardSheet — multi-step sheet content that creates a named polygon
// on a map. The host lists typed steps (name, polygon, selection, summary);
// the sheet shows them behind an animated step indicator and a
// Back / Next / Submit bar. Composes MapPolygonEditor (drawing), PillBadge
// (vertex counter) and EditableValueRow (picked item), and shares
// PolygonFormSelection / PolygonFormResult with PolygonFormSheet (exported
// here). Declares the step and suggestion value classes. State lives in
// view_model.dart, the tree in view.dart, the pure rules in controllers/ and
// one part per step kind in widgets/.

import "dart:async";
import "dart:math" as math;

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_skeleton/utils/load_state.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/EditableValueRow/index.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";
import "package:flutter_skeleton/widgets/custom/MapPolygonEditor/index.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";
import "package:flutter_skeleton/widgets/custom/PolygonFormSheet/index.dart";
import "package:latlong2/latlong.dart";
import "package:logger/logger.dart";

export "package:flutter_skeleton/widgets/custom/PolygonFormSheet/index.dart"
    show PolygonFormResult, PolygonFormSelection;

part "controllers/wizard_rules.dart";
part "view_model.dart";
part "view.dart";
part "widgets/busy_indicator.dart";
part "widgets/inline_error.dart";
part "widgets/map_area.dart";
part "widgets/name_step.dart";
part "widgets/navigation_bar.dart";
part "widgets/polygon_step.dart";
part "widgets/progress_line.dart";
part "widgets/selection_chip.dart";
part "widgets/selection_step.dart";
part "widgets/step_header.dart";
part "widgets/step_indicator.dart";
part "widgets/suggestions_bar.dart";
part "widgets/summary_step.dart";

/// Lowest camera zoom of the drawing map.
const double _kMinZoom = 2;

/// Highest camera zoom of the drawing map.
const double _kMaxZoom = 18;

/// What a [PolygonWizardStep] renders and what it needs before Next.
enum PolygonWizardStepKind {
  /// A text field; Next stays disabled while it is blank.
  name,

  /// The map editor; Next needs 3 or more vertices and no crossing edges.
  polygon,

  /// The host's picker; Next needs at least one resolved selection.
  selection,

  /// A read-only recap card; always complete.
  summary,
}

/// One step of a [PolygonWizardSheet].
@immutable
final class PolygonWizardStep {
  /// What the step renders.
  final PolygonWizardStepKind kind;

  /// Step heading, also the label under its indicator segment (already
  /// localised).
  final String title;

  /// Short instruction under the heading (already localised).
  final String hint;

  const PolygonWizardStep({
    required this.kind,
    required this.title,
    required this.hint,
  });
}

/// A previously drawn polygon the user can import into the polygon step.
@immutable
final class PolygonSuggestion {
  /// Unique among all suggestions; marks the imported chip.
  final String id;

  /// Chip text (already localised).
  final String label;

  /// Vertices in polygon order. A suggestion with fewer than 3 points is
  /// shown but ignored on tap.
  final List<LatLng> points;

  const PolygonSuggestion({
    required this.id,
    required this.label,
    required this.points,
  });
}

/// A titled horizontal row of [PolygonSuggestion] chips ("Recent",
/// "Previous"…).
@immutable
final class PolygonSuggestionGroup {
  /// Row heading (already localised).
  final String title;

  /// Chips of the row, in display order. An empty group is not shown.
  final List<PolygonSuggestion> suggestions;

  const PolygonSuggestionGroup({
    required this.title,
    required this.suggestions,
  });
}

/// Builds the picker of the selection step. Call [onPicked] with the id of
/// the item the user chose. [selectedIds] are the ids already selected (to
/// mark them); [polygon] holds the vertices drawn so far (empty when the
/// selection step comes first).
///
/// The builder runs on every rebuild of the sheet: the host owns any
/// controller its picker needs, so scroll and search state survive picks.
///
/// A [PolygonFormPickerBuilder] and a PolygonFormSheet `loadSelection`
/// adapt with one-line lambdas:
///
/// ```dart
/// pickerBuilder: (BuildContext c, ValueChanged<String> onPicked, _, _) =>
///     formPicker(c, onPicked),
/// loadSelection: (String id, LatLng _) => formLoad(id),
/// ```
typedef PolygonWizardPickerBuilder =
    Widget Function(
      BuildContext context,
      ValueChanged<String> onPicked,
      Set<String> selectedIds,
      List<LatLng> polygon,
    );

/// Persists the polygon. [result] carries the resolved name, the vertices
/// and the first selection; [selections] holds every selection in pick
/// order (empty without a selection step).
typedef PolygonWizardSubmit =
    Future<void> Function(
      PolygonFormResult result,
      List<PolygonFormSelection> selections,
    );

/// Step-by-step sheet content that draws a polygon on a map, optionally names
/// it and ties it to items picked in a host-built picker, then submits it.
///
/// The host lists the [steps] in order. Each step has a
/// [PolygonWizardStepKind]:
/// - `name`: a text field ([nameLabel] placeholder, autofocused); Next stays
///   disabled while it is blank. A non-blank [initialName] pre-fills it and,
///   when the first step is the name step, the sheet starts on the second
///   step (Back returns to the field, text kept).
/// - `polygon`: a [MapPolygonEditor] (tap to add a vertex, tap an edge to
///   insert one, drag a vertex) with undo / reset buttons, a live vertex
///   counter ([PillBadge]) and, when [suggestions] or [loadSuggestions]
///   provide some, chips that import a previously drawn polygon (tap the
///   imported chip again to clear it). Next needs 3 or more vertices and no
///   crossing or touching edges; crossing edges show an inline hint.
///   Coming back to this step fits the camera to the polygon.
/// - `selection`: the host's picker ([pickerBuilder]). A pick is resolved
///   with [loadSelection], which also receives the centroid of the polygon
///   ([initialCenter] while there is none). With
///   [allowMultipleSelections] false the picker gives way to a [Loader]
///   (static under reduced motion), then to the picked item as an
///   [EditableValueRow] card; tapping the card goes back to the picker. With
///   it true the picker stays mounted under a band of removable chips, and a
///   thin progress line (static under reduced motion) shows while a pick
///   resolves; picking an id already selected or still resolving does
///   nothing. A failed [loadSelection] adds nothing and shows an inline
///   error. Next needs at least one selection and no pick still resolving.
/// - `summary`: a card with the typed name, the selected titles and the
///   vertex count (a row is left out when its data is absent).
///
/// Steps: exactly one `polygon` step, at most one `name` and one `selection`
/// step (asserted). A `selection` step needs [pickerBuilder] and
/// [loadSelection] (set together). The progress kept while mounted (step,
/// drawing, selections) assumes the same steps: give the sheet a new [Key]
/// to restart it with another list.
///
/// The last step's button submits once all steps are complete: it calls
/// [onSubmit] once and shows a [Loader] meanwhile (static under reduced
/// motion). The [PolygonFormResult] carries the trimmed typed name, else the
/// first selection's title, else [fallbackName]; the vertices (3 or more, no
/// crossing edges); and the first selection (null without a selection
/// step). While [onSubmit] runs and after it succeeds the sheet is locked:
/// the map, undo / reset, the suggestion chips, the name field, the
/// selections and Back ignore input. On success the button shows its label
/// again, disabled, and the sheet calls [onSubmitted], unless its route is
/// no longer the current one; the host closes the sheet. On failure the
/// error is logged, an inline error (live region) shows [submitErrorText]
/// above the buttons and the sheet is unlocked again.
///
/// Content only: no drag handle, no background, no route handling. Give it a
/// bounded height (the step body is `Expanded`), for example:
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
///       child: PolygonWizardSheet(
///         steps: steps,
///         tileLayer: tileLayer,
///         onSubmit: save,
///         onSubmitted: () => Navigator.of(sheetContext).pop(),
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
/// Built-in strings (`custom.polygon_wizard_sheet.*`): `back`, `next`,
/// `submit`, `submit_error`, `undo`, `reset`, `points_placed` (namedArg
/// `count`), `crossing_edges`, `loading`, `name_label`, `default_name`,
/// `selection_label`, `selected_count` (`count`), `selection_error`,
/// `remove_item` (`label`), `points_label`, `points_count` (`count`),
/// `step_semantics` (`current`, `total`, `title`). The label parameters
/// below replace the matching defaults.
final class PolygonWizardSheet extends StatefulWidget {
  /// Ordered steps; see the class documentation for the allowed mix.
  final List<PolygonWizardStep> steps;

  /// Base map tiles; the host owns the tile URL, user agent and caching.
  final TileLayer tileLayer;

  /// Persists the polygon. Throw to keep the sheet open with an inline
  /// error; complete to make the sheet call [onSubmitted].
  final PolygonWizardSubmit onSubmit;

  /// Called after a successful [onSubmit]. The host closes its container
  /// (pops the sheet route, dismisses the modal…).
  final VoidCallback? onSubmitted;

  /// Last-step button text; defaults to `custom.polygon_wizard_sheet.submit`.
  final String? submitLabel;

  /// Inline error after a failed submit; defaults to
  /// `custom.polygon_wizard_sheet.submit_error`.
  final String? submitErrorText;

  /// Pre-fills the name field; see the `name` step.
  final String? initialName;

  /// Name field placeholder and summary row label; defaults to
  /// `custom.polygon_wizard_sheet.name_label`.
  final String? nameLabel;

  /// Name used when nothing was typed and nothing is selected; defaults to
  /// `custom.polygon_wizard_sheet.default_name`.
  final String? fallbackName;

  /// Camera centre of the map before the first vertex, and the centroid
  /// passed to [loadSelection] while there is no vertex.
  final LatLng initialCenter;

  /// Camera zoom of the map, between 2 and 18.
  final double initialZoom;

  /// Optional last map layer, e.g. the attribution the tile source requires.
  /// The vertex counter covers the bottom-end corner of the map, so align it
  /// elsewhere (for example `SimpleAttributionWidget(alignment:
  /// Alignment.bottomLeft, …)`).
  final Widget? attribution;

  /// Suggestion rows shown at once in the polygon step. Read on every
  /// build: a rebuild with other rows shows them (the loaded rows stay
  /// after them).
  final List<PolygonSuggestionGroup> suggestions;

  /// Loads more suggestion rows, appended after [suggestions]. A thin
  /// progress bar shows meanwhile; errors are logged and swallowed. Pass
  /// null when there is nothing to load.
  final Future<List<PolygonSuggestionGroup>> Function()? loadSuggestions;

  /// Picker of the selection step; set together with [loadSelection].
  final PolygonWizardPickerBuilder? pickerBuilder;

  /// Resolves a picked id (with the polygon centroid) into what the sheet
  /// displays. Throw to add nothing and show an inline error.
  final Future<PolygonFormSelection> Function(String id, LatLng centroid)?
  loadSelection;

  /// False: one selection, shown as a card. True: several, shown as chips
  /// above a picker that stays mounted.
  final bool allowMultipleSelections;

  /// Summary row label of the selections; defaults to
  /// `custom.polygon_wizard_sheet.selection_label`.
  final String? selectionLabel;

  /// Icon of the selection card badge and of the summary row.
  final IconData selectionIcon;

  const PolygonWizardSheet({
    super.key,
    required this.steps,
    required this.tileLayer,
    required this.onSubmit,
    this.onSubmitted,
    this.submitLabel,
    this.submitErrorText,
    this.initialName,
    this.nameLabel,
    this.fallbackName,
    this.initialCenter = const LatLng(0, 0),
    this.initialZoom = _kMinZoom,
    this.attribution,
    this.suggestions = const <PolygonSuggestionGroup>[],
    this.loadSuggestions,
    this.pickerBuilder,
    this.loadSelection,
    this.allowMultipleSelections = false,
    this.selectionLabel,
    this.selectionIcon = Icons.check_circle_outline,
  }) : assert(
         (pickerBuilder == null) == (loadSelection == null),
         "pickerBuilder and loadSelection must be set together",
       ),
       assert(initialZoom >= _kMinZoom && initialZoom <= _kMaxZoom);

  @override
  State<PolygonWizardSheet> createState() => _PolygonWizardSheetState();
}
