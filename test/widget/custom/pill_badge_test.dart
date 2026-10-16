// pill_badge_test.dart
//
// Widget tests for PillBadge: label and icon structure, default ColorScheme
// tokens, tone foregrounds, colour / background overrides, outlined and dense
// variants, the tap tooltip with its exact 48 dp hit area, single-node
// semantics (empty semanticsLabel falls back to the label), overflow under
// narrow parents and text scaling, and the dark theme.

import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _label = "Ready";
const String _tip = "Checked two minutes ago";

Finder _inBadge(Finder matching) {
  return find.descendant(of: find.byType(PillBadge), matching: matching);
}

/// The pill Container (the only Container inside the badge).
Container _pill(WidgetTester tester) => tester.widget<Container>(_inBadge(find.byType(Container)));

BoxDecoration _decoration(WidgetTester tester) => _pill(tester).decoration! as BoxDecoration;

Text _text(WidgetTester tester) => tester.widget<Text>(find.text(_label));

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(PillBadge))).colorScheme;

ToneColors _tone(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(tester.element(find.byType(PillBadge)), tone);
}

/// Center on [finder] in screen coordinates.
Offset _center(WidgetTester tester, Finder finder) => tester.getCenter(finder);

Future<void> _finishTooltipTimers(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

void main() {
  group("structure", () {
    testWidgets("renders the label and no icon by default", (WidgetTester tester) async {
      await pumpApp(tester, const PillBadge(label: _label));

      expect(find.text(_label), findsOneWidget);
      expect(_inBadge(find.byType(Icon)), findsNothing);
    });

    testWidgets("renders the icon before the label, 14 dp, in the label colour", (WidgetTester tester) async {
      await pumpApp(tester, const PillBadge(label: _label, icon: Icons.check));

      final Icon icon = tester.widget<Icon>(find.byIcon(Icons.check));
      expect(icon.size, 14);
      expect(icon.color, _text(tester).style?.color);
      expect(
        tester.getTopLeft(find.byIcon(Icons.check)).dx,
        lessThan(tester.getTopLeft(find.text(_label)).dx),
      );
    });

    testWidgets("label is 11 / w700 on one line with an ellipsis", (WidgetTester tester) async {
      await pumpApp(tester, const PillBadge(label: _label));

      final Text text = _text(tester);
      expect(text.style?.fontSize, 11);
      expect(text.style?.fontWeight, FontWeight.w700);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });

  group("default tokens (light)", () {
    testWidgets("neutral foreground, translucent surface, pill radius, 12 / 8 padding", (WidgetTester tester) async {
      await pumpApp(tester, const PillBadge(label: _label));
      final ColorScheme cs = _scheme(tester);

      expect(_text(tester).style?.color, cs.onSurfaceVariant);
      final BoxDecoration decoration = _decoration(tester);
      expect(decoration.color, cs.surface.withValues(alpha: 0.72));
      expect(decoration.borderRadius, BorderRadius.circular(999));
      expect(decoration.border, isNull);
      expect(_pill(tester).padding, const EdgeInsets.symmetric(horizontal: 12, vertical: 8));
    });
  });

  group("tones and overrides", () {
    for (final StatusTone tone in StatusTone.values) {
      testWidgets("${tone.name} tone colours the label and the icon", (WidgetTester tester) async {
        await pumpApp(tester, PillBadge(label: _label, tone: tone, icon: tone.icon));

        final Color expected = _tone(tester, tone).foreground;
        expect(_text(tester).style?.color, expected);
        expect(tester.widget<Icon>(find.byIcon(tone.icon)).color, expected);
        // The fill stays the translucent default whatever the tone.
        expect(_decoration(tester).color, _scheme(tester).surface.withValues(alpha: 0.72));
      });
    }

    testWidgets("color overrides the tone and backgroundColor overrides the fill", (WidgetTester tester) async {
      await pumpApp(tester, const PillBadge(label: _label, tone: StatusTone.danger, icon: Icons.check));
      final ColorScheme cs = _scheme(tester);

      await pumpApp(
        tester,
        PillBadge(
          label: _label,
          tone: StatusTone.danger,
          icon: Icons.check,
          color: cs.tertiary,
          backgroundColor: cs.tertiaryContainer,
        ),
      );

      expect(_text(tester).style?.color, cs.tertiary);
      expect(tester.widget<Icon>(find.byIcon(Icons.check)).color, cs.tertiary);
      expect(_decoration(tester).color, cs.tertiaryContainer);
    });

    testWidgets("outlined uses surfaceContainerHigh and an outlineVariant border", (WidgetTester tester) async {
      await pumpApp(tester, const PillBadge(label: _label, outlined: true));
      final ColorScheme cs = _scheme(tester);

      final BoxDecoration decoration = _decoration(tester);
      expect(decoration.color, cs.surfaceContainerHigh);
      expect(decoration.border, Border.all(color: cs.outlineVariant));
      expect(decoration.borderRadius, BorderRadius.circular(999));
    });

    testWidgets("backgroundColor wins over outlined, the border stays", (WidgetTester tester) async {
      await pumpApp(tester, const PillBadge(label: _label));
      final ColorScheme cs = _scheme(tester);

      await pumpApp(tester, PillBadge(label: _label, outlined: true, backgroundColor: cs.primaryContainer));

      expect(_decoration(tester).color, cs.primaryContainer);
      expect(_decoration(tester).border, Border.all(color: cs.outlineVariant));
    });

    testWidgets("dense uses 8 / 4 padding and a smaller pill", (WidgetTester tester) async {
      await pumpApp(tester, const PillBadge(label: _label));
      final Size regular = tester.getSize(_inBadge(find.byType(Container)));

      await pumpApp(tester, const PillBadge(label: _label, dense: true));
      final Size dense = tester.getSize(_inBadge(find.byType(Container)));

      expect(_pill(tester).padding, const EdgeInsets.symmetric(horizontal: 8, vertical: 4));
      expect(dense.width, lessThan(regular.width));
      expect(dense.height, lessThan(regular.height));
    });
  });

  group("tooltip", () {
    testWidgets("no tooltip: no Tooltip and the pill keeps its natural height", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: PillBadge(label: _label)));

      expect(find.byType(Tooltip), findsNothing);
      expect(tester.getSize(find.byType(PillBadge)).height, lessThan(kMinTapTarget));
    });

    testWidgets("an empty tooltip is treated as none", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: PillBadge(label: _label, tooltip: "")));

      expect(find.byType(Tooltip), findsNothing);
    });

    testWidgets("tap tooltip with a 48 dp hit area around the unchanged pill", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: PillBadge(label: _label, dense: true, tooltip: _tip)));

      final Tooltip tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.triggerMode, TooltipTriggerMode.tap);
      expect(tooltip.message, _tip);

      final Size pill = tester.getSize(_inBadge(find.byType(Container)));
      expect(pill.height, lessThan(kMinTapTarget));
      expect(tester.getSize(find.byType(PillBadge)), Size(math.max(pill.width, kMinTapTarget), kMinTapTarget));
      expect(_center(tester, _inBadge(find.byType(Container))), _center(tester, find.byType(PillBadge)));
    });

    testWidgets("a pill narrower than 48 dp gets a 48 x 48 hit area", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: PillBadge(label: "A", dense: true, tooltip: _tip)));

      expect(tester.getSize(_inBadge(find.byType(Container))).width, lessThan(kMinTapTarget));
      expect(tester.getSize(find.byType(PillBadge)), const Size(kMinTapTarget, kMinTapTarget));
    });

    testWidgets("the hit area hugs the pill in a start-aligned Column", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[PillBadge(label: _label, dense: true, tooltip: _tip)],
        ),
      );

      final Size pill = tester.getSize(_inBadge(find.byType(Container)));
      final Size area = tester.getSize(find.byType(PillBadge));
      expect(area, Size(math.max(pill.width, kMinTapTarget), kMinTapTarget));
      // The Column hands down a loose width as wide as the screen.
      expect(area.width, lessThan(tester.getSize(find.byType(Scaffold)).width));
    });

    testWidgets("tapping the pill shows the message", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: PillBadge(label: _label, tooltip: _tip)));

      expect(find.text(_tip), findsNothing);
      await tester.tap(find.text(_label));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(_tip), findsOneWidget);

      await _finishTooltipTimers(tester);
    });

    testWidgets("tapping the enlarged area outside the pill also shows the message", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: PillBadge(label: _label, dense: true, tooltip: _tip)));

      final Rect area = tester.getRect(find.byType(PillBadge));
      final Rect pill = tester.getRect(_inBadge(find.byType(Container)));
      final Offset outsidePill = Offset(area.center.dx, area.top + 2);
      expect(pill.contains(outsidePill), isFalse);

      await tester.tapAt(outsidePill);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(_tip), findsOneWidget);

      await _finishTooltipTimers(tester);
    });
  });

  group("semantics", () {
    testWidgets("the label is announced once", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const PillBadge(label: _label, icon: Icons.check));

      expect(find.bySemanticsLabel(_label), findsOneWidget);
      handle.dispose();
    });

    testWidgets("semanticsLabel replaces the visible label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const PillBadge(label: _label, semanticsLabel: "Status: ready"));

      expect(find.bySemanticsLabel("Status: ready"), findsOneWidget);
      expect(find.bySemanticsLabel(_label), findsNothing);
      handle.dispose();
    });

    testWidgets("an empty semanticsLabel falls back to the visible label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const PillBadge(label: _label, semanticsLabel: ""));

      expect(find.bySemanticsLabel(_label), findsOneWidget);
      handle.dispose();
    });

    testWidgets("two badges side by side keep separate labels", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const Row(
          children: <Widget>[
            PillBadge(label: "First"),
            PillBadge(label: "Second"),
          ],
        ),
      );

      expect(find.bySemanticsLabel("First"), findsOneWidget);
      expect(find.bySemanticsLabel("Second"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("a tooltip badge exposes its label and its tooltip", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const Center(child: PillBadge(label: _label, tooltip: _tip)));

      expect(find.bySemanticsLabel(_label), findsOneWidget);
      expect(tester.getSemantics(find.bySemanticsLabel(_label)).tooltip, _tip);
      handle.dispose();
    });
  });

  group("layout robustness", () {
    testWidgets("2x text scaling grows the pill and still fits a narrow parent", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: PillBadge(label: _label, icon: Icons.check)));
      final Size regular = tester.getSize(_inBadge(find.byType(Container)));

      await pumpApp(
        tester,
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Center(
            child: SizedBox(width: 60, child: PillBadge(label: _label, icon: Icons.check)),
          ),
        ),
      );
      final Size scaled = tester.getSize(_inBadge(find.byType(Container)));

      expect(tester.takeException(), isNull);
      expect(scaled.height, greaterThan(regular.height));
      // Still one line: a wrapped label would at least double the text height.
      expect(scaled.height, lessThan(regular.height * 2));
      expect(tester.getSize(find.byType(PillBadge)).width, lessThanOrEqualTo(60));
    });

    testWidgets("ellipsizes in a narrow parent instead of overflowing", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Center(
          child: SizedBox(
            width: 60,
            child: PillBadge(label: "A rather long label that cannot fit", icon: Icons.check),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(PillBadge)).width, lessThanOrEqualTo(60));
    });

    testWidgets("sits directly in a Row (unbounded width) without error", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[PillBadge(label: _label, icon: Icons.check)],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_label), findsOneWidget);
    });
  });

  group("dark theme", () {
    testWidgets("defaults follow the dark scheme and tones resolve per brightness", (WidgetTester tester) async {
      final Color lightSuccess = StatusTones.fromScheme(AppTheme.light().colorScheme).success.foreground;

      await pumpApp(tester, const PillBadge(label: _label, tone: StatusTone.success), theme: AppTheme.dark());
      final ColorScheme cs = _scheme(tester);

      expect(cs.brightness, Brightness.dark);
      expect(tester.takeException(), isNull);
      expect(_decoration(tester).color, cs.surface.withValues(alpha: 0.72));
      expect(_text(tester).style?.color, _tone(tester, StatusTone.success).foreground);
      expect(_text(tester).style?.color, isNot(lightSuccess));
    });
  });
}
