// trend_split_section_test.dart
//
// Tests for TrendSplitSection: the pure defaultFormat (signed one-decimal
// percentage, locale aware, unsigned when it rounds to zero), entries in
// their column, the value-driven sign and arrow, default and custom titles,
// the empty placeholder, dividers, a custom format, the composed StatusPill
// tones (and the higherIsBetter swap), header and pill icons, semantics, a
// narrow parent, a large text scale in phone-width hosts, the ambient locale
// and the dark theme.

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";
import "package:flutter_skeleton/widgets/custom/TrendSplitSection/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const List<TrendEntry> _rising = <TrendEntry>[
  TrendEntry(label: "Alpha", delta: 0.18),
  TrendEntry(label: "Beta", delta: 0.12),
];

const List<TrendEntry> _falling = <TrendEntry>[
  TrendEntry(label: "Gamma", delta: -0.14),
  TrendEntry(label: "Delta", delta: -0.11),
];

const String _risingKey = "custom.trend_split_section.rising";
const String _fallingKey = "custom.trend_split_section.falling";
const String _emptyKey = "custom.trend_split_section.empty";

/// The left (rising) card: the Expanded holding the trending_up header icon.
Finder _risingCard() {
  return find.ancestor(of: find.byIcon(Icons.trending_up_rounded), matching: find.byType(Expanded));
}

/// The right (falling) card: the Expanded holding the trending_down header icon.
Finder _fallingCard() {
  return find.ancestor(of: find.byIcon(Icons.trending_down_rounded), matching: find.byType(Expanded));
}

Finder _in(Finder card, Finder matching) => find.descendant(of: card, matching: matching);

StatusPill _pill(WidgetTester tester, String text) {
  return tester.widget<StatusPill>(find.ancestor(of: find.text(text), matching: find.byType(StatusPill)));
}

ToneColors _tone(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(tester.element(find.byType(TrendSplitSection)), tone);
}

Color? _iconColor(WidgetTester tester, IconData icon) => tester.widget<Icon>(find.byIcon(icon)).color;

/// Pill icons inside [card], in order.
List<IconData?> _pillIcons(WidgetTester tester, Finder card) {
  return tester.widgetList<StatusPill>(_in(card, find.byType(StatusPill))).map((StatusPill p) => p.icon).toList();
}

/// Pumps [section] (default: both sample lists, default options).
Future<void> _pump(
  WidgetTester tester, [
  TrendSplitSection section = const TrendSplitSection(rising: _rising, falling: _falling),
]) {
  return pumpApp(tester, section);
}

void main() {
  group("defaultFormat", _formatTests);
  group("layout", _layoutTests);
  group("tones and icons", _toneTests);
  group("semantics", _semanticsTests);
  group("text scale", _textScaleTests);
  group("context", _contextTests);
}

void _formatTests() {
  test("signed one-decimal percentage, sign from the value", () {
    expect(TrendSplitSection.defaultFormat(0.18, locale: "en"), "+18.0%");
    expect(TrendSplitSection.defaultFormat(-0.14, locale: "en"), "-14.0%");
    expect(TrendSplitSection.defaultFormat(0, locale: "en"), "0.0%");
    expect(TrendSplitSection.defaultFormat(0.1234, locale: "en"), "+12.3%");
  });

  test("a negative value never gets a plus sign", () {
    for (final double delta in <double>[-0.05, -1, -0.0001]) {
      expect(TrendSplitSection.defaultFormat(delta, locale: "en"), isNot(contains("+")));
    }
  });

  test("uses the locale's percent pattern", () {
    final String text = TrendSplitSection.defaultFormat(0.18, locale: "fr");

    expect(text, startsWith("+18,0"));
    expect(text, endsWith("%"));
  });

  test("a value that rounds to zero is the unsigned zero", () {
    for (final double delta in <double>[0.00001, -0.00001, -0.0, 0.0004, -0.0004]) {
      expect(TrendSplitSection.defaultFormat(delta, locale: "en"), "0.0%", reason: "$delta");
      expect(
        TrendSplitSection.defaultFormat(delta, locale: "fr"),
        TrendSplitSection.defaultFormat(0, locale: "fr"),
        reason: "$delta",
      );
    }
    expect(TrendSplitSection.defaultFormat(0.0006, locale: "en"), "+0.1%");
    expect(TrendSplitSection.defaultFormat(-0.0006, locale: "en"), "-0.1%");
  });

  test("an unknown or null locale falls back without throwing", () {
    expect(TrendSplitSection.defaultFormat(0.18, locale: "zz-invalid"), contains("18"));
    expect(TrendSplitSection.defaultFormat(0.18), contains("18"));
  });
}

