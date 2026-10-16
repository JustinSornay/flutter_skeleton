// editable_value_row_test.dart
//
// Widget tests for EditableValueRow: structure, subtitle visibility and
// style, the edit label override, overflow in a narrow row, the chip's
// semantics (raw keys, explicit label, merged into the host's InkWell, real
// fr / en strings), the presentational contract (the host owns the tap) and
// the ColorScheme tokens (texts, icons, decorations) under the dark theme.
// Order-independent: localized tests restore raw keys when they finish.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/EditableValueRow/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _editKey = "custom.editable_value_row.edit";
const String _semanticsKey = "custom.editable_value_row.edit_semantics";

Finder _inRow(Finder matching) {
  return find.descendant(of: find.byType(EditableValueRow), matching: matching);
}

/// The chip's Semantics widget (the only one flagged as a button).
Semantics _chipSemantics(WidgetTester tester) {
  return tester.widget<Semantics>(
    _inRow(find.byWidgetPredicate((Widget w) => w is Semantics && (w.properties.button ?? false))),
  );
}

Text _text(WidgetTester tester, String data) => tester.widget<Text>(find.text(data));

/// The closest decorated Container around [icon] (the badge or the chip).
Finder _decorated(IconData icon) {
  return find.ancestor(of: find.byIcon(icon), matching: find.byType(Container)).first;
}

/// In-memory translations matching the widget's i18n fragment, so the real
/// strings can be checked before the fragment is merged into assets. With
/// [empty], it loads no strings at all, so `.tr()` returns raw keys again.
final class _MemoryLoader extends AssetLoader {
  /// True loads an empty table (used to restore raw-key mode).
  final bool empty;

  const _MemoryLoader({this.empty = false});

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    if (empty) return <String, dynamic>{};
    final bool fr = locale.languageCode == "fr";
    return <String, dynamic>{
      "custom": <String, dynamic>{
        "editable_value_row": <String, dynamic>{
          "edit": fr ? "Modifier" : "Edit",
          "edit_semantics": fr ? "{action} : {value}" : "{action}: {value}",
        },
      },
    };
  }
}

