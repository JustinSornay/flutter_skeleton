// version_badge_test.dart
//
// Widget tests for VersionBadge: current / outdated icon and ColorScheme
// tokens through PillBadge, compact / large padding, tappability rules, the
// 48 dp hit area, semantics, the details panel handed to the host (title,
// body, outdated notice in warning tones, optional "learn more" button and
// its 48 dp hit area on every platform), mounting in AppModal and a bottom
// sheet, and the dark theme.

import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";
import "package:flutter_skeleton/widgets/custom/VersionBadge/index.dart";
import "package:flutter_skeleton/widgets/layout/AppModal/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _label = "v2.4";
const String _title = "Computed with release 2.4";
const String _body = "Values are computed by the release named on the badge.";
const String _notice = "A newer release is available.";
const String _currentKey = "custom.version_badge.current";
const String _outdatedKey = "custom.version_badge.outdated";
const String _learnMoreKey = "custom.version_badge.learn_more";

Finder _inBadge(Finder matching) {
  return find.descendant(of: find.byType(VersionBadge), matching: matching);
}

ColorScheme _scheme(WidgetTester tester, Finder finder) {
  return Theme.of(tester.element(finder)).colorScheme;
}

Text _labelText(WidgetTester tester) => tester.widget<Text>(find.text(_label));

/// The pill Container drawn by PillBadge.
Container _pill(WidgetTester tester) => tester.widget<Container>(_inBadge(find.byType(Container)));

/// Pumps a tappable badge, taps it and returns the panel it handed over.
Future<Widget> _openPanel(
  WidgetTester tester, {
  bool isCurrent = true,
  VersionBadgeDetails details = const VersionBadgeDetails(title: _title, body: _body),
}) async {
  final List<Widget> panels = <Widget>[];
  await pumpApp(
    tester,
    Center(
      child: VersionBadge(
        label: _label,
        isCurrent: isCurrent,
        details: details,
        onShowDetails: panels.add,
      ),
    ),
  );
  await tester.tap(find.byType(VersionBadge));
  await tester.pump();
  expect(panels, hasLength(1));
  return panels.single;
}

/// Opens the panel and pumps it as the page body.
Future<void> _pumpPanel(
  WidgetTester tester, {
  bool isCurrent = true,
  VersionBadgeDetails details = const VersionBadgeDetails(title: _title, body: _body),
  ThemeData? theme,
}) async {
  final Widget panel = await _openPanel(tester, isCurrent: isCurrent, details: details);
  await pumpApp(tester, panel, theme: theme);
}

