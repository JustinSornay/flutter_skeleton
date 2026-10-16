// comparison_panel_test.dart
//
// Widget tests for ComparisonPanel: the collapsed summary header (tags,
// titles, subtitles), the expanded detail (legend, ComparisonBar rows in the
// side colours, change callout with emphasised values), the toggle / cancel
// / confirm callbacks, the disabled confirm, label overrides, the inert
// header without detail, reduced motion, header semantics (focusable
// button), tap targets, the card / header / divider / chevron colours, long
// titles at 320 dp in light and dark, and the real fr / en strings through an
// in-memory EasyLocalization. The localized tests reset the easy_localization
// singleton, so the raw-key tests pass in any order.

import "package:easy_localization/easy_localization.dart";
// Localization.load is the only way to empty the translations singleton that
// EasyLocalization fills; see _pumpLocalized.
// ignore: implementation_imports
import "package:easy_localization/src/localization.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/custom/ComparisonBar/index.dart";
import "package:flutter_skeleton/widgets/custom/ComparisonPanel/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _summaryKey = "custom.comparison_panel.summary_semantics";
const String _showKey = "custom.comparison_panel.show_details";
const String _hideKey = "custom.comparison_panel.hide_details";
const String _cancelKey = "custom.comparison_panel.cancel";
const String _confirmKey = "custom.comparison_panel.confirm";

const ComparisonSide _current = ComparisonSide(tag: "Current", title: "Plan A", subtitle: "55% · Fair");
const ComparisonSide _candidate = ComparisonSide(tag: "Tested", title: "Plan B", subtitle: "72% · Good");

const ComparisonChange _change = ComparisonChange(label: "Main constraint", from: "cost", to: "latency");

String _percent(double value) => "${value.round()}%";

String _count(double value) => "${value.round()}";

final List<ComparisonMetric> _metrics = <ComparisonMetric>[
  const ComparisonMetric(label: "Overall", current: 55, candidate: 72, max: 100, format: _percent),
  const ComparisonMetric(label: "Speed", current: 40, candidate: 65, max: 100, format: _count),
  const ComparisonMetric(
    label: "Incidents",
    sublabel: "per month",
    current: 4,
    candidate: 2,
    max: 12,
    lowerIsBetter: true,
    format: _count,
  ),
];

ComparisonPanel _panel({
  ComparisonSide current = _current,
  ComparisonSide candidate = _candidate,
  List<ComparisonMetric>? metrics,
  ComparisonChange? change,
  bool isExpanded = false,
  VoidCallback? onToggle,
}) {
  return ComparisonPanel(
    current: current,
    candidate: candidate,
    metrics: metrics ?? _metrics,
    change: change,
    isExpanded: isExpanded,
    onToggle: onToggle ?? () {},
    onCancel: () {},
    onConfirm: () {},
  );
}

/// Collapsed panel for the action row tests.
ComparisonPanel _actionPanel({
  VoidCallback? onCancel,
  VoidCallback? onConfirm,
  bool confirmEnabled = true,
  String? confirmLabel,
  String? cancelLabel,
}) {
  return ComparisonPanel(
    current: _current,
    candidate: _candidate,
    metrics: _metrics,
    isExpanded: false,
    onToggle: () {},
    onCancel: onCancel ?? () {},
    onConfirm: confirmEnabled ? (onConfirm ?? () {}) : null,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
  );
}

Future<void> _pump(WidgetTester tester, Widget panel, {Size surfaceSize = const Size(480, 800), ThemeData? theme}) {
  return pumpApp(
    tester,
    Align(alignment: Alignment.topCenter, child: panel),
    surfaceSize: surfaceSize,
    theme: theme,
  );
}

/// Forces `MediaQueryData.disableAnimations` for [child].
Widget _reducedMotion(Widget child) {
  return Builder(
    builder: (BuildContext context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child,
    ),
  );
}

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(ComparisonPanel))).colorScheme;

