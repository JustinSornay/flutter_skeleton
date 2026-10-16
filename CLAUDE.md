# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Working Principles

**Think before coding.** State assumptions explicitly. When ambiguity exists, present interpretations and ask rather than guessing silently. Push back if a simpler approach exists.

**Surgical changes.** Touch only what the task requires. Don't refactor, reformat, or "improve" adjacent code. Match existing style even if you'd do it differently. If unrelated dead code is spotted, mention it — don't remove it.

**Goal-driven execution.** For bugs: write a test that reproduces it, then fix it. For features: define success criteria before implementing. Multi-step tasks get a brief plan (`step → verify`) upfront.

**Simplicity first.** Minimum code that solves the problem. No speculative features, no abstractions for single use, no flexibility that wasn't requested. If 50 lines do the job, don't write 200.

## Commands

```bash
# Dependencies
flutter pub get

# Run
flutter run -d chrome
flutter run -d linux        # or windows / macos

# Static analysis
flutter analyze
dart run custom_lint        # solid_lints complexity metrics

# Tests
flutter test                # everything
flutter test test/unit/
flutter test test/widget/
flutter test test/path/to/file_test.dart

# Quality gate (analyze + custom_lint + unit + widget tests)
bash tooling/hooks/test-gate.sh --force

# Code generators (from repo root)
dart cli/generation/widget/index.dart --className MyWidget --path core/render
dart cli/generation/widget/index.dart --className MyBadge --path custom --stateless
dart cli/generation/service/index.dart --className MyEntity [--route my-entities]
```

Flutter SDK: **3.41.7** (Dart 3.11). Keep the version identical across machines.

## Testing

Tests live in `test/` with two layers: `unit/` and `widget/`.

### Unit tests (`test/unit/`)

Pure logic — no widgets. Run: `flutter test test/unit/`

- `Http` is tested end-to-end without network: `http.runWithClient(() => …, () => MockClient(…))` replaces the `Client()` that `Http` creates internally. Load env values with `dotenv.testLoad(fileInput: "API_API_URL=…")` and reset auth hooks with `tearDown(Http.resetAuthHooks)`.
- Timer-based provider logic uses `testWidgets` for its fake clock (`tester.pump(Duration)`).
- `translations_test.dart` enforces the localization key contract (see Localization).

### Widget tests (`test/widget/`)

Run: `flutter test test/widget/`

Shared helpers in `test/helpers/widget_test_helpers.dart`:

| Helper | Use for |
|---|---|
| `pumpApp(tester, child, providers:, theme:)` | Isolated widgets; `.tr()` returns the raw key; `theme` defaults to `AppTheme.light()` |
| `pumpWithRouter(tester, child, extraRoutes:)` | Widgets calling `context.go()` |
| `pumpLocalizedRouter(tester, initialLocation:)` | The real shell (router + Layout + EasyLocalization with real translations); required when a widget reads `context.locale` |
| `defaultTestProviders(offline:)` | Global providers without platform channels |

**Injectable seam pattern:** static service methods aren't mockable. Render widgets and providers expose optional named function params (`getList`, …) whose production default is the service method; widgets that go through a controller take the controller instead (`TodoDetail(controller: TodoController(getTodo: fake))`). Tests pass plain fake closures at construction time. See `TodoList` / `TodoDetail` / `TodoController` and their tests.

## Environment

The app loads `.env.local` at startup via `flutter_dotenv`. **The file is bundled as an asset and readable by anyone who downloads the build — never put secrets in it.**

```
API_API_URL=<host[:port]>   # no scheme
API_API_SCHEME=https        # or http
ITEM_PER_PAGE=20            # Listing default page size
LOGGER_DEBUG=true
LOGGER_VERBOSE=false        # logs every successful request
LOGGER_ERROR=true           # logs HTTP / DTO contract errors
```

The `HttpApiEnum` key (e.g. `api` → `API`) is the prefix for the URL / scheme lookup. Read env values through `Env` (`lib/utils/env.dart`), which never throws.

## Package name

