// collapsed_gate_group_test.dart
//
// Widget tests for CollapsedGateGroup: collapsed / expanded structure, the
// header toggle, initiallyExpanded, the pill fallback (group default, entry
// override, empty string), the call to action and its absence, default and
// custom texts, the empty list, motion and reduced motion, header and row
// semantics, the 48 dp targets, the ColorScheme tokens under the light
// and dark themes, the row layout at narrow widths and large text scales,
// and the real default strings (with {count}) through an in-memory
// translations singleton. That test resets the singleton, so the raw-key
// tests pass in any order.

// Localization.load and Translations are the only way to fill (and empty)
// the translations singleton that `.tr()` reads without an EasyLocalization
// tree; see the "real strings" test.
// ignore: implementation_imports
import "package:easy_localization/src/localization.dart";
// ignore: implementation_imports
import "package:easy_localization/src/translations.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/CollapsedGateGroup/index.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _summaryKey = "custom.collapsed_gate_group.summary";
const String _unlockKey = "custom.collapsed_gate_group.unlock_all";
const String _expandKey = "custom.collapsed_gate_group.expand";
const String _collapseKey = "custom.collapsed_gate_group.collapse";

const String _export = "Export";
const String _history = "History";
const String _sharing = "Sharing";

const List<GatedFeatureEntry> _features = <GatedFeatureEntry>[
  GatedFeatureEntry(label: _export, icon: Icons.download_outlined),
  GatedFeatureEntry(label: _history, icon: Icons.history),
  GatedFeatureEntry(label: _sharing, badgeLabel: "Max"),
];

CollapsedGateGroup _group({
  List<GatedFeatureEntry> features = _features,
  String? summary,
  String? badgeLabel = "Plus",
  String? actionLabel,
  VoidCallback? onAction,
  bool withAction = true,
  bool initiallyExpanded = false,
}) {
  return CollapsedGateGroup(
    features: features,
    summary: summary,
    badgeLabel: badgeLabel,
    actionLabel: actionLabel,
    onAction: withAction ? (onAction ?? () {}) : null,
    initiallyExpanded: initiallyExpanded,
  );
}

Finder _inGroup(Finder matching) {
  return find.descendant(of: find.byType(CollapsedGateGroup), matching: matching);
}

/// The header InkWell (the only InkWell besides the FilledButton's).
Finder _header() => _inGroup(find.byType(InkWell)).first;

Finder _groupMaterial() => _inGroup(find.byType(Material)).first;

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(CollapsedGateGroup))).colorScheme;
}

/// Wraps [child] in the ambient MediaQuery with reduced motion turned on.
Widget _reducedMotion(Widget child) {
  return Builder(
    builder: (BuildContext context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child,
    ),
  );
}

/// Wraps [child] in the ambient MediaQuery with a linear text [scale].
Widget _textScaled(Widget child, double scale) {
  return Builder(
    builder: (BuildContext context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
      child: child,
    ),
  );
}

Future<void> _expand(WidgetTester tester) async {
  await tester.tap(_header());
  await tester.pumpAndSettle();
}

void _expectTokens(WidgetTester tester) {
  final ColorScheme cs = _scheme(tester);
  final Material material = tester.widget<Material>(_groupMaterial());
  final RoundedRectangleBorder shape = material.shape! as RoundedRectangleBorder;

  expect(material.color, cs.surfaceContainerLow);
  expect(material.clipBehavior, Clip.antiAlias);
  expect(shape.borderRadius, BorderRadius.circular(8));
  expect(shape.side.color, cs.outlineVariant);
  expect(tester.widget<Text>(find.text(_summaryKey)).style?.color, cs.onSurfaceVariant);
  expect(tester.widget<Text>(find.text(_summaryKey)).style?.fontWeight, FontWeight.w600);
  expect(tester.widget<Text>(find.text(_export)).style?.color, cs.onSurface);
  expect(tester.widget<Icon>(find.byIcon(Icons.download_outlined)).color, cs.onSurfaceVariant);
  expect(tester.widget<Icon>(find.byIcon(Icons.keyboard_arrow_up_rounded)).color, cs.onSurfaceVariant);
  for (final Divider divider in tester.widgetList<Divider>(_inGroup(find.byType(Divider)))) {
    expect(divider.color, cs.outlineVariant);
  }
  for (final PillBadge pill in tester.widgetList<PillBadge>(find.byType(PillBadge))) {
    expect(pill.color, cs.onPrimary);
    expect(pill.backgroundColor, cs.primary);
  }
}