void _layoutTests() {
  testWidgets("every entry sits in its own column with its formatted pill", (WidgetTester tester) async {
    await _pump(tester);

    for (final String text in <String>["Alpha", "+18.0%", "Beta", "+12.0%"]) {
      expect(_in(_risingCard(), find.text(text)), findsOneWidget, reason: text);
      expect(_in(_fallingCard(), find.text(text)), findsNothing, reason: text);
    }
    for (final String text in <String>["Gamma", "-14.0%", "Delta", "-11.0%"]) {
      expect(_in(_fallingCard(), find.text(text)), findsOneWidget, reason: text);
      expect(_in(_risingCard(), find.text(text)), findsNothing, reason: text);
    }
    expect(tester.getCenter(find.text("Alpha")).dx, lessThan(tester.getCenter(find.text("Gamma")).dx));
  });

  testWidgets("the pill sign comes from the value, not from the column", (WidgetTester tester) async {
    await _pump(
      tester,
      const TrendSplitSection(
        rising: <TrendEntry>[TrendEntry(label: "Alpha", delta: -0.05)],
        falling: <TrendEntry>[TrendEntry(label: "Gamma", delta: 0.03)],
      ),
    );

    expect(_in(_risingCard(), find.text("-5.0%")), findsOneWidget);
    expect(_in(_fallingCard(), find.text("+3.0%")), findsOneWidget);
    expect(find.textContaining("+-"), findsNothing);
    expect(_pillIcons(tester, _risingCard()), <IconData?>[Icons.arrow_downward_rounded]);
    expect(_pillIcons(tester, _fallingCard()), <IconData?>[Icons.arrow_upward_rounded]);
  });

  testWidgets("titles default to the uppercased built-in keys", (WidgetTester tester) async {
    await _pump(tester);

    expect(_in(_risingCard(), find.text(_risingKey.toUpperCase())), findsOneWidget);
    expect(_in(_fallingCard(), find.text(_fallingKey.toUpperCase())), findsOneWidget);
  });

  testWidgets("custom titles are uppercased", (WidgetTester tester) async {
    await _pump(
      tester,
      const TrendSplitSection(rising: _rising, falling: _falling, risingTitle: "Winners", fallingTitle: "Losers"),
    );

    expect(find.text("WINNERS"), findsOneWidget);
    expect(find.text("LOSERS"), findsOneWidget);
    expect(find.text(_risingKey.toUpperCase()), findsNothing);
  });

  testWidgets("an empty column shows the placeholder, the other keeps its rows", (WidgetTester tester) async {
    await _pump(tester, const TrendSplitSection(rising: <TrendEntry>[], falling: _falling));

    expect(_in(_risingCard(), find.text(_emptyKey)), findsOneWidget);
    expect(_in(_fallingCard(), find.text(_emptyKey)), findsNothing);
    expect(_in(_fallingCard(), find.text("Gamma")), findsOneWidget);
    expect(_in(_risingCard(), find.byType(StatusPill)), findsNothing);
  });

  testWidgets("both columns empty show the placeholder twice", (WidgetTester tester) async {
    await _pump(tester, const TrendSplitSection(rising: <TrendEntry>[], falling: <TrendEntry>[]));

    expect(find.text(_emptyKey), findsNWidgets(2));
  });

  testWidgets("a custom empty label replaces the built-in key", (WidgetTester tester) async {
    await _pump(
      tester,
      const TrendSplitSection(rising: _rising, falling: <TrendEntry>[], emptyLabel: "Nothing here"),
    );

    expect(_in(_fallingCard(), find.text("Nothing here")), findsOneWidget);
    expect(find.text(_emptyKey), findsNothing);
  });

  testWidgets("N entries render N - 1 dividers", (WidgetTester tester) async {
    await _pump(
      tester,
      const TrendSplitSection(
        rising: <TrendEntry>[
          TrendEntry(label: "One", delta: 0.1),
          TrendEntry(label: "Two", delta: 0.2),
          TrendEntry(label: "Three", delta: 0.3),
        ],
        falling: <TrendEntry>[TrendEntry(label: "Four", delta: -0.1)],
      ),
    );

    expect(_in(_risingCard(), find.byType(Divider)), findsNWidgets(2));
    expect(_in(_fallingCard(), find.byType(Divider)), findsNothing);
  });

  testWidgets("a custom format is used for every pill", (WidgetTester tester) async {
    await _pump(
      tester,
      TrendSplitSection(rising: _rising, falling: _falling, format: (double delta) => "${delta}pt"),
    );

    for (final String text in <String>["0.18pt", "0.12pt", "-0.14pt", "-0.11pt"]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text("+18.0%"), findsNothing);
  });

  testWidgets("a long label ellipsizes on one line in a narrow parent", (WidgetTester tester) async {
    final String long = List<String>.filled(30, "Label").join(" ");
    await pumpApp(
      tester,
      Center(
        child: SizedBox(
          width: 320,
          child: TrendSplitSection(
            rising: <TrendEntry>[TrendEntry(label: long, delta: 0.18)],
            falling: <TrendEntry>[TrendEntry(label: long, delta: -0.14)],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final Text text = tester.widget<Text>(find.text(long).first);
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });
}

void _toneTests() {
  testWidgets("higherIsBetter (default): rising is success, falling is danger", (WidgetTester tester) async {
    await _pump(tester);

    expect(_pill(tester, "+18.0%").tone, StatusTone.success);
    expect(_pill(tester, "-14.0%").tone, StatusTone.danger);
    expect(_iconColor(tester, Icons.trending_up_rounded), _tone(tester, StatusTone.success).foreground);
    expect(_iconColor(tester, Icons.trending_down_rounded), _tone(tester, StatusTone.danger).foreground);
  });

  testWidgets("higherIsBetter false swaps the tones", (WidgetTester tester) async {
    await _pump(tester, const TrendSplitSection(rising: _rising, falling: _falling, higherIsBetter: false));

    expect(_pill(tester, "+18.0%").tone, StatusTone.danger);
    expect(_pill(tester, "-14.0%").tone, StatusTone.success);
    expect(_iconColor(tester, Icons.trending_up_rounded), _tone(tester, StatusTone.danger).foreground);
    expect(_iconColor(tester, Icons.trending_down_rounded), _tone(tester, StatusTone.success).foreground);
  });

  testWidgets("pills are dense, tinted container / onContainer, with an arrow", (WidgetTester tester) async {
    await _pump(tester);
    final ToneColors success = _tone(tester, StatusTone.success);

    final StatusPill pill = _pill(tester, "+18.0%");
    expect(pill.dense, isTrue);
    expect(pill.icon, Icons.arrow_upward_rounded);
    expect(_pill(tester, "-14.0%").icon, Icons.arrow_downward_rounded);

    final Finder container = find.ancestor(of: find.text("+18.0%"), matching: find.byType(Container)).first;
    expect((tester.widget<Container>(container).decoration! as BoxDecoration).color, success.container);
    expect(tester.widget<Text>(find.text("+18.0%")).style?.color, success.onContainer);
  });

  testWidgets("header icons sit in their own card, pill arrows follow the value", (WidgetTester tester) async {
    await _pump(tester);

    expect(_in(_risingCard(), find.byIcon(Icons.trending_up_rounded)), findsOneWidget);
    expect(_in(_fallingCard(), find.byIcon(Icons.trending_down_rounded)), findsOneWidget);
    expect(_in(_risingCard(), find.byIcon(Icons.arrow_upward_rounded)), findsNWidgets(2));
    expect(_in(_fallingCard(), find.byIcon(Icons.arrow_downward_rounded)), findsNWidgets(2));
  });

  testWidgets("a delta that is or formats like zero has no arrow and no sign", (WidgetTester tester) async {
    await _pump(
      tester,
      const TrendSplitSection(
        rising: <TrendEntry>[TrendEntry(label: "Flat", delta: 0), TrendEntry(label: "Tiny", delta: 0.00001)],
        falling: <TrendEntry>[TrendEntry(label: "Tinier", delta: -0.00001)],
      ),
    );

    expect(find.text("0.0%"), findsNWidgets(3));
    expect(_pillIcons(tester, _risingCard()), <IconData?>[null, null]);
    expect(_pillIcons(tester, _fallingCard()), <IconData?>[null]);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
  });

  testWidgets("a custom format keeps the value-driven arrow", (WidgetTester tester) async {
    await _pump(
      tester,
      TrendSplitSection(
        rising: const <TrendEntry>[TrendEntry(label: "Alpha", delta: 2)],
        falling: const <TrendEntry>[TrendEntry(label: "Gamma", delta: -3), TrendEntry(label: "Zero", delta: 0)],
        format: (double delta) => "${delta.round()} pts",
      ),
    );

    expect(_pillIcons(tester, _risingCard()), <IconData?>[Icons.arrow_upward_rounded]);
    expect(_pillIcons(tester, _fallingCard()), <IconData?>[Icons.arrow_downward_rounded, null]);
  });
}

void _semanticsTests() {
  testWidgets("titles are header nodes with the title as given", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await _pump(
      tester,
      const TrendSplitSection(rising: _rising, falling: _falling, risingTitle: "Winners", fallingTitle: "Losers"),
    );

    expect(find.bySemanticsLabel("Winners"), findsOneWidget);
    expect(tester.getSemantics(find.bySemanticsLabel("Winners")), matchesSemantics(label: "Winners", isHeader: true));
    expect(tester.getSemantics(find.bySemanticsLabel("Losers")), matchesSemantics(label: "Losers", isHeader: true));
    expect(find.bySemanticsLabel("WINNERS"), findsNothing);
    handle.dispose();
  });

  testWidgets("each row is one node reading the label and the delta", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await _pump(tester);

    final SemanticsNode node = tester.getSemantics(find.text("Alpha"));
    expect(node.label, contains("Alpha"));
    expect(node.label, contains("+18.0%"));
    expect(tester.getSemantics(find.text("Gamma")).label, contains("-14.0%"));
    handle.dispose();
  });
}

/// Pumps one entry per column at [params].scale inside a [params].width box.
Future<void> _pumpScaled(WidgetTester tester, ({double width, double scale}) params) {
  return pumpApp(
    tester,
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(params.scale)),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: params.width,
          child: const TrendSplitSection(
            rising: <TrendEntry>[TrendEntry(label: "Alpha long label here", delta: 0.184)],
            falling: <TrendEntry>[TrendEntry(label: "Gamma", delta: -0.143)],
          ),
        ),
      ),
    ),
  );
}