/// The header's semantics node (found through its raw summary key).
Finder get _header => find.bySemanticsLabel(_summaryKey);

/// The callout Text.rich: the only rich text whose root span is styled
/// (the ComparisonBar readouts style their runs only).
Finder get _callout {
  return find.byWidgetPredicate(
    (Widget widget) => widget is Text && widget.textSpan?.style?.fontWeight == FontWeight.w600,
  );
}

/// [icon] inside the callout row (ComparisonBar rows use tone icons too).
Finder _calloutIcon(IconData icon) {
  return find.descendant(
    of: find.ancestor(of: _callout, matching: find.byType(Row)).first,
    matching: find.byIcon(icon),
  );
}

List<TextSpan> _calloutSpans(WidgetTester tester) {
  final InlineSpan? root = tester.widget<Text>(_callout).textSpan;
  final List<InlineSpan> children = root is TextSpan ? root.children ?? const <InlineSpan>[] : const <InlineSpan>[];
  return children.whereType<TextSpan>().toList();
}

/// In-memory translations matching the i18n fragment, so the real strings
/// can be checked before the fragment is merged into assets.
final class _MemoryLoader extends AssetLoader {
  const _MemoryLoader({this.callout});

  /// Replaces the callout template of both locales when set.
  final String? callout;

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final bool fr = locale.languageCode == "fr";
    return <String, dynamic>{
      "custom": <String, dynamic>{
        "comparison_panel": <String, dynamic>{
          "cancel": fr ? "Annuler" : "Cancel",
          "confirm": fr ? "Confirmer" : "Confirm",
          "show_details": fr ? "Afficher le détail" : "Show details",
          "hide_details": fr ? "Masquer le détail" : "Hide details",
          "callout": callout ?? (fr ? "{label} : {from} → {to}" : "{label}: {from} → {to}"),
          "summary_semantics": fr ? "{current} comparé à {candidate}" : "{current} compared with {candidate}",
        },
      },
    };
  }
}

