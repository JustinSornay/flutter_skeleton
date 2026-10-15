// ranked_list_test.dart
//
// Widget tests for RankedList: empty state (default and custom text, no
// header, no list), header (title + count, trailing slot, hidden), rows
// (order, explicit rank, detail, score pill and tone, trailing icon, taps),
// the active row (fill, border, badge, selected semantics), layout (height
// cap, shrink-wrap, scrolling, a single scrollbar on desktop, 48 dp rows,
// long texts), semantics labels (raw keys and real strings in English and
// French), the dark theme and dispose safety.

import "package:easy_localization/easy_localization.dart" hide TextDirection;
// ignore: implementation_imports
import "package:easy_localization/src/localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/RankedList/index.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _countKey = "custom.ranked_list.count";
const String _emptyKey = "custom.ranked_list.empty";
const String _itemKey = "custom.ranked_list.item_semantics";
const String _title = "SHORTLIST";
const String _badge = "ACTIVE";

const List<RankedListEntry<String>> _three = <RankedListEntry<String>>[
  RankedListEntry<String>(value: "a", label: "Alpha", score: 0.85, tone: StatusTone.success),
  RankedListEntry<String>(value: "b", label: "Beta", score: 0.62, tone: StatusTone.warning, detail: "Second"),
  RankedListEntry<String>(value: "c", label: "Gamma"),
];

List<RankedListEntry<String>> _many(int count) {
  return <RankedListEntry<String>>[
    for (int i = 1; i <= count; i++) RankedListEntry<String>(value: "v$i", label: "Item $i", score: i / count),
  ];
}

/// Tap handler of the tests that do not check taps.
void _ignore(String value) {}

RankedList<String> _list({
  List<RankedListEntry<String>> entries = _three,
  ValueChanged<String>? onItemTap,
  String? activeValue,
  String? activeBadgeLabel,
  String? title = _title,
  Widget? headerTrailing,
}) {
  return RankedList<String>(
    entries: entries,
    onItemTap: onItemTap ?? _ignore,
    activeValue: activeValue,
    activeBadgeLabel: activeBadgeLabel,
    title: title,
    headerTrailing: headerTrailing,
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
        "ranked_list": <String, dynamic>{
          "count": "({count})",
          "empty": fr ? "Aucun élément à afficher." : "No items to display.",
          "item_semantics": fr ? "Rang {rank} : {label}" : "Rank {rank}: {label}",
        },
      },
    };
  }
}

/// Pumps [list] under EasyLocalization with the in-memory translations. The
/// tear-down empties the translation singleton so later `.tr()` calls return
/// the raw key again, whatever the test order.
Future<void> _pumpLocalized(WidgetTester tester, Locale locale, Widget list) async {
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
          home: Scaffold(body: list),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Nearest Material of the row showing [label] (the row surface).
Material _rowMaterial(WidgetTester tester, String label) {
  return tester.widget<Material>(find.ancestor(of: find.text(label), matching: find.byType(Material)).first);
}

/// Semantics node of the row showing [label].
Finder _rowSemantics(String label) {
  return find
      .ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((Widget w) => w is Semantics && w.properties.button == true),
      )
      .first;
}

BorderSide _rowSide(WidgetTester tester, String label) {
  return (_rowMaterial(tester, label).shape! as RoundedRectangleBorder).side;
}

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(RankedList<String>))).colorScheme;

BuildContext _context(WidgetTester tester) => tester.element(find.byType(RankedList<String>));

