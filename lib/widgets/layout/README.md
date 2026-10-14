# widgets/layout/

**Layout widgets** are the persistent components that form the application
shell: header, global modals, overlays, and banners. They are shared across all
pages, either through `Layout` (installed by `MaterialApp.router.builder`) or
through GoRouter's `ShellRoute`.

## Principle

1. **It persists beyond a single page.** `AppHeader` stays mounted for the
   whole shell. `OfflineBanner` is always present, even when invisible.
2. **It manages global or cross-page state.** Connectivity, global errors,
   modals — events not tied to any specific page.
3. **It never resizes content behind an overlay.** Modals float above content
   (`Stack`), they never shift it.

## Difference from `custom/`

| `layout/` | `custom/` |
|---|---|
| Mounted once, shared by all pages | Instantiated on demand inside a page |
| Handles global events (offline, errors, modals) | Responds to local props |
| Driven by global providers | Receives data through parameters |

## Components

| Widget | Mounted by | Driven by |
|---|---|---|
| `Layout` (`layout.dart`) | `MaterialApp.router.builder` | — |
| `OfflineBanner` | `Layout` | `ConnectivityProvider` |
| `ErrorToastCard` | `Layout` | `ErrorProvider` |
| `AppHeader` | `ShellRoute` | GoRouter location + `data/nav_items.dart` |
| `ModalConsumer` | `ShellRoute` | `ModalProvider` |
| `AppModal` | callers, via `ModalProvider.show()` | `isVisible` |
| `PageTitleBar` | `FullPageTemplate` | parameters |

`Layout` sits **above** the Navigator: anything it renders has no `Overlay`
ancestor (no `Tooltip`, no `PopupMenuButton`). `AppHeader` and
`ModalConsumer` live inside the `ShellRoute`, under the Navigator, so they can.

## Rules

- A layout widget **contains no business logic**. It observes and reacts.
- Every animation goes through `resolveMotion()` (reduced-motion support).
- Same MVVM `part` / `part of` structure as the rest of the app;
  `ErrorToastCard` is a single file by exception (no lifecycle).
