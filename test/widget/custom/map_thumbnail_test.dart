// map_thumbnail_test.dart
//
// Widget tests for MapThumbnail: constructor presets, box geometry, map
// options (centre, zoom, no gestures, background), the host tile layer,
// the default MapPin and its anchoring, a custom pin, semantics, pointer
// pass-through, camera updates (with the provider lifecycle of a TileLayer
// built per host build), failing tiles, a dark-theme smoke test and the real
// default label (argument order, rounding, locale decimal separator) through
// an in-memory EasyLocalization. Tiles come from an in-memory TileProvider, so
// no network is used. The localized tests reset the easy_localization
// singleton, so the raw-key tests pass in any order.

import "package:easy_localization/easy_localization.dart";
// Localization.load is the only way to empty the translations singleton that
// EasyLocalization fills; see _pumpLocalized.
// ignore: implementation_imports
import "package:easy_localization/src/localization.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/custom/MapPin/index.dart";
import "package:flutter_skeleton/widgets/custom/MapThumbnail/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:latlong2/latlong.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _kLabelKey = "custom.map_thumbnail.semantics";

/// 1×1 transparent PNG.
final Uint8List _kTransparentPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// Serves every tile from memory (no network), counts the requests and
/// records its disposal.
final class _MemoryTileProvider extends TileProvider {
  int requests = 0;
  bool disposed = false;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    requests++;
    return MemoryImage(_kTransparentPng);
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

/// Image that always fails to load.
final class _BrokenImage extends ImageProvider<_BrokenImage> {
  const _BrokenImage();

  @override
  Future<_BrokenImage> obtainKey(ImageConfiguration configuration) {
    return Future<_BrokenImage>.value(this);
  }

  @override
  ImageStreamCompleter loadImage(_BrokenImage key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(Future<ImageInfo>.error(StateError("tile unavailable")));
  }
}

/// Every tile fails to load.
final class _BrokenTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return const _BrokenImage();
  }
}

TileLayer _tileLayer([_MemoryTileProvider? provider]) {
  return TileLayer(
    urlTemplate: "https://tiles.example.test/{z}/{x}/{y}.png",
    userAgentPackageName: "com.example.test",
    tileProvider: provider ?? _MemoryTileProvider(),
  );
}

Future<void> _pump(WidgetTester tester, Widget thumbnail, {ThemeData? theme}) {
  return pumpApp(tester, Center(child: thumbnail), theme: theme);
}

/// In-memory translations matching the widget's i18n fragment, so the real
/// label can be checked before the fragment is merged into assets.
final class _MemoryLoader extends AssetLoader {
  const _MemoryLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final bool fr = locale.languageCode == "fr";
    return <String, dynamic>{
      "custom": <String, dynamic>{
        "map_thumbnail": <String, dynamic>{
          "semantics": fr
              ? "Aperçu de carte : latitude {lat}, longitude {lon}"
              : "Map preview: latitude {lat}, longitude {lon}",
        },
      },
    };
  }
}