void main() {
  group("empty", () {
    testWidgets("shows the default message, without header or list", (WidgetTester tester) async {
      await pumpApp(tester, _list(entries: const <RankedListEntry<String>>[], headerTrailing: const Text("slot")));

      expect(find.text(_emptyKey), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.text(_title), findsNothing);
      expect(find.text("slot"), findsNothing);
    });

    testWidgets("shows a custom message", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const RankedList<String>(entries: <RankedListEntry<String>>[], onItemTap: _ignore, emptyLabel: "Nothing yet"),
      );

      expect(find.text("Nothing yet"), findsOneWidget);
      expect(find.text(_emptyKey), findsNothing);
    });
  });

  group("header", () {
    testWidgets("renders the title as a semantic header followed by the count", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _list());

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_countKey), findsOneWidget);
      expect(tester.getTopLeft(find.text(_countKey)).dx, greaterThan(tester.getTopLeft(find.text(_title)).dx));
      expect(tester.getSemantics(find.text(_title)), isSemantics(label: _title, isHeader: true));
      handle.dispose();
    });

    testWidgets("renders the trailing slot at the right end", (WidgetTester tester) async {
      await pumpApp(tester, _list(headerTrailing: const Text("slot")));

      expect(find.text("slot"), findsOneWidget);
      expect(tester.getTopRight(find.text("slot")).dx, greaterThan(tester.getTopRight(find.text(_countKey)).dx));
    });

    testWidgets("shows the trailing slot without title or count", (WidgetTester tester) async {
      await pumpApp(tester, _list(title: null, headerTrailing: const Text("slot")));

      expect(find.text("slot"), findsOneWidget);
      expect(find.text(_countKey), findsNothing);
    });

    testWidgets("is absent without title and trailing slot", (WidgetTester tester) async {
      await pumpApp(tester, _list(title: null));

      expect(find.text(_countKey), findsNothing);
      expect(find.text("Alpha"), findsOneWidget);
    });

    // Real strings: without EasyLocalization the count shows its raw key,
    // which is far longer than the real "(n)".
    testWidgets("keeps a long title on one line without overflow", (WidgetTester tester) async {
      await _pumpLocalized(
        tester,
        const Locale("en"),
        SizedBox(width: 240, child: _list(title: "A VERY LONG HEADER TITLE " * 6, headerTrailing: const Text("slot"))),
      );

      expect(tester.takeException(), isNull);
      expect(find.text("slot"), findsOneWidget);
      expect(find.text("(3)"), findsOneWidget);
    });
  });

  group("rows", () {
    testWidgets("renders ranks and labels in the given order", (WidgetTester tester) async {
      await pumpApp(tester, _list());

      for (final String rank in <String>["1", "2", "3"]) {
        expect(find.text(rank), findsOneWidget);
      }
      final double alpha = tester.getTopLeft(find.text("Alpha")).dy;
      final double beta = tester.getTopLeft(find.text("Beta")).dy;
      final double gamma = tester.getTopLeft(find.text("Gamma")).dy;
      expect(alpha, lessThan(beta));
      expect(beta, lessThan(gamma));
      expect(tester.getCenter(find.text("1")).dy, closeTo(tester.getCenter(find.text("Alpha")).dy, 1));
    });

    testWidgets("uses the entry's own rank when set", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _list(
          entries: const <RankedListEntry<String>>[
            RankedListEntry<String>(value: "x", label: "Tenth", rank: 10),
            RankedListEntry<String>(value: "y", label: "Second"),
          ],
        ),
      );

      expect(find.text("10"), findsOneWidget);
      expect(find.text("2"), findsOneWidget);
      expect(find.text("1"), findsNothing);
    });

    testWidgets("fits a three-digit rank inside the circle", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _list(entries: const <RankedListEntry<String>>[RankedListEntry<String>(value: "x", label: "Far", rank: 128)]),
      );

      expect(tester.takeException(), isNull);
      final Rect circle = tester.getRect(
        find.ancestor(of: find.text("128"), matching: find.byType(DecoratedBox)).first,
      );
      final Rect text = tester.getRect(find.text("128"));
      expect(circle.contains(text.topLeft) && circle.contains(text.bottomRight - const Offset(0.1, 0.1)), isTrue);
    });

    testWidgets("shows the detail line only when set", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _list(
          entries: const <RankedListEntry<String>>[
            RankedListEntry<String>(value: "a", label: "Alpha", detail: "More"),
            RankedListEntry<String>(value: "b", label: "Beta", detail: ""),
          ],
        ),
      );

      expect(find.text("More"), findsOneWidget);
      expect(tester.getTopLeft(find.text("More")).dy, greaterThan(tester.getTopLeft(find.text("Alpha")).dy));
      expect(find.text(""), findsNothing);
    });

    testWidgets("shows the score as a percentage pill in the entry tone", (WidgetTester tester) async {
      await pumpApp(tester, _list());

      final StatusPill alpha = tester.widget<StatusPill>(find.widgetWithText(StatusPill, "85%"));
      expect(alpha.tone, StatusTone.success);
      expect(alpha.dense, isTrue);
      expect(tester.widget<StatusPill>(find.widgetWithText(StatusPill, "62%")).tone, StatusTone.warning);
      expect(find.byType(StatusPill), findsNWidgets(2));

      final BuildContext context = _context(tester);
      expect(
        tester.widget<Text>(find.text("85%")).style?.color,
        StatusTones.colorsOf(context, StatusTone.success).onContainer,
      );
      expect(
        tester.widget<Text>(find.text("62%")).style?.color,
        StatusTones.colorsOf(context, StatusTone.warning).onContainer,
      );
    });

    testWidgets("hides the score when it is null or not finite", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _list(
          entries: const <RankedListEntry<String>>[
            RankedListEntry<String>(value: "a", label: "Alpha"),
            RankedListEntry<String>(value: "b", label: "Beta", score: double.nan),
            RankedListEntry<String>(value: "c", label: "Gamma", score: double.infinity),
          ],
        ),
      );

      expect(find.byType(StatusPill), findsNothing);
    });

    testWidgets("draws the default trailing icon on every row", (WidgetTester tester) async {
      await pumpApp(tester, _list());

      expect(find.byIcon(Icons.swap_horiz), findsNWidgets(3));
    });

    testWidgets("draws a custom trailing icon, or none", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const RankedList<String>(entries: _three, onItemTap: _ignore, trailingIcon: Icons.chevron_right),
      );
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));
      expect(find.byIcon(Icons.swap_horiz), findsNothing);

      await pumpApp(tester, const RankedList<String>(entries: _three, onItemTap: _ignore, trailingIcon: null));
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets("calls onItemTap with the tapped row's value", (WidgetTester tester) async {
      final List<String> taps = <String>[];
      await pumpApp(tester, _list(onItemTap: taps.add));

      await tester.tap(find.text("Beta"));
      await tester.tap(find.byIcon(Icons.swap_horiz).last);
      await tester.tap(find.text("85%"));
      await tester.pump();

      expect(taps, <String>["b", "c", "a"]);
    });

    testWidgets("uses the inactive row colours", (WidgetTester tester) async {
      await pumpApp(tester, _list());

      final ColorScheme cs = _scheme(tester);
      expect(_rowMaterial(tester, "Alpha").color, cs.surfaceContainerLow);
      expect(_rowSide(tester, "Alpha").color, cs.outlineVariant);
      expect(tester.widget<Text>(find.text("Alpha")).style?.color, cs.onSurface);
      expect(tester.widget<Text>(find.text("1")).style?.color, cs.onTertiaryContainer);
    });
  });

  group("active row", () {
    testWidgets("highlights only the matching row with the tertiary accent", (WidgetTester tester) async {
      await pumpApp(tester, _list(activeValue: "b", activeBadgeLabel: _badge));

      final ColorScheme cs = _scheme(tester);
      expect(_rowMaterial(tester, "Beta").color, cs.tertiaryContainer);
      expect(_rowSide(tester, "Beta").color, cs.tertiary);
      expect(tester.widget<Text>(find.text("Beta")).style?.color, cs.onTertiaryContainer);
      expect(tester.widget<Text>(find.text("2")).style?.color, cs.onTertiary);
      expect(_rowMaterial(tester, "Alpha").color, cs.surfaceContainerLow);
      expect(_rowSide(tester, "Gamma").color, cs.outlineVariant);
    });

    testWidgets("shows the badge inside the active row only", (WidgetTester tester) async {
      await pumpApp(tester, _list(activeValue: "a", activeBadgeLabel: _badge));

      expect(find.text(_badge), findsOneWidget);
      final Finder activeRow = find.ancestor(of: find.text("Alpha"), matching: find.byType(Material)).first;
      expect(find.descendant(of: activeRow, matching: find.text(_badge)), findsOneWidget);
      expect(tester.widget<Text>(find.text(_badge)).style?.color, _scheme(tester).tertiary);
    });

    testWidgets("shows no badge when the label is null or empty", (WidgetTester tester) async {
      await pumpApp(tester, _list(activeValue: "a"));
      expect(find.text(_badge), findsNothing);
      expect(_rowMaterial(tester, "Alpha").color, _scheme(tester).tertiaryContainer);

      await pumpApp(tester, _list(activeValue: "a", activeBadgeLabel: ""));
      expect(find.text(""), findsNothing);
    });

    testWidgets("has no active row when the value matches nothing", (WidgetTester tester) async {
      await pumpApp(tester, _list(activeValue: "zzz", activeBadgeLabel: _badge));

      expect(find.text(_badge), findsNothing);
      for (final String label in <String>["Alpha", "Beta", "Gamma"]) {
        expect(_rowMaterial(tester, label).color, _scheme(tester).surfaceContainerLow);
      }
    });

    testWidgets("keeps a long badge from overflowing the row", (WidgetTester tester) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 280,
          child: _list(title: null, activeValue: "a", activeBadgeLabel: "A VERY LONG BADGE LABEL " * 4),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group("layout", () {
    testWidgets("caps a long list at maxHeight and scrolls", (WidgetTester tester) async {
      await pumpApp(tester, _list(entries: _many(20)));

      expect(tester.getSize(find.byType(ListView)).height, lessThanOrEqualTo(194));
      final ScrollableState scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scrollable.position.maxScrollExtent, greaterThan(0));

      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, closeTo(scrollable.position.maxScrollExtent, 0.01));
      expect(find.text("Item 20"), findsOneWidget);
      expect(find.text("Item 1"), findsNothing);
    });

    testWidgets("honours a custom maxHeight", (WidgetTester tester) async {
      await pumpApp(tester, RankedList<String>(entries: _many(20), onItemTap: _ignore, maxHeight: 120));

      expect(tester.getSize(find.byType(ListView)).height, 120);
    });

    testWidgets("shrink-wraps a short list", (WidgetTester tester) async {
      await pumpApp(tester, _list(entries: _three.take(2).toList()));

      expect(tester.getSize(find.byType(ListView)).height, lessThan(194));
      expect(tester.state<ScrollableState>(find.byType(Scrollable)).position.maxScrollExtent, 0);
    });

    testWidgets(
      "paints a single always-visible scrollbar on desktop",
      (WidgetTester tester) async {
        await pumpApp(tester, _list(entries: _many(20)));
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull);
        expect(find.byType(Scrollbar), findsOneWidget);
        expect(tester.widget<Scrollbar>(find.byType(Scrollbar)).thumbVisibility, isTrue);

        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.linux),
    );

    testWidgets("makes every row at least 48 dp tall", (WidgetTester tester) async {
      await pumpApp(tester, _list());

      for (final String label in <String>["Alpha", "Beta", "Gamma"]) {
        final Finder ink = find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first;
        expect(tester.getSize(ink).height, greaterThanOrEqualTo(kMinTapTarget));
      }
    });

    testWidgets("ellipsises long labels and details without overflow", (WidgetTester tester) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 260,
          child: _list(
            title: null,
            activeValue: "a",
            activeBadgeLabel: _badge,
            entries: <RankedListEntry<String>>[
              RankedListEntry<String>(value: "a", label: "Long label " * 10, detail: "Long detail " * 10, score: 1),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets("rebuilds with new entries", (WidgetTester tester) async {
      await pumpApp(tester, _list());
      await pumpApp(tester, _list(entries: _many(2)));

      expect(find.text("Alpha"), findsNothing);
      expect(find.text("Item 2"), findsOneWidget);
    });

    testWidgets("disposes its scroll controller cleanly", (WidgetTester tester) async {
      await pumpApp(tester, _list(entries: _many(20)));
      await pumpApp(tester, const SizedBox.shrink());

      expect(tester.takeException(), isNull);
    });
  });

  group("semantics", () {
    testWidgets("announces each row as a button with rank, label, detail and score", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _list());

      expect(
        tester.getSemantics(_rowSemantics("Beta")),
        isSemantics(label: "$_itemKey, Second, 62%", isButton: true, isSelected: false, hasTapAction: true),
      );
      expect(tester.getSemantics(_rowSemantics("Gamma")), isSemantics(label: _itemKey, isButton: true));
      handle.dispose();
    });

    testWidgets("marks the active row as selected and reads its badge", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _list(activeValue: "a", activeBadgeLabel: _badge));

      expect(
        tester.getSemantics(_rowSemantics("Alpha")),
        isSemantics(label: "$_itemKey, 85%, $_badge", isButton: true, isSelected: true),
      );
      handle.dispose();
    });

    testWidgets("uses the entry's semanticsLabel when set", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        _list(
          entries: const <RankedListEntry<String>>[
            RankedListEntry<String>(value: "a", label: "Alpha", score: 0.5, semanticsLabel: "Custom reading"),
          ],
        ),
      );

      expect(tester.getSemantics(_rowSemantics("Alpha")), isSemantics(label: "Custom reading", isButton: true));
      handle.dispose();
    });

    testWidgets("activates the row from the semantics tap action", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<String> taps = <String>[];
      await pumpApp(tester, _list(onItemTap: taps.add));

      tester.semantics.tap(find.semantics.byLabel("$_itemKey, 85%"));
      await tester.pump();

      expect(taps, <String>["a"]);
      handle.dispose();
    });

    testWidgets("renders the real English strings", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("en"), _list(activeValue: "a", activeBadgeLabel: _badge));

      expect(find.text("(3)"), findsOneWidget);
      expect(find.text("85%"), findsOneWidget);
      expect(
        tester.getSemantics(_rowSemantics("Alpha")),
        isSemantics(label: "Rank 1: Alpha, 85%, $_badge"),
      );
      handle.dispose();
    });

    testWidgets("renders the real French strings with the French percent format", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("fr"), _list());

      final String percent = NumberFormat.percentPattern("fr").format(0.85);
      expect(percent, isNot("85%"));
      expect(find.text(percent), findsOneWidget);
      expect(tester.getSemantics(_rowSemantics("Alpha")), isSemantics(label: "Rang 1 : Alpha, $percent"));
      handle.dispose();
    });

    testWidgets("renders the real empty message", (WidgetTester tester) async {
      await _pumpLocalized(tester, const Locale("en"), _list(entries: const <RankedListEntry<String>>[]));

      expect(find.text("No items to display."), findsOneWidget);
    });
  });

  group("theme", () {
    testWidgets("renders under the dark theme with dark tokens", (WidgetTester tester) async {
      await pumpApp(tester, _list(activeValue: "b", activeBadgeLabel: _badge), theme: AppTheme.dark());

      expect(tester.takeException(), isNull);
      final ColorScheme cs = _scheme(tester);
      expect(cs.brightness, Brightness.dark);
      expect(_rowMaterial(tester, "Beta").color, cs.tertiaryContainer);
      expect(_rowMaterial(tester, "Alpha").color, cs.surfaceContainerLow);
      expect(
        tester.widget<Text>(find.text("85%")).style?.color,
        StatusTones.colorsOf(_context(tester), StatusTone.success).onContainer,
      );
    });
  });
}
