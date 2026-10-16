// context_header_test.dart
//
// Widget tests for ContextHeader: icon / title / subtitle structure, the
// three title states (text, null skeleton, empty), the optional change link
// (callback, custom label, hidden without callback, 48 dp hit area, single
// semantics node with a tap action), the link capped at 40 % of the row and
// level with the first text line, long-title ellipsis, the placeholder
// holding the title's line height, content height in a bounded parent,
// intrinsic sizing without a link, reduced motion, RTL order, no Material
// ancestor needed, and ColorScheme tokens (including the rendered divider
// colour) in light and dark themes. One function per group keeps main short.

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/core/decorators/SkeletonPulse/index.dart";
import "package:flutter_skeleton/widgets/custom/ContextHeader/index.dart";
import "package:flutter_skeleton/widgets/custom/SkeletonBlock/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _title = "Main office";
const String _subtitle = "12.34 / 56.78";
const String _changeKey = "custom.context_header.change";
const String _loadingKey = "custom.context_header.loading";

Future<void> _pump(
  WidgetTester tester, {
  String? title = _title,
  VoidCallback? onChange,
  bool withLink = true,
  String? changeLabel,
  String? changeSemanticsLabel,
  ThemeData? theme,
}) {
  return pumpApp(
    tester,
    ContextHeader(
      icon: Icons.place_outlined,
      title: title,
      subtitle: _subtitle,
      onChange: withLink ? (onChange ?? () {}) : null,
      changeLabel: changeLabel,
      changeSemanticsLabel: changeSemanticsLabel,
    ),
    theme: theme,
  );
}

Text _text(WidgetTester tester, String data) => tester.widget<Text>(find.text(data));

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(ContextHeader))).colorScheme;

/// Colour of the line the Divider actually paints (its bottom border).
Color? _dividerLineColor(WidgetTester tester) {
  final Container line = tester.widget<Container>(
    find.descendant(of: find.byType(Divider), matching: find.byType(Container)),
  );
  final BoxDecoration? decoration = line.decoration as BoxDecoration?;
  final Border? border = decoration?.border as Border?;
  return border?.bottom.color;
}

/// Pumps a header with a link at [textScale] text scaling.
Future<void> _pumpScaled(
  WidgetTester tester,
  double textScale, {
  String? title = _title,
  String? changeLabel,
  Size? surfaceSize,
}) async {
  await pumpApp(
    tester,
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: ContextHeader(
        icon: Icons.place_outlined,
        title: title,
        subtitle: _subtitle,
        onChange: () {},
        changeLabel: changeLabel,
      ),
    ),
    surfaceSize: surfaceSize,
  );
  await tester.pump(const Duration(milliseconds: 100));
}

/// Top of the subtitle for [title], at [textScale].
Future<double> _subtitleTop(WidgetTester tester, String? title, double textScale) async {
  await _pumpScaled(tester, textScale, title: title);
  return tester.getTopLeft(find.text(_subtitle)).dy;
}

/// Vertical centre of the link label.
double _linkCentre(WidgetTester tester, String label) => tester.getCenter(find.text(label)).dy;

void main() {
  _structureTests();
  _titleStateTests();
  _changeLinkTests();
  _linkLayoutTests();
  _semanticsTests();
  _reducedMotionTests();
  _themeTokenTests();
}

void _structureTests() {
  group("structure", () {
    testWidgets("renders the icon, the title and the subtitle", (WidgetTester tester) async {
      await _pump(tester);

      expect(find.byIcon(Icons.place_outlined), findsOneWidget);
      expect(find.text(_title), findsOneWidget);
      expect(find.text(_subtitle), findsOneWidget);
      expect(tester.getTopLeft(find.text(_title)).dy, lessThan(tester.getTopLeft(find.text(_subtitle)).dy));
      expect(find.byType(SkeletonPulse), findsNothing);
    });

    testWidgets("orders icon, texts and link from start to end, divider below", (WidgetTester tester) async {
      await _pump(tester);

      final double iconX = tester.getCenter(find.byIcon(Icons.place_outlined)).dx;
      final double titleX = tester.getCenter(find.text(_title)).dx;
      final double linkX = tester.getCenter(find.text(_changeKey)).dx;
      expect(iconX, lessThan(titleX));
      expect(titleX, lessThan(linkX));
      expect(find.byType(Divider), findsOneWidget);
      expect(tester.getTopLeft(find.byType(Divider)).dy, greaterThan(tester.getBottomLeft(find.text(_subtitle)).dy));
    });

    testWidgets("takes its content height in a bounded parent", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: ContextHeader(icon: Icons.place_outlined, title: _title, subtitle: _subtitle, onChange: () {}),
        ),
      );

      // No bottom padding: the header ends with its divider.
      expect(tester.getBottomLeft(find.byType(ContextHeader)).dy, tester.getBottomLeft(find.byType(Divider)).dy);
    });

    testWidgets("RTL mirrors the row", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Directionality(
          textDirection: TextDirection.rtl,
          child: ContextHeader(icon: Icons.place_outlined, title: _title, subtitle: _subtitle, onChange: () {}),
        ),
      );

      final double iconX = tester.getCenter(find.byIcon(Icons.place_outlined)).dx;
      final double linkX = tester.getCenter(find.text(_changeKey)).dx;
      expect(iconX, greaterThan(linkX));
    });

    testWidgets("without a link it works under an intrinsic-size parent", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const IntrinsicHeight(
          child: ContextHeader(icon: Icons.place_outlined, title: _title, subtitle: _subtitle),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_title), findsOneWidget);
    });
  });
}