`flutter_skeleton` — used in all import paths (e.g. `import "package:flutter_skeleton/widgets/..."`). See README → "Renommer le projet" to change it.

## Key dependencies

| Package | Role |
|---|---|
| `go_router` | Declarative routing |
| `provider` | ChangeNotifier state management |
| `http` | Raw client wrapped by `Http` |
| `flutter_dotenv` | `.env.local` loading at startup |
| `easy_localization` | i18n with JSON translation files (persists the chosen locale) |
| `connectivity_plus` | Network status stream (`OfflineBanner`) |
| `fl_chart` | Charts in `widgets/custom/` |
| `flutter_map` + `latlong2` | Tile maps in `widgets/custom/` |
| `logger` | Logging |
| `custom_lint` + `solid_lints` (dev) | Complexity metrics |
| `jinja` + `args` (dev) | Code generators |

## Architecture

### Golden Rules

- **Look before you create**: search `utils/`, `widgets/custom/`, `api/http/` before writing anything new. Use the existing `Listing` widget for paginated lazy-loaded lists.
- **No project-specific names**: keep nomenclature generic (`api`, `dto`, `model`) — never use the app name in folder/variable names.
- **Read READMEs**: check README.md files in target directories before modifying them (`lib/widgets/`, `lib/widgets/core/render/`, `lib/widgets/core/decorators/`, `lib/widgets/custom/`, `lib/widgets/layout/`, `lib/api/dtos/`, `lib/api/services/`, `lib/api/controllers/`, `lib/utils/`).
- **Mirror existing patterns**: inspect similar files before writing new ones.
- **Never wrap `Listing` in a scroll view**: `Listing` manages its own `ScrollController`. Wrapping it in `SingleChildScrollView` or `ListView` breaks lazy loading. Use `Column` + `Expanded` around it (or `FullPageTemplate` / a `SplittedPageTemplate` panel, which already do; never `FollowUpPageTemplate`, whose body scrolls). Give it a `ValueKey` containing every param that should trigger a refresh (query, filters, locale).

### Directory Structure (`lib/`)

```
api/
  controllers/  # User-facing flows around service calls (toasts, redirection, confirmation) (+ _base/confirmAction)
  dtos/         # Data Transfer Objects (input/ and output/ sub-folders per entity)
  http/         # Http utility class, HttpOutput, ApiException, enums
  services/     # One service class per entity (+ _base/apiFilterBuilder)
data/           # Static in-memory data (nav entries, locale config)
providers/      # ChangeNotifier providers (+ _base helpers)
routing/
  pages/        # Page widgets: thin template + render widget wrappers
  router/       # GoRouter config
  templates/    # Page layout templates (FullPageTemplate, SplittedPageTemplate, FollowUpPageTemplate)
theme/          # AppTheme (light / dark from one seed colour), StatusTones
utils/          # Env, LoadState, ActionState, requireAuth, Coords, geo, parsers, extensions, builders, logger filters (see its README)
widgets/
  constants.dart  # spacing grid, content width, motion, resolveMotion()
  core/
    render/     # Screen-level MVVM triads (index + view_model + view)
    decorators/ # Content-agnostic wrappers (SkeletonPulse)
  custom/       # Generic reusable widgets (Listing, Loader, …)
    _base/      # Shared value classes: ChoiceOption<T>, ValueBand
  layout/       # App shell, global overlays, banners
main.dart       # Bootstrap, providers, MaterialApp.router
```

Create `models/` (plain Dart models, sealed unions) and `services/` (local, non-API services: cache, export…) when the first one is needed.

The **demo feature** (todos from JSONPlaceholder) spans `api/dtos/todo/`, `api/services/todo_service.dart`, `api/controllers/todo_controller.dart`, `widgets/core/render/Todo*/`, `routing/pages/{home,todo}_page.dart` and their tests. It exists to show every layer working together; delete it when starting a real project.

### Coding conventions

