// pill_link_test.dart
//
// Widget tests for PillLink: icon / label / arrow structure, the built-in
// label key, the optional icon, tap callback, pill sizes against the 48 dp
// hit area (on every platform), directional padding and gaps, single-node
// semantics, ellipsis under narrow and unbounded parents, ColorScheme tokens
// in light and dark, and a host that navigates from onPressed.

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/PillLink/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";

import "../../helpers/widget_test_helpers.dart";

const String _label = "Read the details";

Finder _inLink(Finder matching) {
  return find.descendant(of: find.byType(PillLink), matching: matching);
}

/// The drawn pill: the TextButton's own Material.
Finder _pill() => _inLink(find.byType(Material)).first;

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(PillLink))).colorScheme;

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onPressed,
  String? label = _label,
  IconData? icon = Icons.lightbulb_outline_rounded,
  PillLinkSize size = PillLinkSize.standard,
  String? semanticsLabel,
  ThemeData? theme,
}) {
  return pumpApp(
    tester,
    Center(
      child: PillLink(
        onPressed: onPressed ?? () {},
        label: label,
        icon: icon,
        size: size,
        semanticsLabel: semanticsLabel,
      ),
    ),
    theme: theme,
  );
}

void main() {
  group("structure", () {
    testWidgets("renders the lightbulb, the label and a trailing arrow in order", (WidgetTester tester) async {
      await _pump(tester);

      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
      expect(find.text(_label), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      final double iconX = tester.getCenter(find.byIcon(Icons.lightbulb_outline_rounded)).dx;
      final double labelX = tester.getCenter(find.text(_label)).dx;
      final double arrowX = tester.getCenter(find.byIcon(Icons.arrow_forward_rounded)).dx;
      expect(iconX, lessThan(labelX));
      expect(labelX, lessThan(arrowX));
    });

    testWidgets("null label shows the built-in key", (WidgetTester tester) async {
      await _pump(tester, label: null);

      expect(find.text("custom.pill_link.learn_more"), findsOneWidget);
    });

    testWidgets("null icon hides the leading icon, label and arrow remain", (WidgetTester tester) async {
      await _pump(tester, icon: null);

      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsNothing);
      expect(_inLink(find.byType(Icon)), findsOneWidget);
      expect(find.text(_label), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });

    testWidgets("a custom icon renders instead of the lightbulb", (WidgetTester tester) async {
      await _pump(tester, icon: Icons.help_outline);

      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsNothing);
    });

    testWidgets("label is labelSmall, w700, one line with an ellipsis", (WidgetTester tester) async {
      await _pump(tester);

      final Text text = tester.widget<Text>(find.text(_label));
      final TextTheme textTheme = Theme.of(tester.element(find.byType(PillLink))).textTheme;
      expect(text.style?.fontWeight, FontWeight.w700);
      expect(text.style?.letterSpacing, textTheme.labelSmall?.letterSpacing);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });

  group("interaction", () {
    testWidgets("tap calls onPressed exactly once", (WidgetTester tester) async {
      int taps = 0;
      await _pump(tester, onPressed: () => taps++);

      await tester.tap(find.byType(PillLink));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets("a tap in the padded area outside the drawn pill still fires", (WidgetTester tester) async {
      int taps = 0;
      await _pump(tester, onPressed: () => taps++, size: PillLinkSize.compact);

      final Rect pill = tester.getRect(_pill());
      await tester.tapAt(Offset(pill.center.dx, pill.top - 6));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets("keyboard activation calls onPressed", (WidgetTester tester) async {
      int taps = 0;
      await _pump(tester, onPressed: () => taps++);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets("a host navigates from onPressed", (WidgetTester tester) async {
      await pumpWithRouter(
        tester,
        Builder(
          builder: (BuildContext context) => Center(
            child: PillLink(label: _label, onPressed: () => context.go("/target?x=1")),
          ),
        ),
        extraRoutes: <RouteBase>[
          GoRoute(
            path: "/target",
            builder: (BuildContext context, GoRouterState state) => Text("landed ${state.uri}"),
          ),
        ],
      );

      await tester.tap(find.byType(PillLink));
      await tester.pumpAndSettle();

      expect(find.text("landed /target?x=1"), findsOneWidget);
    });
  });

  group("size", () {
    testWidgets("standard pill is 28 dp tall, compact 24 dp", (WidgetTester tester) async {
      await _pump(tester);
      expect(tester.getSize(_pill()).height, 28);
      expect(tester.widget<Icon>(find.byIcon(Icons.lightbulb_outline_rounded)).size, 14);
      expect(tester.widget<Icon>(find.byIcon(Icons.arrow_forward_rounded)).size, 12);
      expect(tester.widget<Text>(find.text(_label)).style?.fontSize, 11);

      await _pump(tester, size: PillLinkSize.compact);
      expect(tester.getSize(_pill()).height, 24);
      expect(tester.widget<Icon>(find.byIcon(Icons.lightbulb_outline_rounded)).size, 12);
      expect(tester.widget<Icon>(find.byIcon(Icons.arrow_forward_rounded)).size, 10);
      expect(tester.widget<Text>(find.text(_label)).style?.fontSize, 10);
    });

    testWidgets("padding is start 10 / end 12 (standard), 8 / 10 (compact), 4 dp gaps", (WidgetTester tester) async {
      for (final (PillLinkSize size, double start, double end) entry in <(PillLinkSize, double, double)>[
        (PillLinkSize.standard, 10, 12),
        (PillLinkSize.compact, 8, 10),
      ]) {
        await _pump(tester, size: entry.$1);
        final Rect pill = tester.getRect(_pill());
        final Rect icon = tester.getRect(find.byIcon(Icons.lightbulb_outline_rounded));
        final Rect label = tester.getRect(find.text(_label));
        final Rect arrow = tester.getRect(find.byIcon(Icons.arrow_forward_rounded));

        expect(icon.left - pill.left, entry.$2, reason: "${entry.$1.name} start padding");
        expect(pill.right - arrow.right, entry.$3, reason: "${entry.$1.name} end padding");
        expect(label.left - icon.right, 4, reason: "${entry.$1.name} icon gap");
        expect(arrow.left - label.right, 4, reason: "${entry.$1.name} arrow gap");
      }
    });

    for (final PillLinkSize size in PillLinkSize.values) {
      testWidgets(
        "${size.name}: hit area ≥ kMinTapTarget on every platform",
        (WidgetTester tester) async {
          final SemanticsHandle handle = tester.ensureSemantics();
          await _pump(tester, size: size, label: "Go");

          final Size box = tester.getSize(find.byType(PillLink));
          expect(box.width, greaterThanOrEqualTo(kMinTapTarget));
          expect(box.height, greaterThanOrEqualTo(kMinTapTarget));
          expect(tester.getSize(_pill()).height, size == PillLinkSize.standard ? 28 : 24);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          handle.dispose();
        },
        variant: TargetPlatformVariant.all(),
      );
    }

    testWidgets("grows with large text instead of clipping", (WidgetTester tester) async {
      await pumpApp(
        tester,
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Center(child: PillLink(label: _label, onPressed: () {})),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_pill()).height, greaterThan(28));
    });
  });

  group("semantics", () {
    testWidgets("one enabled, focusable button labelled with the visible text", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester);

      expect(
        tester.getSemantics(find.byType(PillLink)),
        isSemantics(
          label: _label,
          isButton: true,
          hasTapAction: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
      expect(find.bySemanticsLabel(_label), findsOneWidget);
      handle.dispose();
    });

    testWidgets("semanticsLabel overrides the visible label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, label: "Learn more", semanticsLabel: "Learn more about this value");

      expect(
        tester.getSemantics(find.byType(PillLink)),
        isSemantics(label: "Learn more about this value", isButton: true),
      );
      expect(find.bySemanticsLabel("Learn more"), findsNothing);
      handle.dispose();
    });

    testWidgets("the icons add nothing to the semantics label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester);

      expect(tester.getSemantics(find.byType(PillLink)).label, _label);
      handle.dispose();
    });
  });

  group("layout", () {
    testWidgets("a long label truncates inside a narrow parent without overflow", (WidgetTester tester) async {
      const String longLabel = "A very long label that cannot possibly fit in the space available";
      await pumpApp(
        tester,
        Center(
          child: SizedBox(
            width: 120,
            child: PillLink(label: longLabel, onPressed: () {}),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.renderObject<RenderParagraph>(find.text(longLabel)).didExceedMaxLines, isTrue);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    });

    testWidgets("sits in a Row (unbounded width) without error", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text("Value"),
            PillLink(label: _label, onPressed: () {}),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_label), findsOneWidget);
    });

    testWidgets("RTL mirrors the order and the padding: arrow on the left", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Directionality(
          textDirection: TextDirection.rtl,
          child: Center(child: PillLink(label: _label, onPressed: () {})),
        ),
      );

      final double labelX = tester.getCenter(find.text(_label)).dx;
      expect(tester.getCenter(find.byIcon(Icons.arrow_forward_rounded)).dx, lessThan(labelX));
      expect(tester.getCenter(find.byIcon(Icons.lightbulb_outline_rounded)).dx, greaterThan(labelX));

      // Directional padding: start (10) is on the right, end (12) on the left.
      final Rect pill = tester.getRect(_pill());
      expect(pill.right - tester.getRect(find.byIcon(Icons.lightbulb_outline_rounded)).right, 10);
      expect(tester.getRect(find.byIcon(Icons.arrow_forward_rounded)).left - pill.left, 12);
    });
  });

  group("theme tokens", () {
    for (final (String name, ThemeData Function() theme) entry in <(String, ThemeData Function())>[
      ("light", AppTheme.light),
      ("dark", AppTheme.dark),
    ]) {
      testWidgets("${entry.$1}: cs.primary label, icon, translucent fill, border and arrow", (WidgetTester tester) async {
        await _pump(tester, theme: entry.$2());
        final ColorScheme cs = _scheme(tester);

        expect(tester.widget<Text>(find.text(_label)).style?.color, cs.primary);
        expect(tester.widget<Icon>(find.byIcon(Icons.lightbulb_outline_rounded)).color, cs.primary);
        expect(
          tester.widget<Icon>(find.byIcon(Icons.arrow_forward_rounded)).color,
          cs.primary.withValues(alpha: 0.6),
        );

        final Material pill = tester.widget<Material>(_pill());
        expect(pill.color, cs.primary.withValues(alpha: 0.08));
        final OutlinedBorder shape = pill.shape! as OutlinedBorder;
        expect(shape, isA<StadiumBorder>());
        expect(shape.side.color, cs.primary.withValues(alpha: 0.20));
      });
    }
  });
}