void _titleStateTests() {
  group("title states", () {
    testWidgets("null title shows one pulsing 120 x 14 placeholder and keeps the subtitle", (WidgetTester tester) async {
      await _pump(tester, title: null);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SkeletonPulse), findsOneWidget);
      expect(find.byType(SkeletonBlock), findsOneWidget);
      final SkeletonBlock block = tester.widget<SkeletonBlock>(find.byType(SkeletonBlock));
      expect(block.width, 120);
      expect(block.height, 14);
      expect(tester.getSize(find.byType(SkeletonBlock)), const Size(120, 14));
      expect(find.text(_subtitle), findsOneWidget);
      // Only the subtitle and the link label remain as texts.
      expect(find.byType(Text), findsNWidgets(2));
    });

    for (final double scale in <double>[1, 1.5]) {
      testWidgets("x$scale: the placeholder holds the title's line, so the subtitle does not move", (
        WidgetTester tester,
      ) async {
        final double loadingTop = await _subtitleTop(tester, null, scale);
        expect(find.byType(SkeletonBlock), findsOneWidget);
        final double loadedTop = await _subtitleTop(tester, "x", scale);
        expect(find.byType(SkeletonBlock), findsNothing);

        expect(loadingTop, moreOrLessEquals(loadedTop));
      });
    }

    testWidgets("null title is announced as loading", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, title: null);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.bySemanticsLabel(_loadingKey), findsOneWidget);
      handle.dispose();
    });

    testWidgets("the placeholder pulses", (WidgetTester tester) async {
      await _pump(tester, title: null);
      final Finder opacity = find.descendant(of: find.byType(SkeletonPulse), matching: find.byType(Opacity));
      final double start = tester.widget<Opacity>(opacity).opacity;

      await tester.pump(const Duration(milliseconds: 750));

      expect(tester.widget<Opacity>(opacity).opacity, isNot(start));
    });

    testWidgets("empty title hides the title row but keeps the subtitle", (WidgetTester tester) async {
      await _pump(tester, title: "");

      expect(find.byType(SkeletonPulse), findsNothing);
      expect(find.text(""), findsNothing);
      expect(find.text(_subtitle), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets("a long title stays on one line with an ellipsis", (WidgetTester tester) async {
      final String longTitle = "A very long heading " * 4;
      await pumpApp(
        tester,
        ContextHeader(icon: Icons.place_outlined, title: longTitle, subtitle: _subtitle, onChange: () {}),
        surfaceSize: const Size(320, 200),
      );

      expect(tester.takeException(), isNull);
      final Text title = _text(tester, longTitle);
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(find.text(longTitle));
      expect(paragraph.didExceedMaxLines, isTrue);
      expect(tester.getTopRight(find.text(longTitle)).dx, lessThan(tester.getTopLeft(find.text(_changeKey)).dx));
    });
  });
}