Future<void> _pumpEasyLocalization(WidgetTester tester, Locale locale, _MemoryLoader loader, Widget child) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      // A fresh state each time, so the new loader is actually used.
      key: UniqueKey(),
      supportedLocales: const <Locale>[Locale("fr"), Locale("en")],
      path: "memory",
      fallbackLocale: const Locale("fr"),
      startLocale: locale,
      saveLocale: false,
      assetLoader: loader,
      child: Builder(
        builder: (BuildContext context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.light(),
          home: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps [child] with the in-memory [locale] strings and runs [body]. `.tr()`
/// reads EasyLocalization's global singleton, which outlives the test; the
/// `finally` reloads an empty table (even when [body] fails) so the raw-key
/// tests pass whatever order the tests run in.
Future<void> _withLocalized(WidgetTester tester, Locale locale, Widget child, void Function() body) async {
  try {
    await _pumpEasyLocalization(tester, locale, const _MemoryLoader(), child);
    body();
  } finally {
    await _pumpEasyLocalization(tester, locale, const _MemoryLoader(empty: true), const SizedBox.shrink());
  }
}

void main() {
  group("structure", () {
    testWidgets("renders the icon, the title, the edit icon and the default label", (WidgetTester tester) async {
      await pumpApp(tester, const EditableValueRow(icon: Icons.place_outlined, title: "Bordeaux"));

      expect(find.byIcon(Icons.place_outlined), findsOneWidget);
      expect(find.text("Bordeaux"), findsOneWidget);
      expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
      expect(find.text(_editKey), findsOneWidget);
      final Text title = _text(tester, "Bordeaux");
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
      expect(title.style?.fontSize, 15);
      expect(title.style?.fontWeight, FontWeight.w700);
    });

    testWidgets("hides the subtitle and its gap when it is null", (WidgetTester tester) async {
      await pumpApp(tester, const EditableValueRow(icon: Icons.place_outlined, title: "Bordeaux"));

      expect(_inRow(find.byType(Text)), findsNWidgets(2)); // title + chip label
      expect(_inRow(find.byWidgetPredicate((Widget w) => w is SizedBox && w.height == kDefaultPadding / 4)), findsNothing);
    });

    testWidgets("hides the subtitle and its gap when it is empty", (WidgetTester tester) async {
      await pumpApp(tester, const EditableValueRow(icon: Icons.place_outlined, title: "Bordeaux", subtitle: ""));

      expect(_inRow(find.byType(Text)), findsNWidgets(2));
      expect(find.text(""), findsNothing);
      expect(_inRow(find.byWidgetPredicate((Widget w) => w is SizedBox && w.height == kDefaultPadding / 4)), findsNothing);
    });

    testWidgets("renders the subtitle upright by default", (WidgetTester tester) async {
      await pumpApp(tester, const EditableValueRow(icon: Icons.place_outlined, title: "Bordeaux", subtitle: "44.84, -0.58"));

      expect(_inRow(find.byType(Text)), findsNWidgets(3));
      final Text subtitle = _text(tester, "44.84, -0.58");
      expect(subtitle.maxLines, 1);
      expect(subtitle.overflow, TextOverflow.ellipsis);
      expect(subtitle.style?.fontStyle, FontStyle.normal);
    });

    testWidgets("subtitleItalic renders the subtitle in italic", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const EditableValueRow(icon: Icons.science_outlined, title: "Sample", subtitle: "Genus species", subtitleItalic: true),
      );

      expect(_text(tester, "Genus species").style?.fontStyle, FontStyle.italic);
    });

    testWidgets("editLabel replaces the default chip text", (WidgetTester tester) async {
      await pumpApp(tester, const EditableValueRow(icon: Icons.place_outlined, title: "Bordeaux", editLabel: "Change"));

      expect(find.text("Change"), findsOneWidget);
      expect(find.text(_editKey), findsNothing);
    });

    testWidgets("long texts ellipsize in a narrow row without overflowing", (WidgetTester tester) async {
      final String long = List<String>.filled(30, "word").join(" ");
      await pumpApp(
        tester,
        Center(
          child: SizedBox(
            width: 200,
            child: EditableValueRow(icon: Icons.place_outlined, title: long, subtitle: long, editLabel: "Edit"),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(long), findsNWidgets(2));
      for (final Text text in tester.widgetList<Text>(find.text(long))) {
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
      }
      expect(tester.getSize(find.byType(EditableValueRow)).width, 200);
    });
  });

  group("semantics", () {
    testWidgets("the chip is a button with the explicit label and excludes its own text", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const EditableValueRow(icon: Icons.place_outlined, title: "Bordeaux", editLabel: "Change", semanticsLabel: "Change the place"),
      );

      final Semantics chip = _chipSemantics(tester);
      expect(chip.properties.label, "Change the place");
      expect(chip.excludeSemantics, isTrue);
      expect(find.descendant(of: find.byWidget(chip), matching: find.text("Change")), findsOneWidget);
    });

    testWidgets("the default label is the parametric key", (WidgetTester tester) async {
      await pumpApp(tester, const EditableValueRow(icon: Icons.place_outlined, title: "Bordeaux"));

      expect(_chipSemantics(tester).properties.label, _semanticsKey);
    });

    testWidgets("inside a host InkWell the row reads as one tappable button", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        InkWell(
          onTap: () {},
          child: const Padding(
            padding: EdgeInsets.all(kDefaultPadding * 2),
            child: EditableValueRow(
              icon: Icons.place_outlined,
              title: "Bordeaux",
              subtitle: "Gironde",
              editLabel: "Change",
              semanticsLabel: "Change the place",
            ),
          ),
        ),
      );

      final SemanticsNode node = tester.getSemantics(find.byType(EditableValueRow));
      final SemanticsData data = node.getSemanticsData();
      expect(data.label, contains("Bordeaux"));
      expect(data.label, contains("Gironde"));
      expect(data.label, contains("Change the place"));
      expect(data.label.split("\n"), isNot(contains("Change")));
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });
  });

  group("presentational contract", () {
    testWidgets("has no gesture of its own", (WidgetTester tester) async {
      await pumpApp(tester, const EditableValueRow(icon: Icons.place_outlined, title: "Bordeaux", subtitle: "Gironde"));

      expect(_inRow(find.byType(InkWell)), findsNothing);
      expect(_inRow(find.byType(GestureDetector)), findsNothing);
    });

    testWidgets("tapping the chip or the title calls the host InkWell once each", (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(
        tester,
        InkWell(
          onTap: () => taps++,
          child: const EditableValueRow(icon: Icons.place_outlined, title: "Bordeaux"),
        ),
      );

      await tester.tap(find.text(_editKey));
      await tester.pump(kThemeAnimationDuration);
      expect(taps, 1);

      await tester.tap(find.text("Bordeaux"));
      await tester.pump(kThemeAnimationDuration);
      expect(taps, 2);
    });
  });

  testWidgets("uses ColorScheme tokens under the dark theme", (WidgetTester tester) async {
    final ThemeData theme = AppTheme.dark();
    final ColorScheme cs = theme.colorScheme;
    await pumpApp(
      tester,
      const EditableValueRow(icon: Icons.place_outlined, title: "Bordeaux", subtitle: "Gironde"),
      theme: theme,
    );

    expect(tester.takeException(), isNull);
    expect(_text(tester, "Bordeaux").style?.color, cs.onSurface);
    expect(_text(tester, "Gironde").style?.color, cs.onSurfaceVariant);
    expect(_text(tester, _editKey).style?.color, cs.primary);
    expect(tester.widget<Icon>(find.byIcon(Icons.place_outlined)).color, cs.primary);
    expect(tester.widget<Icon>(find.byIcon(Icons.edit_rounded)).color, cs.primary);

    final Finder badge = _decorated(Icons.place_outlined);
    final BoxDecoration badgeDecoration = tester.widget<Container>(badge).decoration! as BoxDecoration;
    expect(badgeDecoration.color, cs.primary.withValues(alpha: 0.07));
    expect(badgeDecoration.borderRadius, BorderRadius.circular(10));
    expect(tester.getSize(badge), const Size(32, 32));

    final Finder chip = _decorated(Icons.edit_rounded);
    final BoxDecoration chipDecoration = tester.widget<Container>(chip).decoration! as BoxDecoration;
    expect(chipDecoration.color, cs.surfaceContainerHighest);
    expect(chipDecoration.borderRadius, BorderRadius.circular(8));
    expect(tester.getSize(chip).height, greaterThanOrEqualTo(32));
  });

  // Each test restores raw-key mode in _withLocalized, so order is free.
  group("localized", () {
    testWidgets("fr: default chip text and semantics label", (WidgetTester tester) async {
      await _withLocalized(tester, const Locale("fr"), const EditableValueRow(icon: Icons.place_outlined, title: "Bordeaux"), () {
        expect(find.text("Modifier"), findsOneWidget);
        expect(_chipSemantics(tester).properties.label, "Modifier : Bordeaux");
      });
    });

    testWidgets("fr: a custom editLabel stays in the semantics label", (WidgetTester tester) async {
      await _withLocalized(
        tester,
        const Locale("fr"),
        const EditableValueRow(icon: Icons.place_outlined, title: "Bordeaux", editLabel: "Changer"),
        () {
          expect(find.text("Changer"), findsOneWidget);
          expect(_chipSemantics(tester).properties.label, "Changer : Bordeaux");
        },
      );
    });

    testWidgets("en: default chip text and semantics label", (WidgetTester tester) async {
      await _withLocalized(tester, const Locale("en"), const EditableValueRow(icon: Icons.place_outlined, title: "Bordeaux"), () {
        expect(find.text("Edit"), findsOneWidget);
        expect(_chipSemantics(tester).properties.label, "Edit: Bordeaux");
      });
    });

    // Design choice, pinned on purpose: the default chip label names the
    // value, so a host InkWell's merged node reads the title twice.
    testWidgets("fr: inside a host InkWell the default merged label repeats the title", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await _withLocalized(
          tester,
          const Locale("fr"),
          InkWell(
            onTap: () {},
            child: const Padding(
              padding: EdgeInsets.all(kDefaultPadding * 2),
              child: EditableValueRow(icon: Icons.place_outlined, title: "Bordeaux", subtitle: "Gironde"),
            ),
          ),
          () {
            final SemanticsData data = tester.getSemantics(find.byType(EditableValueRow)).getSemanticsData();
            expect(data.label, "Bordeaux\nGironde\nModifier : Bordeaux");
            expect(data.flagsCollection.isButton, isTrue);
            expect(data.hasAction(SemanticsAction.tap), isTrue);
          },
        );
      } finally {
        handle.dispose();
      }
    });
  });
}
