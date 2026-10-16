# widgets/custom/

**Custom widgets** are generic, reusable components driven entirely by their
parameters: pickers, sheets, charts, maps, badges, lists (`Listing`,
`Loader`, …). They know nothing about the app's domain, so any page or render
widget can host them.

## Principle

1. **Generic.** No domain vocabulary in identifiers, strings, comments or
   tests. Data arrives through parameters, generic types (`T`), small value
   classes declared in the widget folder, or the shared `_base/` classes.
2. **Inert.** No provider reads, no service / `Http` / platform calls, no
   `Navigator` or `context.go`. Every outcome is a callback (`onChanged`,
   `onSelected`, `onRetry`, …) and the host decides what happens. Two
   exceptions: a sheet may pop its own modal route, and an optional static
   `show()` helper may call `showModalBottomSheet`.
3. **Themed, never hardcoded.** Colours come from `ColorScheme` tokens and
   `StatusTones` only.

## `_base/` — shared value classes

`_base/` is not a widget folder (same convention as `providers/_base` and
`api/dtos/_base`). Never redefine these classes in a widget.

| File | Class | Use |
|---|---|---|
| `choice_option.dart` | `ChoiceOption<T>` | Every option list (`value`, `label`, `description`, `trailing`, `icon`, `enabled`, `semanticsLabel`). Each widget's dartdoc states which fields it renders. |
| `value_band.dart` | `ValueBand` | A `[from, to)` band on a value axis; fill = tone `container` unless `color`; `resolveColor(context)`. |

## Conventions

**Structure**
- Strict MVVM with `part` / `part of`: `index.dart` (declaration, **all**
  imports, `part` directives), `view_model.dart` (State, stateful only),
  `view.dart` (`mixin _ViewMixin` with `render()`). Internal sub-widgets go in
  `widgets/*.dart` part files; complex pure logic goes in `controllers/`.
- `final class` by default, double quotes, explicit types, a short header
  comment in every file.

**Colours and tones**
- Only `Theme.of(context).colorScheme` tokens and
  `StatusTones.colorsOf(context, tone)` (`lib/theme/status_tones.dart`).
  No `Color(0x…)` literals, no `Colors.*` except `Colors.transparent`.
- Never declare a widget-specific tone enum: use `StatusTone`. A level enum
  that maps to a colour exposes a `StatusTone get tone`.
- A status colour is always paired with text or an icon (`StatusTone.icon`).
- Bars share the same tokens: track `cs.surfaceContainerHighest`, radius 999,
  fill = tone `foreground`.

**Motion and spacing**
- Every animation duration goes through `resolveMotion(context, …)`
  (`widgets/constants.dart`); repeating animations stop under reduced motion.
- Spacing uses `kDefaultPadding` multiples.

**Accessibility**
- Interactive targets ≥ `kMinTapTarget` (48 dp).
- `Semantics` labels on icon-only and informative elements.

**Text and formatting**
- Content strings are parameters (already localised by the host).
- Built-in chrome strings use `"custom.<snake_case_widget_name>.<key>".tr()`;
  add the keys to `fr.json` (canonical) and `en.json` in the same change.
  `easy_localization` is imported in `index.dart` only.
- Numbers and dates use intl `NumberFormat` / `DateFormat` with
  `numberLocaleOf(context)` / `dateLocaleOf(context)`
  (`utils/formatters/intl_locale.dart`), never a hand-rolled locale lookup.

**Sheets and overlays**
- Content-only sheets and panels draw **no drag handle**. The host mounts them
  with `showModalBottomSheet(showDragHandle: true, …)` or
  `ModalProvider.show(AppModal(...))`. Only the persistent `SnapBottomSheet`
  and `RankedListPanel` keep their own grip.
- A widget using `Tooltip`, `PopupMenuButton` or any other overlay says in its
  dartdoc that it needs an `Overlay` ancestor (a routed page or a modal) —
  `Layout` sits above the Navigator and has none.

**Maps**
- Map widgets take a required `TileLayer tileLayer` (`flutter_map`); the host
  owns tile URLs and caching.

**Tests** (`test/widget/custom/`)
- Use `pumpApp(tester, child, theme: …)` from
  `test/helpers/widget_test_helpers.dart` — `.tr()` returns the raw key.
- Tone-aware widgets get one smoke test under `AppTheme.dark()`.
- Avoid `pumpAndSettle` with repeating animations; use `pump(Duration)`.
- Map tests inject a fake `TileProvider` (no network).

## Catalogue

`Listing` (paginated lazy list) and `Loader` (centred progress indicator) ship with the skeleton. The other widgets below are generic; each folder's `index.dart` dartdoc documents its full API and hosting requirements.