void main() {
  group("collapsed / expanded", () {
    testWidgets("collapsed by default: header only, rows and CTA hidden from taps and semantics", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _group());

      expect(find.text(_summaryKey), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
      expect(find.text(_export).hitTestable(), findsNothing);
      expect(find.byType(PillBadge).hitTestable(), findsNothing);
      expect(find.byType(FilledButton).hitTestable(), findsNothing);
      expect(find.bySemanticsLabel(RegExp(_export)), findsNothing);
      expect(find.bySemanticsLabel(_unlockKey), findsNothing);
      handle.dispose();
    });

    testWidgets("a header tap expands the list; a second tap collapses it", (WidgetTester tester) async {
      await pumpApp(tester, _group());

      await _expand(tester);
      for (final String label in <String>[_export, _history, _sharing]) {
        expect(find.text(label).hitTestable(), findsOneWidget);
      }
      expect(find.byType(FilledButton).hitTestable(), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);

      await tester.tap(_header());
      await tester.pumpAndSettle();
      expect(find.text(_export).hitTestable(), findsNothing);
      expect(find.byType(FilledButton).hitTestable(), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    });

    testWidgets("rows follow the entry order, each under the header and the divider", (WidgetTester tester) async {
      await pumpApp(tester, _group(initiallyExpanded: true));

      final double headerBottom = tester.getBottomLeft(_header()).dy;
      final double divider = tester.getTopLeft(_inGroup(find.byType(Divider)).first).dy;
      final double export = tester.getTopLeft(find.text(_export)).dy;
      final double history = tester.getTopLeft(find.text(_history)).dy;
      final double sharing = tester.getTopLeft(find.text(_sharing)).dy;
      final double button = tester.getTopLeft(find.byType(FilledButton)).dy;

      expect(divider, greaterThanOrEqualTo(headerBottom));
      expect(export, greaterThan(divider));
      expect(history, greaterThan(export));
      expect(sharing, greaterThan(history));
      expect(button, greaterThan(sharing));
    });

    testWidgets("initiallyExpanded shows the rows on the first frame", (WidgetTester tester) async {
      await pumpApp(tester, _group(initiallyExpanded: true));

      expect(find.text(_export).hitTestable(), findsOneWidget);
      expect(find.byType(FilledButton).hitTestable(), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
    });

    testWidgets("the expanded state survives a parent rebuild with new entries", (WidgetTester tester) async {
      await pumpApp(tester, _group());
      await _expand(tester);

      await pumpApp(tester, _group(features: const <GatedFeatureEntry>[GatedFeatureEntry(label: "Archive")]));
      await tester.pumpAndSettle();

      expect(find.text("Archive").hitTestable(), findsOneWidget);
      expect(find.text(_export), findsNothing);
    });

    testWidgets("an empty list renders nothing: no header, no Material, no InkWell", (WidgetTester tester) async {
      await pumpApp(tester, _group(features: const <GatedFeatureEntry>[]));

      expect(_inGroup(find.byType(Material)), findsNothing);
      expect(_inGroup(find.byType(InkWell)), findsNothing);
      expect(find.text(_summaryKey), findsNothing);
      expect(tester.getSize(find.byType(CollapsedGateGroup)), Size.zero);
    });
  });

  group("rows and pills", () {
    testWidgets("a pill that fits beside its label sits at the row end", (WidgetTester tester) async {
      await pumpApp(tester, _group(initiallyExpanded: true));

      final double contentRight = tester.getTopRight(_groupMaterial()).dx - kDefaultPadding * 2;
      for (final Element pill in find.byType(PillBadge).evaluate()) {
        expect(tester.getTopRight(find.byWidget(pill.widget)).dx, closeTo(contentRight, 1));
      }
      expect(
        tester.getCenter(find.text("Max")).dy,
        closeTo(tester.getCenter(find.text(_sharing)).dy, 1),
      );
    });

    testWidgets("pills: group default, entry override; dense PillBadge with a lock icon", (WidgetTester tester) async {
      await pumpApp(tester, _group(initiallyExpanded: true));

      expect(find.text("Plus"), findsNWidgets(2));
      expect(find.text("Max"), findsOneWidget);
      final List<PillBadge> pills = tester.widgetList<PillBadge>(find.byType(PillBadge)).toList();
      expect(pills.map((PillBadge p) => p.label), <String>["Plus", "Plus", "Max"]);
      for (final PillBadge pill in pills) {
        expect(pill.dense, isTrue);
        expect(pill.icon, Icons.lock_outline_rounded);
        expect(pill.tooltip, isNull);
      }
      final Finder sharingRow = find.ancestor(of: find.text(_sharing), matching: find.byType(Row)).first;
      expect(find.descendant(of: sharingRow, matching: find.text("Max")), findsOneWidget);
      expect(
        tester.getTopLeft(find.text("Max")).dx,
        greaterThan(tester.getTopRight(find.text(_sharing)).dx),
      );
    });

    testWidgets("no pill when both labels are null, or when the entry passes an empty string", (WidgetTester tester) async {
      await pumpApp(tester, _group(badgeLabel: null, initiallyExpanded: true));
      expect(find.byType(PillBadge), findsOneWidget);
      expect(find.text("Max"), findsOneWidget);

      await pumpApp(
        tester,
        _group(
          badgeLabel: "Plus",
          initiallyExpanded: true,
          features: const <GatedFeatureEntry>[
            GatedFeatureEntry(label: _export, badgeLabel: ""),
            GatedFeatureEntry(label: _history),
          ],
        ),
      );
      expect(find.byType(PillBadge), findsOneWidget);
      final Finder historyRow = find.ancestor(of: find.text(_history), matching: find.byType(Row)).first;
      expect(find.descendant(of: historyRow, matching: find.byType(PillBadge)), findsOneWidget);

      await pumpApp(
        tester,
        _group(
          badgeLabel: "",
          initiallyExpanded: true,
          features: const <GatedFeatureEntry>[GatedFeatureEntry(label: _export)],
        ),
      );
      expect(find.byType(PillBadge), findsNothing);
    });

    testWidgets("entry icons render (default lock), the header keeps its own lock", (WidgetTester tester) async {
      await pumpApp(tester, _group(initiallyExpanded: true));

      expect(find.byIcon(Icons.download_outlined), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(tester.widget<Icon>(find.byIcon(Icons.history)).size, 16);
      // Header lock + default icon of "Sharing" (pills draw their own via
      // PillBadge, counted separately).
      final int pillLocks = find
          .descendant(of: find.byType(PillBadge), matching: find.byIcon(Icons.lock_outline_rounded))
          .evaluate()
          .length;
      expect(find.byIcon(Icons.lock_outline_rounded).evaluate().length - pillLocks, 2);
    });
  });

  group("call to action", () {
    testWidgets("onAction is called exactly once per tap", (WidgetTester tester) async {
      int calls = 0;
      await pumpApp(tester, _group(onAction: () => calls++));
      await _expand(tester);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets("onAction null: no button and a single divider, even when expanded", (WidgetTester tester) async {
      await pumpApp(tester, _group(withAction: false, initiallyExpanded: true));

      expect(find.byType(FilledButton), findsNothing);
      expect(find.text(_unlockKey), findsNothing);
      expect(_inGroup(find.byType(Divider)), findsOneWidget);
    });

    testWidgets("with onAction: two dividers and a full-width button", (WidgetTester tester) async {
      await pumpApp(tester, _group(initiallyExpanded: true));

      expect(_inGroup(find.byType(Divider)), findsNWidgets(2));
      final double groupWidth = tester.getSize(_groupMaterial()).width;
      expect(tester.getSize(find.byType(FilledButton)).width, closeTo(groupWidth - kDefaultPadding * 4, 1));
    });
  });

  group("texts", () {
    testWidgets("real strings: the default summary interpolates {count}", (WidgetTester tester) async {
      addTearDown(() => Localization.load(const Locale("fr")));
      Localization.load(
        const Locale("en"),
        translations: Translations(<String, dynamic>{
          "custom": <String, dynamic>{
            "collapsed_gate_group": <String, String>{
              "summary": "Locked features ({count})",
              "unlock_all": "Unlock all",
              "expand": "Show features",
              "collapse": "Hide features",
            },
          },
        }),
      );
      await pumpApp(tester, _group(initiallyExpanded: true));

      expect(find.text("Locked features (3)"), findsOneWidget);
      expect(find.text("Unlock all"), findsOneWidget);
      expect(find.text(_summaryKey), findsNothing);
    });

    testWidgets("defaults: the summary and CTA keys (pumpApp returns raw keys)", (WidgetTester tester) async {
      await pumpApp(tester, _group(initiallyExpanded: true));

      expect(find.text(_summaryKey), findsOneWidget);
      expect(find.text(_unlockKey), findsOneWidget);
    });

    testWidgets("a custom summary and actionLabel replace the defaults; empty strings fall back", (WidgetTester tester) async {
      await pumpApp(tester, _group(summary: "3 locked", actionLabel: "See plans", initiallyExpanded: true));
      expect(find.text("3 locked"), findsOneWidget);
      expect(find.text("See plans"), findsOneWidget);
      expect(find.text(_summaryKey), findsNothing);
      expect(find.text(_unlockKey), findsNothing);

      await pumpApp(tester, _group(summary: "", actionLabel: "", initiallyExpanded: true));
      expect(find.text(_summaryKey), findsOneWidget);
      expect(find.text(_unlockKey), findsOneWidget);
    });
  });

  group("motion", () {
    testWidgets("the cross-fade uses kMotionShort and easeOutCubic", (WidgetTester tester) async {
      await pumpApp(tester, _group());

      final AnimatedCrossFade fade = tester.widget<AnimatedCrossFade>(_inGroup(find.byType(AnimatedCrossFade)));
      expect(fade.duration, kMotionShort);
      expect(fade.sizeCurve, Curves.easeOutCubic);
      expect(fade.firstCurve, Curves.easeOutCubic);
      expect(fade.secondCurve, Curves.easeOutCubic);
      expect(fade.crossFadeState, CrossFadeState.showFirst);
    });

    testWidgets("the group grows progressively while expanding", (WidgetTester tester) async {
      await pumpApp(tester, _group());
      final double collapsed = tester.getSize(_groupMaterial()).height;

      await tester.tap(_header());
      await tester.pump();
      await tester.pump(kMotionShort ~/ 2);
      final double halfway = tester.getSize(_groupMaterial()).height;
      await tester.pumpAndSettle();
      final double expanded = tester.getSize(_groupMaterial()).height;

      expect(halfway, greaterThan(collapsed));
      expect(halfway, lessThan(expanded));
    });

    testWidgets("reduced motion: no cross-fade, content shows and hides in one frame", (WidgetTester tester) async {
      await pumpApp(tester, _reducedMotion(_group()));
      final double collapsed = tester.getSize(_groupMaterial()).height;

      expect(_inGroup(find.byType(AnimatedCrossFade)), findsNothing);
      expect(find.text(_export), findsNothing);

      await tester.tap(_header());
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text(_export).hitTestable(), findsOneWidget);
      expect(find.byType(FilledButton).hitTestable(), findsOneWidget);
      final double afterOneFrame = tester.getSize(_groupMaterial()).height;
      await tester.pumpAndSettle();
      expect(tester.getSize(_groupMaterial()).height, afterOneFrame);

      await tester.tap(_header());
      await tester.pump();
      expect(find.text(_export), findsNothing);
      expect(tester.getSize(_groupMaterial()).height, collapsed);
    });
  });

  group("accessibility", () {
    testWidgets("header: button with expanded state and the expand / collapse hints", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _group());

      expect(
        tester.getSemantics(find.text(_summaryKey)),
        isSemantics(
          label: _summaryKey,
          isButton: true,
          hasExpandedState: true,
          isExpanded: false,
          hasTapAction: true,
          onTapHint: _expandKey,
        ),
      );

      await _expand(tester);
      expect(
        tester.getSemantics(find.text(_summaryKey)),
        isSemantics(
          label: _summaryKey,
          isButton: true,
          hasExpandedState: true,
          isExpanded: true,
          hasTapAction: true,
          onTapHint: _collapseKey,
        ),
      );
      handle.dispose();
    });

    testWidgets("each row reads as one node: label then pill", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _group(initiallyExpanded: true));

      expect(find.bySemanticsLabel("$_export\nPlus"), findsOneWidget);
      expect(find.bySemanticsLabel("$_sharing\nMax"), findsOneWidget);
      expect(find.bySemanticsLabel(_unlockKey), findsOneWidget);
      handle.dispose();
    });

    testWidgets("header and CTA are at least 48 dp tall; tap-target guidelines pass", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _group(initiallyExpanded: true));

      expect(tester.getSize(_header()).height, greaterThanOrEqualTo(kMinTapTarget));
      expect(tester.getSize(find.byType(FilledButton)).height, greaterThanOrEqualTo(kMinTapTarget));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });

  group("theme", () {
    testWidgets("light theme: ColorScheme tokens", (WidgetTester tester) async {
      await pumpApp(tester, _group(initiallyExpanded: true));

      _expectTokens(tester);
    });

    testWidgets("dark theme: renders without exceptions with the same tokens", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _group(initiallyExpanded: true), theme: AppTheme.dark());

      expect(tester.takeException(), isNull);
      expect(_scheme(tester).brightness, Brightness.dark);
      _expectTokens(tester);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets("narrow width: long texts wrap without overflow", (WidgetTester tester) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 200,
          child: _group(
            summary: "A rather long summary that needs more than one line",
            initiallyExpanded: true,
            features: const <GatedFeatureEntry>[
              GatedFeatureEntry(label: "A feature label long enough to wrap", badgeLabel: "Plus"),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    // A wide pill used to squeeze the label to 0 dp and overflow the row.
    for (final (double width, double scale) in <(double, double)>[(200, 1), (240, 1), (320, 2), (360, 2)]) {
      testWidgets("narrow row ($width dp, text x$scale): a wide pill moves under its label", (WidgetTester tester) async {
        const String label = "Advanced export";
        await pumpApp(
          tester,
          _textScaled(
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: _group(
                  badgeLabel: "Enterprise",
                  initiallyExpanded: true,
                  features: const <GatedFeatureEntry>[GatedFeatureEntry(label: label)],
                ),
              ),
            ),
            scale,
          ),
          surfaceSize: const Size(800, 2000),
        );

        expect(tester.takeException(), isNull);
        final Rect group = tester.getRect(_groupMaterial());
        final Rect text = tester.getRect(find.text(label));
        final Rect pill = tester.getRect(find.byType(PillBadge));
        expect(text.width, greaterThan(group.width / 2));
        expect(pill.top, greaterThanOrEqualTo(text.bottom));
        expect(pill.right, lessThanOrEqualTo(group.right));
      });
    }
  });
}