- Prefer `final class` for widgets, DTOs, value objects, providers, services, and any class not intended to be subclassed. Use `class` / `abstract class` only when inheritance is architecturally justified.
- Dart string literals use **double quotes** throughout (enforced by `prefer_double_quotes`).
- Declare types explicitly on locals, closure parameters and collection literals (`<String>[]`, `(BuildContext context) => …`); `strict-casts`, `strict-inference` and `strict-raw-types` are on.
- Files start with a short header comment: file name, purpose, relationships.

### Widget Pattern (strict MVVM with `part`/`part of`)

Every widget is split across files in its own PascalCase folder. **Never put UI and logic in the same file.** Generate the boilerplate with the widget generator.

**StatefulWidget** — 3 files:

`index.dart`
```dart
import "package:flutter/material.dart";
part "view_model.dart";
part "view.dart";

final class Example extends StatefulWidget {
  const Example({super.key});
  @override
  State<Example> createState() => _ExampleState();
}
```

`view_model.dart`
```dart
part of "index.dart";

final class _ExampleState extends State<Example> with _ViewMixin {
  @override
  void initState() { super.initState(); }
  @override
  void dispose() { super.dispose(); }
  @override
  Widget build(BuildContext context) { return render(context, this); }
}
```

`view.dart`
```dart
part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, _ExampleState state) {
    return const SizedBox.shrink();
  }
}
```

**StatelessWidget** — 2 files (`index.dart` + `view.dart`):

```dart
// index.dart
final class Example extends StatelessWidget with _ViewMixin {
  const Example({super.key});
  @override
  Widget build(BuildContext context) { return render(context, this); }
}

// view.dart
mixin _ViewMixin {
  Widget render(BuildContext context, Example widget) { ... }
}
```

All imports go in `index.dart` (part files cannot import).

### Render widgets — controllers and sub-widgets

Complex `widgets/core/render/` components may extend the 3-file pattern with two additional layers:

- `controllers/` — plain Dart classes (not State, not ChangeNotifier) that encapsulate a discrete piece of business logic. Instantiated and owned by the view-model.
- `widgets/` — small stateless composable pieces used only within that render widget. Each is a single file (no folder); never imported from outside.

Async screen state uses `LoadState<T>` (`utils/load_state.dart`: `Idle`, `Loading`, `Loaded`, `LoadError`) with an exhaustive `switch` in the view — not ad-hoc `isLoading` / `hasError` / `data` triples.

### API Layer

**DTOs**
- Location: `api/dtos/<entity>/output/<name>_output.dart` or `api/dtos/<entity>/input/<name>_input.dart`
- 1 DTO = 1 file; singular file names (`detail_output.dart`, not `models.dart`)
- Outputs implement `OutputInterface` and use `.fromOutput(HttpOutput output)` as their **only** constructor — no `const` named constructor, no `fromJson`
- Nested sub-DTOs also implement `OutputInterface` and follow the same rule
- Parse via `output.cast<T>("key")`, `output.output("key")`, `output.outputList("key")` — never read `output.json` directly for typed fields. `cast` is strict: missing key or wrong type throws.
- Inputs extend `AbstractInput` and implement `Map<String, dynamic> toJson()`, omitting unset optional fields
- Specs that provide `fromJson(Map<String, dynamic>)` patterns must be converted to `fromOutput(HttpOutput)`

**Services**
- One class per entity (`TodoService`, …); generate them with the service generator
- All methods are `static Future<T>`
- Always use `Http.output`, `Http.listOutput`, `Http.input`, `Http.request`, or `Http.listen`
- Always wrap in `try { ... } catch (e) { Logger().e("ServiceName.methodName: $e"); rethrow; }` (or the equivalent `.withErrorLog("ServiceName.methodName")` from `utils/extensions/future_extensions.dart`) — every service catch block is an observability checkpoint; a bare rethrow is incomplete
- Pass an `ApiFilterBuilder` as `queryBuilder` for filtered/paginated list calls

