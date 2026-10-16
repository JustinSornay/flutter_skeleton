# utils/

Small, dependency-light helpers with no UI and no domain knowledge. Look here
before writing a helper; add one here only when two places need it.

| File | Content |
|---|---|
| `env.dart` | `Env.get` / `flag` / `intOr`: crash-free reads of `.env.local` (never throws, even before `dotenv.load`). |
| `load_state.dart` | `LoadState<T>` (`Idle`, `Loading`, `Loaded`, `LoadError`): lifecycle of a data fetch, rendered with an exhaustive `switch`. |
| `action_state.dart` | `ActionState` (`idle`, `loading`, `success`, `error`): lifecycle of a one-shot action that returns no data to show (export, share, upload). |
| `auth_gate.dart` | `requireAuth(context)`: true when `Http.hasToken`, otherwise runs the sign-in flow registered with `AuthGate.setSignInHandler` (none ships with the skeleton). |
| `coords.dart` | `Coords.snapToGrid` / `formatKey`: snap lat / lon to a decimal grid and build the `"lat_lon"` cache-key segment (3 decimals by default). |
| `geo/polygon_area.dart` | `geodesicAreaHectares(List<LatLng>)`: geodesic polygon area on the WGS84 sphere (matches PostGIS `ST_Area(geography)`). |
| `parsers/coordinates_parser.dart` | `parseCoordinates("lat,lon")` → `LatLng?` (null on any invalid input), `formatCoordinates(lat, lon)` → `"46.50°N  2.30°E"`. |
| `parsers/string_parser.dart` | `StringParser.fromSnake` / `fromCamel` / `fromPascal` → `toSnake()` / `toCamel()` / `toPascal()`: identifier case conversion (API field names ↔ Dart names). |
| `builders/file_path_builder.dart` | `FilePathBuilder`: fluent, platform-aware file system path builder (export or cache paths). |
| `extensions/enum_extensions.dart` | `Enum.values.by(test, orElse:)`: concise enum lookup. |
| `extensions/future_extensions.dart` | `future.withErrorLog("Service.method")`: logs then rethrows, the shorthand for the service try / catch. |
| `logger/command_filter.dart` | `Logger` filter that lets every event through (cold start, before the `LOGGER_*` env flags are loaded). |

Rules:

- Pure Dart where possible; a `BuildContext` only when the helper must reach
  the widget tree (`requireAuth`).
- No provider, service or widget imports (`auth_gate.dart` only reads
  `Http.hasToken`).
- A new helper comes with a unit test under `test/unit/utils/`.