### Sheets

| Widget | Purpose |
|---|---|
| `ConfirmCard` | Content of a confirmation modal: a title, an optional message, and cancel / confirm buttons (error colours when destructive). Mounted by `confirmAction()` in `api/controllers/_base`. |
| `AsyncPickerSheet` | Sheet content for picking one value of type `T` from a body that the caller builds, then committing it with an async `onSubmit`. |
| `MultiSelectSheet` | A content-only panel for a bottom sheet or `AppModal` where the user picks several values from a checkbox list and confirms. |
| `SingleSelectSheet` | Content for a bottom sheet or modal. The user picks exactly one value from radio rows, and the choice stays pending until they press confirm or cancel. |
| `OptionPickerSheet` | OptionPickerSheet is the content of a bottom sheet or modal for picking one value. |
| `EditFieldsSheet` | Sheet content that edits a few labelled text values. Save is enabled only while a value differs from its initial value, and it commits the values through an injected async `onSubmit`, showing busy and inline-error states. |
| `ExplainerSheet` | Content panel for a modal or bottom sheet that explains a result. It shows a header title, up to `maxItems` toned contributing items, a success row when there are no items, an optional badge slot and an optional "learn more" link. |
| `PreviewConfirmSheet` | Content for a modal or bottom sheet that previews one item before the user commits to an action. |
| `PolygonFormSheet` | A one-page sheet that creates a polygon on a map and gives it a name. It can first ask the user to pick an item in a picker the host builds. |
| `PolygonWizardSheet` | Sheet content that creates a named polygon on a map, step by step. The host lists typed steps (name, polygon, selection, summary), and the sheet shows them behind an animated step indicator and a Back / Next / Submit bar. |
| `SnapBottomSheet` | A bottom sheet that stays on screen over a full-screen background (map, canvas, media) and rests at three heights: collapsed, mid and full. |
| `EmailVerificationPrompt` | Modal content that asks the user to verify their email through a link. |

### Inputs and selection

| Widget | Purpose |
|---|---|
| `SearchField` | A rounded search text field, 48 dp tall. Its leading search icon turns into a `Loader` while loading, its focus border and glow animate through `resolveMotion`, and it has an optional accessible clear button. |
| `AutocompleteSearch` | A typed, debounced search field built on `SearchField`. It sends the trimmed query to an injected async lookup and shows the matches in an `OverlayPortal` dropdown anchored under the field. |
| `MaskedDigitField` | An outlined digit text field driven by a `#` pattern: `#` is a digit slot and any other character is a separator inserted between digits as the user types. |
| `EditableValueRow` | A compact, read-only summary of a value the user has already picked. It shows a tinted icon badge, a title, an optional subtitle and a "✏ Edit" chip. |
| `SegmentedPicker` | A stateless, generic single-select segmented track for a small set of `ChoiceOption<T>`. |
| `ChoiceChipRow` | A stateless single-choice selector for any `T`. It draws pill-shaped `ChoiceChip`s that wrap onto several lines, with an optional small caption above them. |
| `SelectionChipBar` | A floating "selection tray" that shows the selected `ChoiceOption<T>` entries as removable chips, next to one primary action button (compare, export, delete…). |
| `SelectionStrip` | A compact, full-width strip that summarises the active selection or context as `● <prefix> <value> <detail> ...... [Edit]`, with an optional edit action. |
| `ThumbnailChoicePicker` | A controlled single-choice picker. Each option is a tappable thumbnail (a custom preview, or a built-in mini app mockup drawn from a `ColorScheme`) with a caption. |
| `ComparisonPicker` | A list where the user assigns up to two items to slot A (the reference, `cs.primary`) and slot B (the comparison, `cs.tertiary`). |
| `CategoryBrowser` | A scrollable accordion picker with two levels. Only one group is open at a time, each group is an `ExpandableGroupTile`, and tapping an entry (or a non-expandable group) returns its typed value. |
| `ExpandableGroupTile` | A controlled accordion card for one group of selectable `ChoiceOption<T>` entries. |
| `LocationBar` | A generic "pick a place" bar, typed on the caller's place value `T`. It has three modes: a debounced search with a suggestion dropdown, an optional "use my current location" row, and a compact `EditableValueRow` with an edit affordance once a place is chosen. |
| `FileUploadPanel` | A self-contained panel for picking files. It lists them with their sizes, lets the user clear the selection, and uploads it through a host callback, showing progress, success or failure inline. |
| `ContextActionBar` | A floating row of round icon buttons for actions on the current selection or context. |

### Badges and labels