void _textScaleTests() {
  for (final ({double width, double scale}) params in <({double width, double scale})>[
    (width: 328, scale: 2),
    (width: 288, scale: 1.3),
    (width: 328, scale: 1),
  ]) {
    testWidgets("width ${params.width} at text scale ${params.scale}: no overflow, label keeps 32 dp", (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpScaled(tester, params);

      expect(tester.takeException(), isNull);
      for (final String label in <String>["Alpha long label here", "Gamma"]) {
        final Finder row = find.ancestor(of: find.text(label), matching: find.byType(Row)).first;
        final Finder pill = find.descendant(of: row, matching: find.byType(StatusPill));
        expect(tester.getRect(pill).right, lessThanOrEqualTo(tester.getRect(row).right + 0.01), reason: label);
        expect(tester.getSize(find.text(label)).width, greaterThanOrEqualTo(32 - 0.01), reason: label);
      }
      expect(tester.getSemantics(find.text("Alpha long label here")).label, contains("+18.4%"));
      expect(tester.getSemantics(find.text("Gamma")).label, contains("-14.3%"));
      handle.dispose();
    });
  }
}

void _contextTests() {
  testWidgets("formats with the ambient locale", (WidgetTester tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (BuildContext context) => Localizations.override(
          context: context,
          locale: const Locale("fr"),
          child: const TrendSplitSection(rising: _rising, falling: _falling),
        ),
      ),
    );

    expect(find.textContaining("+18,0"), findsOneWidget);
    expect(find.text("+18.0%"), findsNothing);
  });

  testWidgets("renders under the dark theme with the dark tones", (WidgetTester tester) async {
    await pumpApp(tester, const TrendSplitSection(rising: _rising, falling: _falling), theme: AppTheme.dark());

    expect(tester.takeException(), isNull);
    expect(_iconColor(tester, Icons.trending_up_rounded), _tone(tester, StatusTone.success).foreground);
    expect(tester.widget<Text>(find.text("-14.0%")).style?.color, _tone(tester, StatusTone.danger).onContainer);
    expect(Theme.of(tester.element(find.byType(TrendSplitSection))).brightness, Brightness.dark);
  });
}
