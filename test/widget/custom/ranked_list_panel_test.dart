// ranked_list_panel_test.dart
//
// Widget tests for RankedListPanel: the surface (colour, elevation, top
// radius), the grip (shown, hidden, excluded from semantics), the title
// (shown, hidden, header), the rows (order, explicit and positional rank,
// label, detail, chevron, taps with a typed value), the leading icon (tone
// tint, neutral default, per-entry override, hidden), layout (48 dp rows,
// narrow width, label / detail width sharing, 128 dp detail cap, untruncated
// three-digit rank), semantics (one childless button node per row, raw key,
// custom label, real English and French strings) and the dark theme.

import "package:easy_localization/easy_localization.dart" hide TextDirection;
// ignore: implementation_imports
import "package:easy_localization/src/localization.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart" show RenderParagraph, SemanticsNode;
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/RankedListPanel/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _rankKey = "custom.ranked_list_panel.rank";
const String _title = "TOP RESULTS";

const List<RankedListEntry<String>> _three = <RankedListEntry<String>>[
  RankedListEntry<String>(value: "a", label: "85 %", detail: "12 km N", tone: StatusTone.success),
  RankedListEntry<String>(value: "b", label: "52 %", detail: "30 km E", tone: StatusTone.warning),
  RankedListEntry<String>(value: "c", label: "21 %", tone: StatusTone.danger),
];

/// Tap handler of the tests that do not check taps.
void _ignore(String value) {}

RankedListPanel<String> _panel({
  List<RankedListEntry<String>> entries = _three,
  ValueChanged<String>? onTap,
  String? title = _title,
  IconData? icon = Icons.star_border_rounded,
  bool showHandle = true,
}) {
  return RankedListPanel<String>(
    entries: entries,
    onTap: onTap ?? _ignore,
    title: title,
    icon: icon,
    showHandle: showHandle,
  );
}

/// In-memory translations matching the widget's i18n fragment, so the real
/// strings can be checked before the fragment is merged into assets.
final class _MemoryLoader extends AssetLoader {
  const _MemoryLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final bool fr = locale.languageCode == "fr";
    return <String, dynamic>{
      "custom": <String, dynamic>{
        "ranked_list_panel": <String, dynamic>{"rank": fr ? "Rang {rank}" : "Rank {rank}"},
      },
    };
  }
}

/// Pumps [panel] under EasyLocalization with the in-memory translations. The
/// tear-down empties the translation singleton so later `.tr()` calls return
/// the raw key again, whatever the test order.
Future<void> _pumpLocalized(WidgetTester tester, Locale locale, Widget panel) async {
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
          home: Scaffold(body: panel),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The grip box (32 x 4 dp).
final Finder _grip = find.byWidgetPredicate(
  (Widget w) => w is SizedBox && w.width == kDefaultPadding * 4 && w.height == kDefaultPadding / 2,
);

/// InkWell of the row showing [label].
Finder _row(String label) => find.ancestor(of: find.text(label), matching: find.byType(InkWell));

/// Leading icon of the row showing [label].
Icon _leadingIcon(WidgetTester tester, String label, IconData glyph) {
  return tester.widget<Icon>(find.descendant(of: _row(label), matching: find.byIcon(glyph)));
}

/// Outer Material of the panel.
Material _surface(WidgetTester tester) {
  return tester.widget<Material>(
    find.descendant(of: find.byType(RankedListPanel<String>), matching: find.byType(Material)).first,
  );
}

BuildContext _context(WidgetTester tester) => tester.element(find.byType(RankedListPanel<String>));

void main() {
  _surfaceTests();
  _headerTests();
  _rowTests();
  _iconTests();
  _layoutTests();
  _semanticsTests();
  _themeTests();
}

void _surfaceTests() {
  group("surface", () {
    testWidgets("is an elevated surfaceContainerLow Material with 16 dp top corners", (WidgetTester tester) async {
      await pumpApp(tester, _panel());

      final Material surface = _surface(tester);
      final ColorScheme cs = Theme.of(_context(tester)).colorScheme;
      expect(surface.color, cs.surfaceContainerLow);
      expect(surface.shadowColor, cs.shadow);
      expect(surface.elevation, 6);
      expect(surface.borderRadius, const BorderRadius.vertical(top: Radius.circular(16)));
    });
  });
}

void _headerTests() {
  group("header", () {
    testWidgets("shows the grip by default, out of the semantics tree", (WidgetTester tester) async {
      await pumpApp(tester, _panel());

      expect(_grip, findsOneWidget);
      expect(find.ancestor(of: _grip, matching: find.byType(ExcludeSemantics)), findsWidgets);
    });

    testWidgets("showHandle false removes the grip", (WidgetTester tester) async {
      await pumpApp(tester, _panel(showHandle: false));

      expect(_grip, findsNothing);
      expect(find.text("85 %"), findsOneWidget);
    });

    testWidgets("shows the title as given and announces it as a header", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _panel());

      expect(find.text(_title), findsOneWidget);
      expect(tester.getSemantics(find.text(_title)), isSemantics(label: _title, isHeader: true));
      handle.dispose();
    });

    testWidgets("hides the title when null", (WidgetTester tester) async {
      await pumpApp(tester, _panel(title: null));

      expect(find.text(_title), findsNothing);
      expect(find.text("85 %"), findsOneWidget);
    });

    testWidgets("an empty list renders the grip and the title only", (WidgetTester tester) async {
      await pumpApp(tester, _panel(entries: const <RankedListEntry<String>>[]));

      expect(tester.takeException(), isNull);
      expect(_grip, findsOneWidget);
      expect(find.text(_title), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });
  });
}