| Widget | Purpose |
|---|---|
| `PillBadge` | A small, fully rounded label (pill) with an optional leading icon, an optional tooltip shown on tap and a single accessible label. |
| `StatusPill` | A non-interactive status label tinted by a `StatusTone`. The default constructor draws a pill (a composed `PillBadge` with the tone's container fill). |
| `StatusPillGroup` | A wrapping row of `StatusPill` widgets whose items the host loads once through an async callback. |
| `SeverityBadge` | A non-interactive inline pill that flags how serious one item is on a 3-level scale (`SeverityLevel` low / medium / high, mapped to the success / warning / danger tones). |
| `ConfidenceBadge` | A compact indicator for any normalised 0..1 reliability, quality or confidence value. |
| `VersionBadge` | An outlined pill that names a version (of a model, dataset, API, document revision and so on) and shows whether it is the current one. |
| `SourceBadge` | A small outlined pill that names where a value comes from (a dataset, a publication, an internal reference). |
| `IndicatorChip` | A compact chip with a tinted fill and border (radius 8) that shows one indicator. |
| `IndicatorChipRow` | A compact, read-only `Wrap` of icon-and-label indicator chips that reflows on narrow panels. |
| `MetricLabel` | A muted header row for metric, stat or KPI displays (tiles, bars, gauges). |
| `PillLink` | A small pill-shaped link placed inline next to a value, header or badge. |

### Bars and gauges

| Widget | Purpose |
|---|---|
| `LabeledProgressBar` | A stateless, labelled, determinate progress bar for a ratio in [0, 1]. |
| `LevelProgressBar` | A segmented progress bar through an ordered list of named levels (plans, stages, ranks). |
| `QuotaBar` | A compact "used / limit" meter for any capped resource. It shows a title, a two-tone count and a 5 dp pill bar. |
| `QualitativeScoreBar` | Shows a normalised 0..1 score as a word plus a thin bar in the same tone, with no number on screen or for screen readers. |
| `ComparisonBar` | A compact one-row bar that compares a baseline value and a comparison value of the same metric on a bounded scale. |
| `DistributionBar` | A part-of-whole breakdown. One stacked horizontal bar has a slice per segment, sized by its share of the total. |
| `RangeEnvelopeBar` | A horizontal banded value scale that shows the min–max envelope (spread) of one or two series of sample values. |
| `ClusteredValueAxis` | A horizontal 0–1 value axis. It plots points as tappable bubbles over optional `ValueBand` backgrounds, with one optional reference marker. |

### Charts and timelines

| Widget | Purpose |
|---|---|
| `Sparkline` | A compact inline trend line for any ordered numeric series (for example a metric history in a table cell, a list tile or a summary tile). |
| `TrendChart` | A time-series line chart (fl_chart) for a chronological list of (date, value) samples, evenly spaced by index. |
| `StepRangeChart` | A read-only categorical step chart. Each column shows one value as a flat step with a dot. |
| `RadarChartCard` | A collapsible card that draws an N-axis radar (spider) chart with fl_chart. |
| `StatusStrip` | A compact strip of N equal period cells (months, days, hours…). Each cell is filled with its category colour and shows a short period label, and a legend lists the categories present. |
| `StatusHeatmapRow` | A compact strip of equal-width cells that never scrolls and compares one numeric value across a few ordered columns. |
| `ValueMatrix` | A table of numbers with rows and columns, sortable by column. Each column is loaded by an async callback the host injects, a few columns at a time. |
| `HistoryTimeline` | A small horizontal timeline for any history list (versions, visits, check-ins, snapshots). |

### Cards, panels and tables

| Widget | Purpose |
|---|---|
| `SectionCard` | A titled, bordered, rounded card that groups related rows under a section label, a hairline divider and the caller's rows, which run edge to edge. |
| `SectionBlock` | A stateless, numbered section container. A circular index badge sits next to a title and an optional caption, and any content widget is placed below. |
| `CollapsibleSectionCard` | A controlled accordion card for any content. The parent owns `isOpen` and `onToggle`. |
| `ExpandableCard` | An accordion card for one list or summary item. The header holds the title, subtitle, an optional status badge, one or two key values and a round chevron, and it is the only part that toggles the card. |
| `ContextHeader` | A header for a detail panel. It shows a leading icon, a title that may still be loading (a pulsing skeleton while it is null), a subtitle that is always shown, an optional inline "change" link, and a divider below. |
| `MetricTile` | A compact, read-only stat tile. It shows a MetricLabel header (the label in capitals, with an optional icon), a prominent formatted value with an optional smaller unit, and an optional caption line. |
| `StatStrip` | A responsive strip of summary stat tiles (KPIs) for dashboards and report or detail headers. |
| `DeltaCards` | A compact row of 2 to 4 equal cards. Each card shows how one metric changed between two states (before/after, period A/B, plan/actual) with a label, a value and a toned trend caption. |
| `ScoreBanner` | A stateless, full-width summary banner for a normalised score in [0, 1], coloured by a `StatusTone`. |
| `ScoreListCard` | A titled card that loads a list of items with an injected async callback and shows each item as a compact scored row: title, optional italic subtitle, a 6 dp bar for a 0..1 score with its value label, and an optional caption. |
| `WeightedScoreCard` | An interactive "what-if" card for a weighted score. The user sets the weights of N components with sliders that always add up to 100 %. |
| `ThumbnailMetricCard` | A list card that compares a few values of one item. It shows a 56 x 56 rounded thumbnail (any `ImageProvider`, with an icon placeholder when the image is missing or broken), a one-line title and an optional subtitle, a row of small labelled value columns (each with an optional status-tone marker) and an optional `StatusPill` change badge led by its tone icon. |
| `ListEntryCard` | One tappable row of a result list. The header has a bold title, an optional muted subtitle, an optional status pill (a composed `StatusPill`) and a chevron that shows only when the card is tappable. |
| `SwimlaneCard` | A titled card with a lane of fixed-width tiles that scrolls horizontally. |
| `AsyncSummaryCard` | A card that loads a short narrative text (a summary, explanation or recommendation) through an injected async callback and handles the whole lifecycle itself:. |
| `ComparisonPanel` | A decision panel whose expansion the parent controls. It compares a current option with a candidate option before the user confirms a change. |
| `TrendSplitSection` | Two cards side by side that compare a "rising" list (left) with a "falling" list (right) of labelled signed values. |
| `IconListPanel` | A read-only titled card with a tinted header band and a divided list of rows. |
| `CardTable` | A small table for short lists, generic over the row type `T`. It is drawn as a bordered card with caller-declared columns, an uppercase micro-label header, divider-separated rows that can be tapped, an optional detail slot under each row, and an empty card when there are no rows. |
| `FilterableDataTable` | A controlled data-table card for rows of any type `T`. It has a titled header with the row count, optional single-choice filter chips ("all" first, and tapping the selected chip clears the filter) and a horizontally scrolling, sortable Material `DataTable` whose columns the caller declares. |

### Lists

| Widget | Purpose |
|---|---|
| `RankedList` | A compact, height-capped, scrollable list of ranked, tappable rows. Each row has a rank circle, a label with an optional detail line, an optional percentage score shown as a StatusPill, and an optional decorative trailing icon. |
| `RankedListPanel` | A persistent panel styled like a bottom sheet. It lists a short, already-ordered set of ranked rows. |
| `RankedBadgeList` | A collapsible list of tone-tinted badges, ranked by descending weight. |
| `MasterListPanel` | A fixed-width sidebar for the list side of a list/detail screen. It has an optional create button and optional category tabs with counts. |

### States and gating

| Widget | Purpose |
|---|---|
| `StateMessageView` | A centred, full-area state message for error, empty, prerequisite-missing or blocked screens. |
| `ProgressStatusView` | A centred, full-area determinate progress display for any long-running or polled background job. |
| `AuthLockedState` | A centred empty state for content that needs a signed-in user. It shows an icon, a title, a short explanation and one sign-in button. |
| `FeatureGate` | Shows its child when access is granted, otherwise a locked state in one of five modes (lock card, dimmed preview, blurred teaser, compact hint row, hidden). |
| `CollapsedGateGroup` | A collapsible disclosure that folds a list of locked or unavailable features into one row, listing each feature (icon, label, optional pill) above a single call to action whose outcome the host supplies. |
| `SkeletonBlock` | A static, theme-aware rounded placeholder rectangle for loading skeletons (boxes, text lines, pills, avatars, media banners). |

### Maps

| Widget | Purpose |
|---|---|
| `MapPin` | A theme-aware teardrop location pin (round head and tapered wick, with the tip at the bottom centre of its box) that marks a point on a map, an image or a diagram. |
| `MapThumbnail` | A small map preview with no gestures, for list rows, cards and headers. |
| `MapPolygonEditor` | A map widget with no chrome for drawing and editing one polygon. You tap to add vertices. |
| `PolygonEditorPanel` | A map panel for drawing one polygon and saving it. It composes MapPolygonEditor (tap to add, snapping, edge insert, draggable vertices) and adds two things: a hint pill over the map while the polygon is empty, and an action bar with Reset, Undo and Save. |
| `MapExportOverlay` | A capture-only, non-interactive overlay that sits over a map or chart during an image export. |