void _changeLinkTests() {
  group("change link", () {
    testWidgets("tapping the default label calls onChange once", (WidgetTester tester) async {
      int calls = 0;
      await _pump(tester, onChange: () => calls++);

      await tester.tap(find.text(_changeKey));
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets("changeLabel replaces the default label", (WidgetTester tester) async {
      await _pump(tester, changeLabel: "Pick another");

      expect(find.text("Pick another"), findsOneWidget);
      expect(find.text(_changeKey), findsNothing);
    });

    testWidgets("no callback, no link", (WidgetTester tester) async {
      await _pump(tester, withLink: false);

      expect(find.byType(InkWell), findsNothing);
      expect(find.text(_changeKey), findsNothing);
      expect(find.text(_title), findsOneWidget);
    });

    testWidgets("the hit area is at least kMinTapTarget square", (WidgetTester tester) async {
      await _pump(tester);

      final Size size = tester.getSize(find.byType(InkWell));
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets("works without a Material ancestor", (WidgetTester tester) async {
      int calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: ContextHeader(icon: Icons.place_outlined, title: _title, subtitle: _subtitle, onChange: () => calls++),
        ),
      );

      expect(tester.takeException(), isNull);
      await tester.tap(find.text(_changeKey));
      expect(calls, 1);
    });
  });
}

void _linkLayoutTests() {
  group("link layout", () {
    testWidgets("a long label at 320 dp and 2x text is capped, ellipsised and read in full", (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      const String longLabel = "Pick another one from the full list";
      await _pumpScaled(tester, 2, changeLabel: longLabel, surfaceSize: const Size(320, 300));

      expect(tester.takeException(), isNull);
      // Row width: 320 minus 2 x 16 dp of horizontal padding.
      const double rowWidth = 320 - kDefaultPadding * 4;
      expect(tester.getSize(find.byType(InkWell)).width, lessThanOrEqualTo(rowWidth * 0.4));
      expect(tester.getSize(find.text(_title)).width, greaterThan(rowWidth * 0.4));
      final Text link = _text(tester, longLabel);
      expect(link.maxLines, 1);
      expect(link.overflow, TextOverflow.ellipsis);
      expect(tester.renderObject<RenderParagraph>(find.text(longLabel)).didExceedMaxLines, isTrue);
      expect(find.bySemanticsLabel(longLabel), findsOneWidget);
      handle.dispose();
    });

    testWidgets("a short label keeps its natural width", (WidgetTester tester) async {
      await _pump(tester, changeLabel: "Edit");

      expect(tester.renderObject<RenderParagraph>(find.text("Edit")).didExceedMaxLines, isFalse);
      expect(
        tester.getSize(find.byType(InkWell)).width,
        moreOrLessEquals(tester.getSize(find.text("Edit")).width + kDefaultPadding * 2),
      );
    });

    for (final double scale in <double>[1, 2]) {
      testWidgets("x$scale: the label is level with the title line", (WidgetTester tester) async {
        await _pumpScaled(tester, scale);

        expect(_linkCentre(tester, _changeKey), moreOrLessEquals(tester.getCenter(find.text(_title)).dy, epsilon: 0.5));
      });
    }

    testWidgets("the label is level with the placeholder while the title loads", (WidgetTester tester) async {
      await _pumpScaled(tester, 1, title: null);

      expect(
        _linkCentre(tester, _changeKey),
        moreOrLessEquals(tester.getCenter(find.byType(SkeletonBlock)).dy, epsilon: 0.5),
      );
    });

    testWidgets("with an empty title the label is level with the subtitle", (WidgetTester tester) async {
      await _pumpScaled(tester, 1, title: "");

      expect(_linkCentre(tester, _changeKey), moreOrLessEquals(tester.getCenter(find.text(_subtitle)).dy, epsilon: 0.5));
    });
  });
}

void _semanticsTests() {
  group("semantics", () {
    testWidgets("the link is one button node with a tap action and the visible label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int calls = 0;
      await _pump(tester, onChange: () => calls++);

      expect(
        tester.getSemantics(find.text(_changeKey)),
        isSemantics(label: _changeKey, isButton: true, hasTapAction: true),
      );
      expect(find.bySemanticsLabel(_changeKey), findsOneWidget);

      tester.semantics.tap(find.semantics.byLabel(_changeKey));
      await tester.pump();
      expect(calls, 1);
      handle.dispose();
    });

    testWidgets("changeSemanticsLabel replaces the spoken label only", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, changeSemanticsLabel: "Change the place");

      expect(find.text(_changeKey), findsOneWidget);
      expect(
        tester.getSemantics(find.text(_changeKey)),
        isSemantics(label: "Change the place", isButton: true, hasTapAction: true),
      );
      expect(find.bySemanticsLabel(_changeKey), findsNothing);
      handle.dispose();
    });

    testWidgets("the title and the subtitle are read", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester);

      expect(find.bySemanticsLabel(_title), findsOneWidget);
      expect(find.bySemanticsLabel(_subtitle), findsOneWidget);
      handle.dispose();
    });
  });
}

void _reducedMotionTests() {
  group("reduced motion", () {
    testWidgets("the placeholder is static and pumpAndSettle completes", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: ContextHeader(icon: Icons.place_outlined, subtitle: _subtitle),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SkeletonBlock), findsOneWidget);
      expect(find.byType(SkeletonPulse), findsNothing);
      expect(find.ancestor(of: find.byType(SkeletonBlock), matching: find.byType(Opacity)), findsNothing);
    });
  });
}

void _themeTokenTests() {
  group("theme tokens", () {
    for (final (String name, ThemeData Function() theme) in <(String, ThemeData Function())>[
      ("light", AppTheme.light),
      ("dark", AppTheme.dark),
    ]) {
      testWidgets("$name: icon, title, subtitle and link use ColorScheme roles", (WidgetTester tester) async {
        await _pump(tester, theme: theme());
        final ColorScheme cs = _scheme(tester);

        expect(tester.widget<Icon>(find.byIcon(Icons.place_outlined)).color, cs.primary);
        expect(_text(tester, _title).style?.color, cs.onSurface);
        expect(_text(tester, _subtitle).style?.color, cs.onSurfaceVariant);
        expect(_text(tester, _changeKey).style?.color, cs.primary);
        expect(tester.widget<Divider>(find.byType(Divider)).color, isNull);
        expect(_dividerLineColor(tester), cs.outlineVariant);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