/// Pumps [child] under EasyLocalization with [loader]. The loaded
/// translations live in a singleton that outlives the test; the tear-down
/// empties it so every later `.tr()` returns the raw key again, whatever the
/// test order.
Future<void> _pumpLocalized(
  WidgetTester tester,
  Locale locale,
  Widget child, {
  AssetLoader loader = const _MemoryLoader(),
}) async {
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
      assetLoader: loader,
      child: Builder(
        builder: (BuildContext context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.light(),
          home: Scaffold(body: Align(alignment: Alignment.topCenter, child: child)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  _summaryHeaderTests();
  _detailTests();
  _actionTests();
  _semanticsTests();
  _motionTests();
  _visualTests();
  _layoutTests();
  _localizedTests();
}

void _summaryHeaderTests() {
  group("summary header", () {
    testWidgets("collapsed: shows both sides, no detail", (WidgetTester tester) async {
      await _pump(tester, _panel(change: _change));

      expect(find.text("CURRENT"), findsOneWidget);
      expect(find.text("TESTED"), findsOneWidget);
      expect(find.text("Plan A"), findsOneWidget);
      expect(find.text("Plan B"), findsOneWidget);
      expect(find.text("55% · Fair"), findsOneWidget);
      expect(find.text("72% · Good"), findsOneWidget);
      expect(find.byType(ComparisonBar), findsNothing);
      expect(find.textContaining("Main constraint", findRichText: true), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz), findsNWidgets(2));
    });

    testWidgets("tags are uppercased in the header and kept as given in the legend", (WidgetTester tester) async {
      await _pump(
        tester,
        _panel(
          current: const ComparisonSide(tag: "Today", title: "Plan A"),
          candidate: const ComparisonSide(tag: "Proposal", title: "Plan B"),
          isExpanded: true,
        ),
      );

      expect(find.text("TODAY"), findsOneWidget);
      expect(find.text("PROPOSAL"), findsOneWidget);
      expect(find.text("Today"), findsOneWidget);
      expect(find.text("Proposal"), findsOneWidget);
    });

    testWidgets("hides the subtitle when null", (WidgetTester tester) async {
      await _pump(
        tester,
        _panel(
          current: const ComparisonSide(tag: "Current", title: "Plan A"),
          candidate: const ComparisonSide(tag: "Tested", title: "Plan B"),
        ),
      );

      expect(find.text("55% · Fair"), findsNothing);
      expect(find.text("72% · Good"), findsNothing);
    });

    testWidgets("side colours: current tag primary, candidate tag tertiary", (WidgetTester tester) async {
      await _pump(tester, _panel());
      final ColorScheme cs = _scheme(tester);

      expect(tester.widget<Text>(find.text("CURRENT")).style?.color, cs.primary);
      expect(tester.widget<Text>(find.text("TESTED")).style?.color, cs.tertiary);
      expect(tester.widget<Text>(find.text("Plan A")).style?.color, cs.onSurface);
      expect(tester.widget<Text>(find.text("55% · Fair")).style?.color, cs.onSurfaceVariant);
    });

    testWidgets("tapping the header calls onToggle once", (WidgetTester tester) async {
      int toggles = 0;
      await _pump(tester, _panel(onToggle: () => toggles++));

      await tester.tap(find.text("Plan A"));
      await tester.pump();

      expect(toggles, 1);
    });

    testWidgets("the chevron turns half a turn when expanded", (WidgetTester tester) async {
      await _pump(tester, _panel());
      expect(tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns, 0);

      await _pump(tester, _panel(isExpanded: true));
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns, 0.5);
    });
  });
}

void _detailTests() {
  group("detail", () {
    testWidgets("expanded: one ComparisonBar per metric, labels and legend", (WidgetTester tester) async {
      await _pump(tester, _panel(isExpanded: true));
      await tester.pumpAndSettle();

      expect(find.byType(ComparisonBar), findsNWidgets(3));
      expect(find.text("Overall"), findsOneWidget);
      expect(find.text("Speed"), findsOneWidget);
      expect(find.text("Incidents"), findsOneWidget);
      expect(find.text("per month"), findsOneWidget);
      expect(find.text("Current"), findsOneWidget);
      expect(find.text("Tested"), findsOneWidget);
    });

    testWidgets("maps each metric onto ComparisonBar in the side colours", (WidgetTester tester) async {
      await _pump(tester, _panel(isExpanded: true));
      await tester.pumpAndSettle();
      final ColorScheme cs = _scheme(tester);
      final List<ComparisonBar> bars = tester.widgetList<ComparisonBar>(find.byType(ComparisonBar)).toList();

      expect(bars.map((ComparisonBar bar) => bar.label), <String>["Overall", "Speed", "Incidents"]);
      final ComparisonBar last = bars.last;
      expect(last.baselineValue, 4);
      expect(last.comparisonValue, 2);
      expect(last.max, 12);
      expect(last.min, 0);
      expect(last.lowerIsBetter, isTrue);
      expect(last.sublabel, "per month");
      expect(last.formatValue(3.6), "4");
      for (final ComparisonBar bar in bars) {
        expect(bar.baselineColor, cs.primary);
        expect(bar.comparisonColor, cs.tertiary);
      }
    });

    testWidgets("change null: no callout", (WidgetTester tester) async {
      await _pump(tester, _panel(isExpanded: true));
      await tester.pumpAndSettle();

      expect(_callout, findsNothing);
    });

    testWidgets("change set: fallback template, emphasised values, icon", (WidgetTester tester) async {
      await _pump(tester, _panel(isExpanded: true, change: _change));
      await tester.pumpAndSettle();

      expect(find.text("Main constraint: cost → latency", findRichText: true), findsOneWidget);
      expect(_calloutIcon(Icons.check_circle_outline), findsOneWidget);

      final List<TextSpan> spans = _calloutSpans(tester);
      final TextSpan from = spans.firstWhere((TextSpan span) => span.text == "cost");
      final TextSpan to = spans.firstWhere((TextSpan span) => span.text == "latency");
      final TextSpan label = spans.firstWhere((TextSpan span) => span.text == "Main constraint");
      expect(from.style?.fontWeight, FontWeight.w800);
      expect(to.style?.fontWeight, FontWeight.w800);
      expect(label.style, isNull);
    });

    testWidgets("change only: callout without legend or bars", (WidgetTester tester) async {
      await _pump(
        tester,
        _panel(
          metrics: const <ComparisonMetric>[],
          change: const ComparisonChange(label: "Mode", from: "manual", to: "auto", icon: Icons.bolt),
          isExpanded: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ComparisonBar), findsNothing);
      expect(find.text("Current"), findsNothing);
      expect(find.text("Mode: manual → auto", findRichText: true), findsOneWidget);
      expect(_calloutIcon(Icons.bolt), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    });

    testWidgets("callout colours come from primaryContainer", (WidgetTester tester) async {
      await _pump(tester, _panel(isExpanded: true, change: _change));
      await tester.pumpAndSettle();
      final ColorScheme cs = _scheme(tester);

      expect(tester.widget<Icon>(_calloutIcon(Icons.check_circle_outline)).color, cs.onPrimaryContainer);
      final InlineSpan? root = tester.widget<Text>(_callout).textSpan;
      expect(root?.style?.color, cs.onPrimaryContainer);
    });

    testWidgets("no detail: no chevron, inert header", (WidgetTester tester) async {
      int toggles = 0;
      await _pump(
        tester,
        _panel(metrics: const <ComparisonMetric>[], isExpanded: true, onToggle: () => toggles++),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
      expect(find.byType(ComparisonBar), findsNothing);
      await tester.tap(find.text("Plan A"));
      await tester.pump();
      expect(toggles, 0);
    });
  });
}

void _actionTests() {
  group("actions", () {
    testWidgets("cancel and confirm call their callbacks", (WidgetTester tester) async {
      int cancels = 0;
      int confirms = 0;
      await _pump(tester, _actionPanel(onCancel: () => cancels++, onConfirm: () => confirms++));

      await tester.tap(find.byType(OutlinedButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(cancels, 1);
      expect(confirms, 1);
    });

    testWidgets("onConfirm null disables Confirm", (WidgetTester tester) async {
      await _pump(tester, _actionPanel(confirmEnabled: false));

      final FilledButton button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(button.enabled, isFalse);
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
    });

    testWidgets("default labels come from the chrome keys", (WidgetTester tester) async {
      await _pump(tester, _actionPanel());

      expect(find.text(_cancelKey), findsOneWidget);
      expect(find.text(_confirmKey), findsOneWidget);
      expect(find.descendant(of: find.byType(OutlinedButton), matching: find.byIcon(Icons.close)), findsOneWidget);
      expect(find.descendant(of: find.byType(FilledButton), matching: find.byIcon(Icons.swap_horiz)), findsOneWidget);
    });

    testWidgets("label overrides replace the defaults", (WidgetTester tester) async {
      await _pump(tester, _actionPanel(confirmLabel: "Switch plan", cancelLabel: "Keep"));

      expect(find.text("Switch plan"), findsOneWidget);
      expect(find.text("Keep"), findsOneWidget);
      expect(find.text(_cancelKey), findsNothing);
      expect(find.text(_confirmKey), findsNothing);
    });

    testWidgets("confirm is filled tertiary and twice as wide as cancel", (WidgetTester tester) async {
      await _pump(tester, _actionPanel());
      final ColorScheme cs = _scheme(tester);

      final ButtonStyle? style = tester.widget<FilledButton>(find.byType(FilledButton)).style;
      expect(style?.backgroundColor?.resolve(<WidgetState>{}), cs.tertiary);
      expect(style?.foregroundColor?.resolve(<WidgetState>{}), cs.onTertiary);
      final double cancelWidth = tester.getSize(find.byType(OutlinedButton)).width;
      final double confirmWidth = tester.getSize(find.byType(FilledButton)).width;
      expect(confirmWidth, closeTo(cancelWidth * 2, 1));
    });

    testWidgets("buttons are at least kMinTapTarget tall", (WidgetTester tester) async {
      await _pump(tester, _actionPanel());

      expect(tester.getSize(find.byType(OutlinedButton)).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(find.byType(FilledButton)).height, greaterThanOrEqualTo(48));
    });
  });
}

void _semanticsTests() {
  group("semantics", () {
    testWidgets("header is a collapsed button with the show hint", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _panel());

      expect(
        tester.getSemantics(_header),
        isSemantics(
          label: _summaryKey,
          hint: _showKey,
          isButton: true,
          hasExpandedState: true,
          isExpanded: false,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      expect(tester.getSize(_header).height, greaterThanOrEqualTo(48));
      handle.dispose();
    });

    testWidgets("expanded header has the hide hint and toggles on tap action", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int toggles = 0;
      await _pump(tester, _panel(isExpanded: true, onToggle: () => toggles++));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(_header),
        isSemantics(label: _summaryKey, hint: _hideKey, isButton: true, isExpanded: true, isFocusable: true),
      );
      tester.semantics.tap(find.semantics.byLabel(_summaryKey));
      expect(toggles, 1);
      handle.dispose();
    });

    testWidgets("header without detail is not a button", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _panel(metrics: const <ComparisonMetric>[]));

      expect(
        tester.getSemantics(_header),
        isSemantics(
          label: _summaryKey,
          isButton: false,
          hasExpandedState: false,
          hasTapAction: false,
          isFocusable: false,
        ),
      );
      handle.dispose();
    });
  });
}

void _motionTests() {
  group("motion", () {
    testWidgets("animates the reveal with AnimatedSize by default", (WidgetTester tester) async {
      await _pump(tester, _panel());
      await _pump(tester, _panel(isExpanded: true));

      expect(find.byType(AnimatedSize), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pumpAndSettle();
      expect(find.byType(ComparisonBar), findsNWidgets(3));
    });

    testWidgets("reduced motion: expands in a single frame", (WidgetTester tester) async {
      await _pump(tester, _reducedMotion(_panel()));
      await _pump(tester, _reducedMotion(_panel(isExpanded: true)));

      expect(find.byType(AnimatedSize), findsNothing);
      expect(find.byType(ComparisonBar), findsNWidgets(3));
      expect(tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).duration, Duration.zero);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });
}

/// The chevron badge's circle (nearest Container above the glyph).
BoxDecoration _chevronDecoration(WidgetTester tester) {
  final Finder badge = find.ancestor(of: find.byIcon(Icons.keyboard_arrow_down_rounded), matching: find.byType(Container));
  return tester.widget<Container>(badge.first).decoration! as BoxDecoration;
}

Color? _chevronIconColor(WidgetTester tester) {
  return tester.widget<Icon>(find.byIcon(Icons.keyboard_arrow_down_rounded)).color;
}

void _visualTests() {
  group("visual contract", () {
    testWidgets("card border, header background and detail divider", (WidgetTester tester) async {
      await _pump(tester, _panel(isExpanded: true));
      await tester.pumpAndSettle();
      final ColorScheme cs = _scheme(tester);

      final Material card = tester.widget<Material>(
        find.descendant(of: find.byType(ComparisonPanel), matching: find.byType(Material)).first,
      );
      expect(card.color, cs.surface);
      expect(card.clipBehavior, Clip.antiAlias);
      expect(
        card.shape,
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.tertiary, width: 1.5),
        ),
      );

      final Material header = tester.widget<Material>(
        find.ancestor(of: find.text("Plan A"), matching: find.byType(Material)).first,
      );
      expect(header.color, cs.surfaceContainerLow);

      final Finder section = find.ancestor(
        of: find.byType(ComparisonBar).first,
        matching: find.byWidgetPredicate((Widget widget) => widget is Container && widget.decoration is BoxDecoration),
      );
      final BoxDecoration decoration = tester.widget<Container>(section.first).decoration! as BoxDecoration;
      expect(decoration.border, Border(top: BorderSide(color: cs.tertiary, width: 0.5)));
    });

    testWidgets("chevron badge: outlined when collapsed, filled when expanded", (WidgetTester tester) async {
      await _pump(tester, _panel());
      final ColorScheme cs = _scheme(tester);

      BoxDecoration badge = _chevronDecoration(tester);
      expect(badge.color, cs.surface);
      expect(badge.border, Border.all(color: cs.tertiary));
      expect(badge.shape, BoxShape.circle);
      expect(_chevronIconColor(tester), cs.tertiary);

      await _pump(tester, _panel(isExpanded: true));
      await tester.pumpAndSettle();
      badge = _chevronDecoration(tester);
      expect(badge.color, cs.tertiary);
      expect(badge.border, Border.all(color: cs.tertiary));
      expect(_chevronIconColor(tester), cs.onTertiary);
    });
  });
}

void _layoutTests() {
  group("layout", () {
    const String longTitle = "An extremely long option name that never fits on a single line";

    for (final (String name, ThemeData Function() theme) in <(String, ThemeData Function())>[
      ("light", AppTheme.light),
      ("dark", AppTheme.dark),
    ]) {
      testWidgets("long titles at 320 dp ($name)", (WidgetTester tester) async {
        await _pump(
          tester,
          ComparisonPanel(
            current: const ComparisonSide(tag: "A very long current tag", title: longTitle, subtitle: longTitle),
            candidate: const ComparisonSide(tag: "A very long candidate tag", title: longTitle, subtitle: longTitle),
            metrics: _metrics,
            change: _change,
            isExpanded: true,
            onToggle: () {},
            onCancel: () {},
            onConfirm: () {},
            confirmLabel: "A confirm label that is far too long for the button",
            cancelLabel: "A cancel label that is far too long",
          ),
          surfaceSize: const Size(320, 800),
          theme: theme(),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(ComparisonBar), findsNWidgets(3));
        final Text title = tester.widgetList<Text>(find.text(longTitle)).first;
        expect(title.maxLines, 1);
        expect(title.overflow, TextOverflow.ellipsis);
      });
    }
  });
}

void _localizedTests() {
  group("localized", () {
    testWidgets("fr strings: buttons, callout, header summary", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("fr"), _panel(isExpanded: true, change: _change));

      expect(find.text("Annuler"), findsOneWidget);
      expect(find.text("Confirmer"), findsOneWidget);
      expect(find.text("Main constraint : cost → latency", findRichText: true), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel("Plan A (55% · Fair) comparé à Plan B (72% · Good)")),
        isSemantics(hint: "Masquer le détail", isButton: true, isExpanded: true),
      );
      handle.dispose();
    });

    testWidgets("en strings and a side without subtitle", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(
        tester,
        const Locale("en"),
        _panel(candidate: const ComparisonSide(tag: "Tested", title: "Plan B")),
      );

      expect(find.text("Cancel"), findsOneWidget);
      expect(find.text("Confirm"), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel("Plan A (55% · Fair) compared with Plan B")),
        isSemantics(hint: "Show details", isExpanded: false),
      );
      handle.dispose();
    });

    testWidgets("renders a translated callout template in another order", (WidgetTester tester) async {
      await _pumpLocalized(
        tester,
        const Locale("en"),
        _panel(isExpanded: true, change: _change),
        loader: const _MemoryLoader(callout: "{to} replaces {from} ({label})"),
      );

      expect(find.text("latency replaces cost (Main constraint)", findRichText: true), findsOneWidget);
      final List<TextSpan> spans = _calloutSpans(tester);
      expect(spans.firstWhere((TextSpan span) => span.text == "latency").style?.fontWeight, FontWeight.w800);
    });
  });
}