void main() {
  group("pill", () {
    testWidgets("current: label, verified icon and cs.primary", (WidgetTester tester) async {
      await pumpApp(tester, const VersionBadge(label: _label));
      final ColorScheme cs = _scheme(tester, find.byType(VersionBadge));

      expect(find.text(_label), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
      expect(find.byIcon(Icons.history), findsNothing);
      expect(_labelText(tester).style?.color, cs.primary);
      expect(tester.widget<Icon>(find.byIcon(Icons.verified_outlined)).color, cs.primary);
    });

    testWidgets("outdated: history icon and cs.onSurfaceVariant", (WidgetTester tester) async {
      await pumpApp(tester, const VersionBadge(label: _label, isCurrent: false));
      final ColorScheme cs = _scheme(tester, find.byType(VersionBadge));

      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.verified_outlined), findsNothing);
      expect(_labelText(tester).style?.color, cs.onSurfaceVariant);
      expect(tester.widget<Icon>(find.byIcon(Icons.history)).color, cs.onSurfaceVariant);
    });

    testWidgets("is an outlined PillBadge with primary / neutral tones", (WidgetTester tester) async {
      await pumpApp(tester, const VersionBadge(label: _label));
      PillBadge badge = tester.widget<PillBadge>(find.byType(PillBadge));
      expect(badge.outlined, isTrue);
      expect(badge.tone, StatusTone.primary);
      expect(badge.label, _label);

      await pumpApp(tester, const VersionBadge(label: _label, isCurrent: false));
      badge = tester.widget<PillBadge>(find.byType(PillBadge));
      expect(badge.tone, StatusTone.neutral);

      final ColorScheme cs = _scheme(tester, find.byType(VersionBadge));
      final BoxDecoration decoration = _pill(tester).decoration! as BoxDecoration;
      expect(decoration.color, cs.surfaceContainerHigh);
      expect(decoration.border, Border.all(color: cs.outlineVariant));
      expect(decoration.borderRadius, BorderRadius.circular(999));
    });

    testWidgets("compact is dense (8 / 4), large uses 12 / 8 and is bigger", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: VersionBadge(label: _label)));
      expect(tester.widget<PillBadge>(find.byType(PillBadge)).dense, isTrue);
      expect(_pill(tester).padding, const EdgeInsets.symmetric(horizontal: 8, vertical: 4));
      final Size compact = tester.getSize(find.byType(VersionBadge));

      await pumpApp(tester, const Center(child: VersionBadge(label: _label, size: VersionBadgeSize.large)));
      expect(tester.widget<PillBadge>(find.byType(PillBadge)).dense, isFalse);
      expect(_pill(tester).padding, const EdgeInsets.symmetric(horizontal: 12, vertical: 8));
      final Size large = tester.getSize(find.byType(VersionBadge));

      expect(large.width, greaterThan(compact.width));
      expect(large.height, greaterThan(compact.height));
    });
  });

  group("tappability", () {
    testWidgets("not tappable without details: no InkWell, natural height", (WidgetTester tester) async {
      int calls = 0;
      await pumpApp(
        tester,
        Center(child: VersionBadge(label: _label, onShowDetails: (Widget _) => calls++)),
      );

      expect(_inBadge(find.byType(InkWell)), findsNothing);
      expect(tester.getSize(find.byType(VersionBadge)).height, lessThan(kMinTapTarget));
      await tester.tap(find.byType(VersionBadge), warnIfMissed: false);
      await tester.pump();
      expect(calls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets("not tappable without onShowDetails", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Center(
          child: VersionBadge(
            label: _label,
            details: VersionBadgeDetails(title: _title, body: _body),
          ),
        ),
      );

      expect(_inBadge(find.byType(InkWell)), findsNothing);
      await tester.tap(find.byType(VersionBadge), warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets("a tap hands one panel widget to the host", (WidgetTester tester) async {
      final Widget panel = await _openPanel(tester);

      expect(panel, isA<Widget>());
      // The badge itself does not mount anything.
      expect(find.text(_title), findsNothing);
    });

    testWidgets("hit area is at least 48 x 48 around the centred pill", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Center(
          child: VersionBadge(
            label: "A",
            details: const VersionBadgeDetails(title: _title, body: _body),
            onShowDetails: (Widget _) {},
          ),
        ),
      );

      final Size pill = tester.getSize(_inBadge(find.byType(Container)));
      final Size area = tester.getSize(_inBadge(find.byType(InkWell)));
      expect(pill.height, lessThan(kMinTapTarget));
      expect(area, Size(math.max(pill.width, kMinTapTarget), kMinTapTarget));
      expect(
        tester.getCenter(_inBadge(find.byType(Container))),
        tester.getCenter(_inBadge(find.byType(InkWell))),
      );
    });

    testWidgets("tapping the enlarged area outside the pill opens the panel", (WidgetTester tester) async {
      int calls = 0;
      await pumpApp(
        tester,
        Center(
          child: VersionBadge(
            label: _label,
            details: const VersionBadgeDetails(title: _title, body: _body),
            onShowDetails: (Widget _) => calls++,
          ),
        ),
      );

      final Rect area = tester.getRect(_inBadge(find.byType(InkWell)));
      final Rect pill = tester.getRect(_inBadge(find.byType(Container)));
      final Offset outsidePill = Offset(area.center.dx, area.top + 4);
      expect(pill.contains(outsidePill), isFalse);

      await tester.tapAt(outsidePill);
      await tester.pump();
      expect(calls, 1);
    });

    testWidgets("the hit area hugs the pill in a start-aligned Column", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            VersionBadge(
              label: _label,
              details: const VersionBadgeDetails(title: _title, body: _body),
              onShowDetails: (Widget _) {},
            ),
          ],
        ),
      );

      final Size pill = tester.getSize(_inBadge(find.byType(Container)));
      expect(
        tester.getSize(find.byType(VersionBadge)),
        Size(math.max(pill.width, kMinTapTarget), kMinTapTarget),
      );
    });
  });

  group("semantics", () {
    testWidgets("default label adds the current state, not a button", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const VersionBadge(label: _label));

      final Finder node = find.bySemanticsLabel("$_label, $_currentKey");
      expect(node, findsOneWidget);
      expect(tester.getSemantics(node), isSemantics(isButton: false, hasTapAction: false));
      handle.dispose();
    });

    testWidgets("default label adds the outdated state", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const VersionBadge(label: _label, isCurrent: false));

      expect(find.bySemanticsLabel("$_label, $_outdatedKey"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("semanticsLabel overrides the default, empty falls back", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const VersionBadge(label: _label, semanticsLabel: "Release 2.4, latest"));
      expect(find.bySemanticsLabel("Release 2.4, latest"), findsOneWidget);
      expect(find.bySemanticsLabel("$_label, $_currentKey"), findsNothing);

      await pumpApp(tester, const VersionBadge(label: _label, semanticsLabel: ""));
      expect(find.bySemanticsLabel("$_label, $_currentKey"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("tappable badge is one button node with a tap action", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        Center(
          child: VersionBadge(
            label: _label,
            details: const VersionBadgeDetails(title: _title, body: _body),
            onShowDetails: (Widget _) {},
          ),
        ),
      );

      final Finder node = find.bySemanticsLabel("$_label, $_currentKey");
      expect(node, findsOneWidget);
      expect(tester.getSemantics(node), isSemantics(isButton: true, hasTapAction: true));
      handle.dispose();
    });
  });

  group("details panel", () {
    testWidgets("shows the title as a header and the body", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpPanel(tester);
      final ColorScheme cs = _scheme(tester, find.text(_title));

      final Text title = tester.widget<Text>(find.text(_title));
      expect(title.style?.fontSize, 18);
      expect(title.style?.fontWeight, FontWeight.w600);
      expect(title.style?.color, cs.onSurface);
      final Text body = tester.widget<Text>(find.text(_body));
      expect(body.style?.fontSize, 14);
      expect(body.style?.height, 1.4);
      expect(tester.getSemantics(find.text(_title)), isSemantics(isHeader: true, label: _title));
      handle.dispose();
    });

    testWidgets("no notice and no button by default", (WidgetTester tester) async {
      await _pumpPanel(tester, isCurrent: false);

      expect(find.byType(TextButton), findsNothing);
      expect(find.text(_learnMoreKey), findsNothing);
      expect(find.text(_notice), findsNothing);
    });

    testWidgets("outdated: notice in warning container tones", (WidgetTester tester) async {
      await _pumpPanel(
        tester,
        isCurrent: false,
        details: const VersionBadgeDetails(title: _title, body: _body, outdatedNotice: _notice),
      );

      expect(find.text(_notice), findsOneWidget);
      final ToneColors warning = StatusTones.colorsOf(tester.element(find.text(_notice)), StatusTone.warning);
      final Container box = tester.widget<Container>(
        find.ancestor(of: find.text(_notice), matching: find.byType(Container)).first,
      );
      final BoxDecoration decoration = box.decoration! as BoxDecoration;
      expect(decoration.color, warning.container);
      expect(decoration.borderRadius, BorderRadius.circular(8));
      expect(box.padding, const EdgeInsets.all(12));
      final Text text = tester.widget<Text>(find.text(_notice));
      expect(text.style?.color, warning.onContainer);
      expect(text.style?.fontSize, 13);
    });

    testWidgets("current: the notice is hidden even when set", (WidgetTester tester) async {
      await _pumpPanel(
        tester,
        details: const VersionBadgeDetails(title: _title, body: _body, outdatedNotice: _notice),
      );

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_notice), findsNothing);
    });

    testWidgets("an empty notice draws no callout", (WidgetTester tester) async {
      await _pumpPanel(
        tester,
        isCurrent: false,
        details: const VersionBadgeDetails(title: _title, body: _body, outdatedNotice: ""),
      );

      final Finder boxes = find.descendant(of: find.byType(SingleChildScrollView), matching: find.byType(Container));
      expect(boxes, findsNothing);
    });

    testWidgets("learn more: default key, open_in_new icon, one call", (WidgetTester tester) async {
      int calls = 0;
      await _pumpPanel(
        tester,
        details: VersionBadgeDetails(title: _title, body: _body, onLearnMore: () => calls++),
      );

      expect(find.text(_learnMoreKey), findsOneWidget);
      final Icon icon = tester.widget<Icon>(find.byIcon(Icons.open_in_new));
      expect(icon.size, 16);

      await tester.tap(find.text(_learnMoreKey));
      await tester.pump();
      expect(calls, 1);
    });

    testWidgets(
      "learn more: hit area ≥ kMinTapTarget on every platform",
      (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await _pumpPanel(
          tester,
          details: VersionBadgeDetails(title: _title, body: _body, onLearnMore: () {}),
        );

        expect(tester.getSize(find.byType(TextButton)).height, greaterThanOrEqualTo(kMinTapTarget));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      },
      variant: TargetPlatformVariant.all(),
    );

    testWidgets("learnMoreLabel replaces the default, empty falls back", (WidgetTester tester) async {
      await _pumpPanel(
        tester,
        details: VersionBadgeDetails(title: _title, body: _body, learnMoreLabel: "Read the notes", onLearnMore: () {}),
      );
      expect(find.text("Read the notes"), findsOneWidget);
      expect(find.text(_learnMoreKey), findsNothing);

      await _pumpPanel(
        tester,
        details: VersionBadgeDetails(title: _title, body: _body, learnMoreLabel: "", onLearnMore: () {}),
      );
      expect(find.text(_learnMoreKey), findsOneWidget);
    });

    testWidgets("a long body scrolls instead of overflowing", (WidgetTester tester) async {
      await _pumpPanel(
        tester,
        details: VersionBadgeDetails(title: _title, body: List<String>.filled(400, "word").join(" ")),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group("hosting", () {
    testWidgets("the panel mounts in an AppModal card", (WidgetTester tester) async {
      final Widget panel = await _openPanel(
        tester,
        isCurrent: false,
        details: const VersionBadgeDetails(title: _title, body: _body, outdatedNotice: _notice),
      );
      await pumpApp(tester, AppModal(isVisible: true, onDismiss: () {}, child: panel));
      await tester.pumpAndSettle();

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_notice), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("the panel mounts in a bottom sheet opened by the host", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => Center(
            child: VersionBadge(
              label: _label,
              details: const VersionBadgeDetails(title: _title, body: _body),
              onShowDetails: (Widget panel) => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (BuildContext _) => panel,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(VersionBadge));
      await tester.pumpAndSettle();
      expect(find.text(_title), findsOneWidget);
      expect(find.text(_body), findsOneWidget);
    });
  });

  group("dark theme", () {
    testWidgets("badge and panel read the dark scheme and tones", (WidgetTester tester) async {
      await pumpApp(tester, const VersionBadge(label: _label), theme: AppTheme.dark());
      final ColorScheme cs = _scheme(tester, find.byType(VersionBadge));
      expect(cs.brightness, Brightness.dark);
      expect(_labelText(tester).style?.color, cs.primary);

      await _pumpPanel(
        tester,
        isCurrent: false,
        details: const VersionBadgeDetails(title: _title, body: _body, outdatedNotice: _notice),
        theme: AppTheme.dark(),
      );
      final ColorScheme panelScheme = _scheme(tester, find.text(_title));
      expect(panelScheme.brightness, Brightness.dark);
      expect(tester.widget<Text>(find.text(_title)).style?.color, panelScheme.onSurface);
      final ToneColors warning = StatusTones.colorsOf(tester.element(find.text(_notice)), StatusTone.warning);
      expect(tester.widget<Text>(find.text(_notice)).style?.color, warning.onContainer);
      expect(tester.takeException(), isNull);
    });
  });
}
