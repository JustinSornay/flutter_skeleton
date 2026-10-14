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
- Numbers and dates use intl `NumberFormat.percentPattern` / `DateFormat` with
  `context.locale.toLanguageTag()`.

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