**Controllers** (`api/controllers/`, see its README)
- Sit between view models and services, like API controllers: they call services and own what the user experiences around the call — error toasts, redirection, the meaning of a status code for the flow (404 = gone, 409 = exists), auth and multi-step flows, confirmation modal (`confirmAction`), feedback overlay, success toast (`AppErrorLevel.success`)
- One `final class <Entity>Controller` per entity or flow, `const` constructor whose params are the service calls defaulting to the static service methods (test seam)
- Methods are `Future<T>` taking `BuildContext` first and never throw: the return value (`LoadState<T>`, `T?`, `bool`) tells the view model what happened; local UI state stays in the view model
- Read providers before the first `await`; after it, use the context only behind `context.mounted`

**Http utility** (`api/http/http.dart`)
- `Http.output` — GET → single `HttpOutput` (unwraps a `data` object envelope)
- `Http.listOutput` — GET → `List<HttpOutput>` (accepts a bare array or a `data` envelope)
- `Http.input` — POST/PUT/PATCH → `HttpOutput`
- `Http.request` — HEAD/DELETE → void
- `Http.listen` — streaming via `StreamTransformer`

Every method throws `ApiException(status, detail)` for HTTP 400+ (`detail` comes from the body's `detail` / `title` / `error`, else the status text). Routes must have no leading `/`.

Auth hooks (no auth provider ships with the skeleton): `Http.setTokenProvider` (Bearer token), `Http.setTokenRefreshCallback` (one retry after a 401), `Http.setOnUnauthorizedCallback` (401 again after refresh → force sign-out). `Http.hasToken` guards auth-gated calls. For an action that needs a signed-in user, call `requireAuth(context)` (`utils/auth_gate.dart`): it returns true when a token exists, otherwise runs the sign-in flow the app registers with `AuthGate.setSignInHandler` (open a sign-in modal through `ModalProvider`, complete with the outcome).

### Providers

Global providers registered in `main.dart` via `MultiProvider`:
- `ErrorProvider` — global toast (`show(message, level:)` with `info` / `success` / `warning` / `error`, auto-dismiss 3 s info and success / 5 s otherwise), rendered by `ErrorToastCard`
- `ConnectivityProvider` — `isOffline`, rendered by `OfflineBanner`; `ConnectivityProvider.withState(offline:)` in tests
- `ModalProvider` — `show(widget)` / `dismiss()`, rendered by `ModalConsumer` in the ShellRoute; pair it with `AppModal`

Rules:
- No `addListener()` inside `create:` lambdas. If providers come to depend on each other, wire them in one place after `runApp()`.
- Providers doing async work extend `BaseAsyncProvider` and call `notify()` (dispose-safe).
- Consume providers with `renderConsumer<T>()` / `renderSelector<T, S>()` from `providers/_base/consumer.dart`.
- Language is owned by EasyLocalization (`context.setLocale`, persisted automatically) — no separate language provider.

### Routing

Uses `go_router`. Routes are declared in `routing/router/router.dart` under a `ShellRoute` (adds `AppHeader` + `ModalConsumer`). Unknown locations render `NotFoundPage` outside the shell. Route builders validate path params (non-numeric `/todos/:id` → 404).

To expose a page in the header, add a `NavItem` to `data/nav_items.dart` and the matching `GoRoute`.

Pages (`routing/pages/`) are thin: a template plus the render widget(s) it hosts. No state, no service calls. Every template draws a `PageTitleBar` (title, optional back button calling `onBack`, optional `trailing` action):
- `FullPageTemplate(title:, child:)` — one panel, body unscrolled (bounded height, capped at `kContentMaxWidth`): lists, `Listing`, screens that scroll themselves.
- `SplittedPageTemplate(title:, primary:, secondary:, primaryWidth: 400)` — two panels side by side from `kSplitBreakpoint` (840 dp, measured on the template), stacked half / half below; both panels unscrolled (detail + map, list + preview).
- `FollowUpPageTemplate(title:, onBack:, child:, actions:)` — page reached after an action: back button always shown, padded scrolling body capped at `kContentMaxWidth`, next-step `actions` pinned at the bottom.

**Navigation rules:**
- Always use `context.go()` — never `context.push()`. This is a URL-driven app; `push()` stacks history entries and breaks back-button behavior.
- Dialogs are mounted with `ModalProvider.show(AppModal(...))`, not `Navigator.push` / `showDialog`.
- Bottom sheets: `custom/` sheets are content-only (no drag handle, no provider / service / `context.go`). The host mounts them with `showModalBottomSheet(showDragHandle: true, …)` or `ModalProvider.show(AppModal(...))` and reacts to their callbacks. See `lib/widgets/custom/README.md`.
- Guards: add a `redirect` to `createRouter()` and pass the providers it reads as `refreshListenable`.
- `Layout` (installed by `MaterialApp.router.builder`) sits **above** the Navigator: widgets rendered there have no `Overlay` (no `Tooltip`, no `PopupMenuButton`).

### Localization

Handled by `EasyLocalization`. Supported locales and asset path live in `data/locales.dart` (French fallback + English).

- **Canonical reference:** `fr.json` — every other locale must match its key set exactly (enforced by `test/unit/translations_test.dart`).
- **Import rule:** `easy_localization` must be imported in the parent `index.dart`, not in `view.dart` (part files have no imports).
- **Parametric keys** use `namedArgs`: `"todo.user".tr(namedArgs: <String, String>{"id": "$id"})` → `"Utilisateur n°{id}"`.
- Never hardcode user-visible strings in widgets.

### Theme

`theme/app_theme.dart` builds Material 3 light and dark themes from one seed colour (`AppTheme.seed`, `#3B7054`); `main.dart` uses both (`ThemeMode.system`). Tests use the same `AppTheme.light()`.

**Never hardcode colours in widgets.** Always read `ColorScheme` tokens (`cs.primary`, `cs.surface`, `cs.onSurface`, `cs.onSurfaceVariant`, `cs.outlineVariant`, `cs.error`, `cs.errorContainer`, …) so both brightnesses stay correct.

Status colours come from the `StatusTones` theme extension (`theme/status_tones.dart`, registered by `AppTheme`): `StatusTones.colorsOf(context, StatusTone.success)` returns `ToneColors(foreground, container, onContainer)` for `neutral`, `primary`, `info`, `success`, `warning`, `danger` (each ≥ 4.5:1, enforced by `test/unit/theme/status_tones_test.dart`). `StatusTone.icon` gives the non-colour cue. Widgets never declare their own tone enums; theme files are the only place hex values live.

Spacing follows an 8 dp grid: use `kDefaultPadding` multiples, `kSectionGap` between sections, `kContentMaxWidth` for centred content (`widgets/constants.dart`).

### Motion

Every animation resolves its duration with `resolveMotion(context, duration)`, which returns `Duration.zero` when the platform asks to reduce motion (`MediaQuery.disableAnimationsOf`). Page transitions skip their animation in the same case.

| Animation | Duration | Curve |
|---|---|---|
| Banner / toast | 250 ms (`kMotionShort`) | `easeOutCubic` |
| Modal | 260 ms | `easeOutCubic` |
| Page fade | 180 ms | `easeOut` |
| Page fade + slide up | 200 ms | `easeOut` |
| Skeleton pulse | 1500 ms | linear ping-pong |

### Accessibility

- All interactive elements ≥ 48×48 dp tap target (`kMinTapTarget`, WCAG 2.5.8)
- `Semantics(label: ...)` on informative and interactive components without visible text
- `Semantics(liveRegion: true)` for dynamic status announcements (offline banner, toasts)
- Status colours always paired with a text label — never colour-alone coding

## Automated gates (Claude Code hooks)

Hooks in `.claude/settings.json` run automatically when Claude Code finishes a turn:

| Event | Command | Blocks on |
|---|---|---|
| `Stop` | `bash tooling/hooks/test-gate.sh` | analyze errors, custom_lint errors, unit or widget test failures |

The gate exits immediately when nothing under `lib/`, `test/`, `cli/`, `assets/`, `pubspec.yaml` or `analysis_options.yaml` changed in the working tree. Run it manually with `--force`.

Exit codes: 0 = green, 2 = red (Claude Code continues until the gate passes), 3 = unknown flag. Timeout is 300 s.