void _rowTests() {
  group("rows", () {
    testWidgets("renders the rows in order with label, detail and chevron", (WidgetTester tester) async {
      await pumpApp(tester, _panel());

      expect(find.byType(InkWell), findsNWidgets(3));
      expect(find.text("12 km N"), findsOneWidget);
      expect(find.text("30 km E"), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(3));
      expect(tester.getTopLeft(find.text("85 %")).dy, lessThan(tester.getTopLeft(find.text("52 %")).dy));
      expect(tester.getTopLeft(find.text("52 %")).dy, lessThan(tester.getTopLeft(find.text("21 %")).dy));
    });

    testWidgets("hides a null or empty detail", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _panel(
          entries: const <RankedListEntry<String>>[
            RankedListEntry<String>(value: "a", label: "First", detail: ""),
            RankedListEntry<String>(value: "b", label: "Second"),
          ],
        ),
      );

      expect(find.descendant(of: _row("First"), matching: find.byType(Text)), findsNWidgets(2));
      expect(find.descendant(of: _row("Second"), matching: find.byType(Text)), findsNWidgets(2));
    });

    testWidgets("ranks rows by position when no rank is set", (WidgetTester tester) async {
      await pumpApp(tester, _panel());

      expect(find.descendant(of: _row("85 %"), matching: find.text("1")), findsOneWidget);
      expect(find.descendant(of: _row("52 %"), matching: find.text("2")), findsOneWidget);
      expect(find.descendant(of: _row("21 %"), matching: find.text("3")), findsOneWidget);
    });

    testWidgets("uses the entry rank when set", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _panel(
          entries: const <RankedListEntry<String>>[
            RankedListEntry<String>(value: "a", label: "First", rank: 4),
            RankedListEntry<String>(value: "b", label: "Second"),
          ],
        ),
      );

      expect(find.descendant(of: _row("First"), matching: find.text("4")), findsOneWidget);
      expect(find.descendant(of: _row("Second"), matching: find.text("2")), findsOneWidget);
    });

    testWidgets("tapping a row calls onTap once with its value", (WidgetTester tester) async {
      final List<String> taps = <String>[];
      await pumpApp(tester, _panel(onTap: taps.add));

      await tester.tap(find.text("52 %"));
      await tester.pump();

      expect(taps, <String>["b"]);
    });

    testWidgets("hands back a typed record payload", (WidgetTester tester) async {
      final List<({int id, String name})> taps = <({int id, String name})>[];
      await pumpApp(
        tester,
        RankedListPanel<({int id, String name})>(
          entries: const <RankedListEntry<({int id, String name})>>[
            RankedListEntry<({int id, String name})>(value: (id: 7, name: "seven"), label: "Seven"),
          ],
          onTap: taps.add,
        ),
      );

      await tester.tap(find.text("Seven"));
      await tester.pump();

      expect(taps, <({int id, String name})>[(id: 7, name: "seven")]);
    });
  });
}