/// Pumps [thumbnail] under EasyLocalization at [locale]. The loaded
/// translations live in a singleton that outlives the test; the tear-down
/// empties it so every later `.tr()` returns the raw key again.
Future<void> _pumpLocalized(WidgetTester tester, Locale locale, Widget thumbnail) async {
  addTearDown(() => Localization.load(const Locale("fr")));
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale("fr"), Locale("en")],
      path: "memory",
      fallbackLocale: const Locale("fr"),
      startLocale: locale,
      saveLocale: false,
      assetLoader: const _MemoryLoader(),
      child: Builder(
        builder: (BuildContext context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.light(),
          home: Scaffold(body: Center(child: thumbnail)),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

MapOptions _options(WidgetTester tester) {
  return tester.widget<FlutterMap>(find.byType(FlutterMap)).options;
}

MapCamera _camera(WidgetTester tester) {
  return MapCamera.of(tester.element(find.byType(TileLayer)));
}

void main() {
  group("constructors", () {
    test("default preset is 48 × 40, radius 6, zoom 11", () {
      final MapThumbnail thumbnail = MapThumbnail(lat: 48.86, lon: 2.35, tileLayer: _tileLayer());
      expect(thumbnail.lat, 48.86);
      expect(thumbnail.lon, 2.35);
      expect(thumbnail.width, 48);
      expect(thumbnail.height, 40);
      expect(thumbnail.borderRadius, 6);
      expect(thumbnail.zoom, 11);
    });

    test("large preset is 56 × 56, radius 8", () {
      final MapThumbnail thumbnail = MapThumbnail.large(lat: 43.32, lon: 1.95, tileLayer: _tileLayer(), zoom: 9);
      expect(thumbnail.lat, 43.32);
      expect(thumbnail.lon, 1.95);
      expect(thumbnail.width, 56);
      expect(thumbnail.height, 56);
      expect(thumbnail.borderRadius, 8);
      expect(thumbnail.zoom, 9);
    });
  });

  group("layout", () {
    testWidgets("box has the preset size and corner radius", (WidgetTester tester) async {
      await _pump(tester, MapThumbnail(lat: 48.86, lon: 2.35, tileLayer: _tileLayer()));
      expect(tester.getSize(find.byType(MapThumbnail)), const Size(48, 40));
      final ClipRRect clip = tester.widget<ClipRRect>(
        find.descendant(of: find.byType(MapThumbnail), matching: find.byType(ClipRRect)),
      );
      expect(clip.borderRadius, BorderRadius.circular(6));
    });

    testWidgets("large preset lays out at 56 × 56, radius 8", (WidgetTester tester) async {
      await _pump(tester, MapThumbnail.large(lat: 43.32, lon: 1.95, tileLayer: _tileLayer()));
      expect(tester.getSize(find.byType(MapThumbnail)), const Size(56, 56));
      final ClipRRect clip = tester.widget<ClipRRect>(
        find.descendant(of: find.byType(MapThumbnail), matching: find.byType(ClipRRect)),
      );
      expect(clip.borderRadius, BorderRadius.circular(8));
    });

    testWidgets("custom width, height and radius are honoured", (WidgetTester tester) async {
      await _pump(
        tester,
        MapThumbnail(lat: 0, lon: 0, tileLayer: _tileLayer(), width: 120, height: 64, borderRadius: 12),
      );
      expect(tester.getSize(find.byType(MapThumbnail)), const Size(120, 64));
      final ClipRRect clip = tester.widget<ClipRRect>(
        find.descendant(of: find.byType(MapThumbnail), matching: find.byType(ClipRRect)),
      );
      expect(clip.borderRadius, BorderRadius.circular(12));
    });
  });

  group("map", () {
    testWidgets("is centred on the coordinate at the zoom, with no gestures", (WidgetTester tester) async {
      await _pump(tester, MapThumbnail(lat: 48.86, lon: 2.35, tileLayer: _tileLayer(), zoom: 13));
      final MapOptions options = _options(tester);
      expect(options.initialCenter, const LatLng(48.86, 2.35));
      expect(options.initialZoom, 13);
      expect(options.interactionOptions.flags, InteractiveFlag.none);
      expect(_camera(tester).center, const LatLng(48.86, 2.35));
      expect(_camera(tester).zoom, 13);
    });

    testWidgets("background defaults to surfaceContainerHighest", (WidgetTester tester) async {
      await _pump(tester, MapThumbnail(lat: 0, lon: 0, tileLayer: _tileLayer()));
      final ColorScheme cs = AppTheme.light().colorScheme;
      expect(_options(tester).backgroundColor, cs.surfaceContainerHighest);
    });

    testWidgets("backgroundColor overrides the default", (WidgetTester tester) async {
      final Color custom = AppTheme.light().colorScheme.tertiaryContainer;
      await _pump(tester, MapThumbnail(lat: 0, lon: 0, tileLayer: _tileLayer(), backgroundColor: custom));
      expect(_options(tester).backgroundColor, custom);
    });

    testWidgets("renders the host tile layer and its provider serves the tiles", (WidgetTester tester) async {
      final _MemoryTileProvider provider = _MemoryTileProvider();
      final TileLayer layer = _tileLayer(provider);
      await _pump(tester, MapThumbnail(lat: 48.86, lon: 2.35, tileLayer: layer));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byWidget(layer), findsOneWidget);
      expect(provider.requests, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets("new centre or zoom recentres the camera", (WidgetTester tester) async {
      // A new TileLayer per build, as the dartdoc asks of hosts.
      final _MemoryTileProvider first = _MemoryTileProvider();
      await _pump(tester, MapThumbnail(lat: 48.86, lon: 2.35, tileLayer: _tileLayer(first)));
      expect(_camera(tester).center, const LatLng(48.86, 2.35));

      final _MemoryTileProvider second = _MemoryTileProvider();
      await _pump(tester, MapThumbnail(lat: 43.32, lon: 1.95, tileLayer: _tileLayer(second), zoom: 8));
      await tester.pump(const Duration(milliseconds: 300));
      expect(_camera(tester).center, const LatLng(43.32, 1.95));
      expect(_camera(tester).zoom, 8);
      // The remounted map serves the new layer; the old map disposed its own.
      expect(first.disposed, isTrue);
      expect(second.disposed, isFalse);
      expect(second.requests, greaterThan(0));
    });

    testWidgets("unchanged centre keeps the map and its provider", (WidgetTester tester) async {
      final _MemoryTileProvider first = _MemoryTileProvider();
      await _pump(tester, MapThumbnail(lat: 48.86, lon: 2.35, tileLayer: _tileLayer(first)));
      final State<FlutterMap> before = tester.state<State<FlutterMap>>(find.byType(FlutterMap));

      await _pump(tester, MapThumbnail(lat: 48.86, lon: 2.35, tileLayer: _tileLayer()));
      expect(tester.state<State<FlutterMap>>(find.byType(FlutterMap)), same(before));
      expect(first.disposed, isFalse);
    });

    testWidgets("failing tiles throw nothing and reach the host's errorTileCallback", (WidgetTester tester) async {
      int errors = 0;
      final DebugPrintCallback originalDebugPrint = debugPrint;
      // flutter_map debugPrints every tile error; keep the test output clean.
      debugPrint = (String? message, {int? wrapWidth}) {};
      try {
        await _pump(
          tester,
          MapThumbnail(
            lat: 48.86,
            lon: 2.35,
            tileLayer: TileLayer(
              urlTemplate: "https://tiles.example.test/{z}/{x}/{y}.png",
              userAgentPackageName: "com.example.test",
              tileProvider: _BrokenTileProvider(),
              errorTileCallback: (TileImage tile, Object error, StackTrace? stackTrace) => errors++,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
      } finally {
        debugPrint = originalDebugPrint;
      }
      expect(tester.takeException(), isNull);
      expect(errors, greaterThan(0));
      expect(find.byType(MapPin), findsOneWidget);
    });
  });

  group("pointer", () {
    testWidgets("a drag leaves the camera where it was", (WidgetTester tester) async {
      await _pump(tester, MapThumbnail.large(lat: 48.86, lon: 2.35, tileLayer: _tileLayer()));
      await tester.drag(find.byType(MapThumbnail), const Offset(20, 20), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(_camera(tester).center, const LatLng(48.86, 2.35));
      expect(_options(tester).interactionOptions.flags, InteractiveFlag.none);
      expect(tester.takeException(), isNull);
    });

    testWidgets("taps reach a host gesture detector", (WidgetTester tester) async {
      int taps = 0;
      await _pump(
        tester,
        GestureDetector(
          onTap: () => taps++,
          child: MapThumbnail(lat: 48.86, lon: 2.35, tileLayer: _tileLayer()),
        ),
      );
      await tester.tap(find.byType(MapThumbnail));
      await tester.pump(const Duration(milliseconds: 300));
      expect(taps, 1);
    });

    testWidgets("a drag over it scrolls the parent list", (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);
      await pumpApp(
        tester,
        ListView(
          controller: controller,
          children: <Widget>[
            MapThumbnail.large(lat: 48.86, lon: 2.35, tileLayer: _tileLayer()),
            const SizedBox(height: 2000),
          ],
        ),
      );
      await tester.drag(find.byType(MapThumbnail), const Offset(0, -100));
      await tester.pump(const Duration(milliseconds: 300));
      expect(controller.offset, greaterThan(0));
    });
  });

  group("pin", () {
    testWidgets("default MapPin has its tip on the centre", (WidgetTester tester) async {
      await _pump(tester, MapThumbnail(lat: 48.86, lon: 2.35, tileLayer: _tileLayer()));
      final Finder pin = find.byType(MapPin);
      expect(pin, findsOneWidget);
      expect(tester.widget<MapPin>(pin).size, MapThumbnail.defaultPinSize);
      final Rect box = tester.getRect(find.byType(MapThumbnail));
      final Rect pinRect = tester.getRect(pin);
      expect(pinRect.size, MapThumbnail.defaultPinSize);
      expect(pinRect.bottomCenter, box.center);
      // The head and its 1.5 dp outline stay inside the 40 dp box.
      expect(pinRect.top - box.top, greaterThanOrEqualTo(2));
    });

    testWidgets("default pin follows the theme (primary fill)", (WidgetTester tester) async {
      await _pump(tester, MapThumbnail(lat: 0, lon: 0, tileLayer: _tileLayer()));
      final MapPin pin = tester.widget<MapPin>(find.byType(MapPin));
      expect(pin.color, isNull);
      expect(pin.outlineColor, isNull);
    });

    testWidgets("a custom pin replaces MapPin and is anchored by its bottom centre", (WidgetTester tester) async {
      const Key key = Key("pin");
      await _pump(
        tester,
        MapThumbnail.large(
          lat: 0,
          lon: 0,
          tileLayer: _tileLayer(),
          pin: const SizedBox(key: key, width: 10, height: 10),
        ),
      );
      expect(find.byType(MapPin), findsNothing);
      final Rect box = tester.getRect(find.byType(MapThumbnail));
      expect(tester.getRect(find.byKey(key)).bottomCenter, box.center);
    });

    testWidgets("SizedBox.shrink hides the pin", (WidgetTester tester) async {
      await _pump(tester, MapThumbnail(lat: 0, lon: 0, tileLayer: _tileLayer(), pin: const SizedBox.shrink()));
      expect(find.byType(MapPin), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group("semantics", () {
    testWidgets("default label is one image node; map internals are excluded", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, MapThumbnail(lat: 48.86, lon: 2.35, tileLayer: _tileLayer()));
      final Finder label = find.bySemanticsLabel(_kLabelKey);
      expect(label, findsOneWidget);
      expect(
        tester.getSemantics(label),
        isSemantics(label: _kLabelKey, isImage: true),
      );
      expect(find.bySemanticsLabel("custom.map_pin.label"), findsNothing);
      handle.dispose();
    });

    testWidgets("semanticLabel is used verbatim", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        MapThumbnail(lat: 48.86, lon: 2.35, tileLayer: _tileLayer(), semanticLabel: "Preview of the place"),
      );
      expect(find.bySemanticsLabel("Preview of the place"), findsOneWidget);
      expect(find.bySemanticsLabel(_kLabelKey), findsNothing);
      handle.dispose();
    });

    testWidgets("en label puts lat then lon, rounded to 4 decimals", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(
        tester,
        const Locale("en"),
        MapThumbnail(lat: -33.86882, lon: 151.2093, tileLayer: _tileLayer()),
      );
      expect(find.bySemanticsLabel("Map preview: latitude -33.8688, longitude 151.2093"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("fr label uses the locale decimal comma", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(
        tester,
        const Locale("fr"),
        MapThumbnail(lat: -33.86882, lon: 151.2093, tileLayer: _tileLayer()),
      );
      expect(find.bySemanticsLabel("Aperçu de carte : latitude -33,8688, longitude 151,2093"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("trailing zeros are dropped", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("en"), MapThumbnail(lat: 48.5, lon: 2, tileLayer: _tileLayer()));
      expect(find.bySemanticsLabel("Map preview: latitude 48.5, longitude 2"), findsOneWidget);
      handle.dispose();
    });
  });

  testWidgets("dark theme smoke test", (WidgetTester tester) async {
    final ThemeData dark = AppTheme.dark();
    await _pump(tester, MapThumbnail.large(lat: 48.86, lon: 2.35, tileLayer: _tileLayer()), theme: dark);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.byType(MapPin), findsOneWidget);
    expect(_options(tester).backgroundColor, dark.colorScheme.surfaceContainerHighest);
  });
}
