# utils/

Small, dependency-light helpers with no UI and no domain knowledge. Look here
before writing a helper.

| File | Content |
|---|---|
| `env.dart` | `Env.get` / `flag` / `intOr`: crash-free reads of `.env.local` (never throws, even before `dotenv.load`). |
| `load_state.dart` | `LoadState<T>` (`Idle`, `Loading`, `Loaded`, `LoadError`): lifecycle of a data fetch, rendered with an exhaustive `switch`. |
| `action_state.dart` | `ActionState` (`idle`, `loading`, `success`, `error`): lifecycle of a one-shot action that returns no data to show (export, share, upload). |
| `auth_gate.dart` | `requireAuth(context)`: true when `Http.hasToken`, otherwise runs the sign-in flow registered with `AuthGate.setSignInHandler` (none ships with the skeleton) and returns `Http.hasToken` once it ends. Concurrent calls share one flow. |
| `coords.dart` | `Coords.snapToGrid` / `formatKey`: snap lat / lon to a decimal grid and build the `"lat_lon"` cache-key segment (3 decimals by default). |
| `geo/polygon_area.dart` | `geodesicAreaHectares(List<LatLng>)`: geodesic polygon area on the WGS84 sphere, within ~0.3 % of PostGIS `ST_Area(geography)`; the smaller side of the ring (polar caps work, polygons over a hemisphere do not). |
| `geo/polygon_shape.dart` | `hasCrossingEdges(List<LatLng>)`: whether two non-adjacent edges of the closed ring cross or touch (exact, no tolerance), in planar lon / lat; do not repeat the first vertex; false below 4 vertices. |
| `geo/geojson.dart` | `polygonToGeoJson(List<LatLng>)` → GeoJSON Polygon geometry (`[lon, lat]`, ring closed once; `ArgumentError` below 3 vertices or out of range), `geoJsonOuterRings(Object?)` → open outer rings of a Polygon / MultiPolygon / Feature / FeatureCollection (holes ignored, never throws). |
| `geo/compass_point.dart` | `CompassPoint` (8 points): `fromBearing(degrees)` (45° sectors centred on each point), `between(from, to)` (initial great-circle bearing). No labels: translate `point.name`. |
| `parsers/coordinates_parser.dart` | `parseCoordinates("lat,lon")` → `LatLng?` (null when blank, malformed, non-finite or out of range), `formatCoordinates(lat, lon)` → `"46.50°N  2.30°E"` (not localised). |
| `parsers/string_parser.dart` | `StringParser.fromSnake` / `fromCamel` / `fromPascal` → `toSnake()` / `toCamel()` / `toPascal()`: identifier case conversion (API field names ↔ Dart names). |
| `formatters/byte_size.dart` | `ByteSize.of(bytes, locale:)` → `key` (`common.byte_units.b` / `kb` / `mb` / `gb`, 1024 steps) + locale-formatted `value`; translate with `size.key.tr(namedArgs: size.namedArgs)`. |
| `builders/file_path_builder.dart` | `FilePathBuilder`: `dart:io` path builder (platform separator, `..` cascades), used by the `cli/` generators; not for web code. |
| `extensions/enum_extensions.dart` | `MyEnum.values.by(test, orElse:)`: first value matching a predicate (for a name lookup use the SDK's `values.byName` / `asNameMap()`). |
| `extensions/future_extensions.dart` | `future.withErrorLog("Service.method")`: logs then rethrows, the shorthand for the service try / catch. |
| `logger/command_filter.dart` | `CommandFilter`: `Logger` filter that prints every event, used by the `cli/` generators. |

Rules:

- Generic only: no entity, DTO or product rule. A helper that only one
  widget needs stays in that widget's `controllers/`.
- Pure Dart where possible; a `BuildContext` only when the helper must reach
  the widget tree (`requireAuth`).
- No provider, service or widget imports (`auth_gate.dart` only reads
  `Http.hasToken`).
- Logic comes with a unit test under `test/unit/utils/` (plain enums and
  typedefs excepted).