void _iconTests() {
  group("leading icon", () {
    testWidgets("is tinted with the tone foreground of each entry", (WidgetTester tester) async {
      await pumpApp(tester, _panel());

      final BuildContext context = _context(tester);
      const IconData star = Icons.star_border_rounded;
      expect(_leadingIcon(tester, "85 %", star).color, StatusTones.colorsOf(context, StatusTone.success).foreground);
      expect(_leadingIcon(tester, "52 %", star).color, StatusTones.colorsOf(context, StatusTone.warning).foreground);
      expect(_leadingIcon(tester, "21 %", star).color, StatusTones.colorsOf(context, StatusTone.danger).foreground);
    });

    testWidgets("the default neutral tone uses onSurfaceVariant", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _panel(entries: const <RankedListEntry<String>>[RankedListEntry<String>(value: "a", label: "Plain")]),
      );

      final ColorScheme cs = Theme.of(_context(tester)).colorScheme;
      expect(_leadingIcon(tester, "Plain", Icons.star_border_rounded).color, cs.onSurfaceVariant);
    });

    testWidgets("an entry icon overrides the panel icon", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _panel(
          entries: const <RankedListEntry<String>>[
            RankedListEntry<String>(value: "a", label: "Own", icon: Icons.place, tone: StatusTone.info),
            RankedListEntry<String>(value: "b", label: "Shared"),
          ],
        ),
      );

      final BuildContext context = _context(tester);
      expect(_leadingIcon(tester, "Own", Icons.place).color, StatusTones.colorsOf(context, StatusTone.info).foreground);
      expect(find.descendant(of: _row("Own"), matching: find.byIcon(Icons.star_border_rounded)), findsNothing);
      expect(find.descendant(of: _row("Shared"), matching: find.byIcon(Icons.star_border_rounded)), findsOneWidget);
    });

    testWidgets("a null panel icon leaves only the chevron", (WidgetTester tester) async {
      await pumpApp(tester, _panel(icon: null));

      expect(find.descendant(of: _row("85 %"), matching: find.byType(Icon)), findsOneWidget);
      expect(find.byIcon(Icons.star_border_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(3));
    });
  });
}

void _layoutTests() {
  group("layout", () {
    testWidgets("every row is at least kMinTapTarget tall", (WidgetTester tester) async {
      await pumpApp(tester, _panel());

      for (final String label in <String>["85 %", "52 %", "21 %"]) {
        expect(tester.getSize(_row(label)).height, greaterThanOrEqualTo(kMinTapTarget));
      }
    });

    testWidgets("long texts ellipsise at a narrow width without overflow", (WidgetTester tester) async {
      final String long = List<String>.filled(30, "word").join(" ");
      await pumpApp(
        tester,
        _panel(
          entries: <RankedListEntry<String>>[RankedListEntry<String>(value: "a", label: long, detail: long)],
        ),
        surfaceSize: const Size(260, 400),
      );

      expect(tester.takeException(), isNull);
      expect(tester.widgetList<Text>(find.text(long)).every((Text t) => t.overflow == TextOverflow.ellipsis), isTrue);
    });

    testWidgets("a long detail never squeezes the label out at 200 dp", (WidgetTester tester) async {
      final String long = List<String>.filled(30, "word").join(" ");
      await pumpApp(
        tester,
        _panel(
          entries: <RankedListEntry<String>>[RankedListEntry<String>(value: "a", label: "Short", detail: long)],
        ),
        surfaceSize: const Size(200, 400),
      );

      expect(tester.takeException(), isNull);
      final double label = tester.getSize(find.text("Short")).width;
      expect(label, greaterThan(0));
      expect(tester.getSize(find.text(long)).width, lessThanOrEqualTo(label));
    });

    testWidgets("a short detail sits by the chevron and leaves the rest to the label", (WidgetTester tester) async {
      await pumpApp(tester, _panel());

      final Rect row = tester.getRect(_row("85 %"));
      final Rect label = tester.getRect(find.text("85 %"));
      final Rect detail = tester.getRect(find.text("12 km N"));
      final Rect chevron = tester.getRect(
        find.descendant(of: _row("85 %"), matching: find.byIcon(Icons.chevron_right_rounded)),
      );
      expect(chevron.right, row.right - kDefaultPadding / 2);
      expect(detail.right, chevron.left - kDefaultPadding / 2);
      expect(label.right, detail.left - kDefaultPadding);
    });

    testWidgets("a long detail is capped at 128 dp on a wide row", (WidgetTester tester) async {
      final String long = List<String>.filled(30, "word").join(" ");
      await pumpApp(
        tester,
        _panel(
          entries: <RankedListEntry<String>>[RankedListEntry<String>(value: "a", label: "Short", detail: long)],
        ),
      );

      expect(tester.getSize(find.text(long)).width, lessThanOrEqualTo(kDefaultPadding * 16));
    });

    testWidgets("a three-digit rank is drawn in full, clear of the icon", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _panel(entries: const <RankedListEntry<String>>[RankedListEntry<String>(value: "a", label: "Far", rank: 100)]),
      );

      expect(tester.takeException(), isNull);
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(find.text("100"));
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(paragraph.size.width, greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(double.infinity)));
      final Rect rank = tester.getRect(find.text("100"));
      final Rect icon = tester.getRect(find.byIcon(Icons.star_border_rounded));
      expect(rank.right, lessThanOrEqualTo(icon.left));
    });
  });
}

void _semanticsTests() {
  group("semantics", () {
    testWidgets("each row is one button with rank, label and detail", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _panel());

      final SemanticsNode row = tester.getSemantics(find.bySemanticsLabel("$_rankKey — 85 % — 12 km N"));
      expect(row, isSemantics(isButton: true, hasTapAction: true));
      expect(row.childrenCount, 0);
      expect(find.bySemanticsLabel("$_rankKey — 21 %"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("the semantics tap action calls onTap", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<String> taps = <String>[];
      await pumpApp(tester, _panel(onTap: taps.add));

      tester.semantics.tap(find.semantics.byLabel("$_rankKey — 52 % — 30 km E"));
      await tester.pump();

      expect(taps, <String>["b"]);
      handle.dispose();
    });

    testWidgets("semanticsLabel replaces the default label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        _panel(
          entries: const <RankedListEntry<String>>[
            RankedListEntry<String>(value: "a", label: "85 %", detail: "12 km N", semanticsLabel: "Best match"),
          ],
        ),
      );

      expect(find.bySemanticsLabel("Best match"), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(_rankKey)), findsNothing);
      handle.dispose();
    });

    testWidgets("uses the real English string", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("en"), _panel());

      expect(find.bySemanticsLabel("Rank 1 — 85 % — 12 km N"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("uses the real French string", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("fr"), _panel());

      expect(find.bySemanticsLabel("Rang 2 — 52 % — 30 km E"), findsOneWidget);
      handle.dispose();
    });
  });
}

void _themeTests() {
  group("theme", () {
    testWidgets("renders under the dark theme with dark tone colours", (WidgetTester tester) async {
      await pumpApp(tester, _panel(), theme: AppTheme.dark());

      expect(tester.takeException(), isNull);
      final BuildContext context = _context(tester);
      final ColorScheme cs = Theme.of(context).colorScheme;
      expect(cs.brightness, Brightness.dark);
      expect(_surface(tester).color, cs.surfaceContainerLow);
      expect(
        _leadingIcon(tester, "85 %", Icons.star_border_rounded).color,
        StatusTones.colorsOf(context, StatusTone.success).foreground,
      );
    });
  });
}
