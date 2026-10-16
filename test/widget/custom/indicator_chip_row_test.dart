// indicator_chip_row_test.dart
//
// Widget tests for IndicatorChipRow: one IndicatorChip per entry in order,
// the 4 dp Wrap gaps, active tones versus the muted neutral tone (an active
// neutral entry matches a muted one), optional icons, entry defaults, reflow
// and ellipsis in narrow parents, the empty list, per-chip semantics and the
// dark theme.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/IndicatorChip/index.dart";
import "package:flutter_skeleton/widgets/custom/IndicatorChipRow/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const List<IndicatorChipEntry> _mixed = <IndicatorChipEntry>[
  IndicatorChipEntry(label: "Late 3", icon: Icons.schedule, tone: StatusTone.danger),
  IndicatorChipEntry(label: "Blocked 0", icon: Icons.block, tone: StatusTone.warning, active: false),
  IndicatorChipEntry(label: "Done 12", tone: StatusTone.success),
];

Finder _chipFor(String label) {
  return find.ancestor(of: find.text(label), matching: find.byType(IndicatorChip));
}

IndicatorChip _chip(WidgetTester tester, String label) => tester.widget<IndicatorChip>(_chipFor(label));

Color? _textColour(WidgetTester tester, String label) => tester.widget<Text>(find.text(label)).style?.color;

BuildContext _context(WidgetTester tester) => tester.element(find.byType(IndicatorChipRow));

Color _foreground(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(_context(tester), tone).foreground;
}

void main() {
  group("structure", () {
    testWidgets("renders one IndicatorChip per entry, in order, inside a Wrap", (WidgetTester tester) async {
      await pumpApp(tester, const IndicatorChipRow(entries: _mixed));

      expect(find.byType(IndicatorChip), findsNWidgets(3));
      expect(find.descendant(of: find.byType(Wrap), matching: find.byType(IndicatorChip)), findsNWidgets(3));
      final List<String> labels = tester
          .widgetList<IndicatorChip>(find.byType(IndicatorChip))
          .map((IndicatorChip chip) => chip.label)
          .toList();
      expect(labels, <String>["Late 3", "Blocked 0", "Done 12"]);
      expect(tester.getTopLeft(find.text("Late 3")).dx, lessThan(tester.getTopLeft(find.text("Blocked 0")).dx));
    });

    testWidgets("spaces chips and runs 4 dp apart", (WidgetTester tester) async {
      await pumpApp(tester, const IndicatorChipRow(entries: _mixed));

      final Wrap wrap = tester.widget<Wrap>(find.byType(Wrap));
      expect(wrap.spacing, 4);
      expect(wrap.runSpacing, 4);
      expect(
        tester.getTopLeft(_chipFor("Blocked 0")).dx - tester.getTopRight(_chipFor("Late 3")).dx,
        4,
      );
    });

    testWidgets("renders an icon only for entries that have one", (WidgetTester tester) async {
      await pumpApp(tester, const IndicatorChipRow(entries: _mixed));

      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.block), findsOneWidget);
      expect(find.descendant(of: _chipFor("Done 12"), matching: find.byType(Icon)), findsNothing);
      expect(_chip(tester, "Done 12").icon, isNull);
    });

    testWidgets("an empty list renders no chip and no error", (WidgetTester tester) async {
      await pumpApp(tester, const IndicatorChipRow(entries: <IndicatorChipEntry>[]));

      expect(tester.takeException(), isNull);
      expect(find.byType(IndicatorChip), findsNothing);
      expect(tester.getSize(find.byType(IndicatorChipRow)).height, 0);
    });

    testWidgets("passes no tooltip to the chips", (WidgetTester tester) async {
      await pumpApp(tester, const IndicatorChipRow(entries: _mixed));

      expect(find.byType(Tooltip), findsNothing);
    });
  });

  group("entry defaults", () {
    test("tone is neutral, active is true, icon and semanticsLabel are null", () {
      const IndicatorChipEntry entry = IndicatorChipEntry(label: "Flag");

      expect(entry.tone, StatusTone.neutral);
      expect(entry.active, isTrue);
      expect(entry.icon, isNull);
      expect(entry.semanticsLabel, isNull);
    });
  });

  group("tones", () {
    testWidgets("an active entry is drawn with its tone", (WidgetTester tester) async {
      await pumpApp(tester, const IndicatorChipRow(entries: _mixed));

      expect(_chip(tester, "Late 3").tone, StatusTone.danger);
      expect(_chip(tester, "Done 12").tone, StatusTone.success);
      final Color danger = _foreground(tester, StatusTone.danger);
      expect(_textColour(tester, "Late 3"), danger);
      expect(tester.widget<Icon>(find.byIcon(Icons.schedule)).color, danger);
    });

    testWidgets("an inactive entry ignores its tone and is muted", (WidgetTester tester) async {
      await pumpApp(tester, const IndicatorChipRow(entries: _mixed));

      expect(_chip(tester, "Blocked 0").tone, StatusTone.neutral);
      final Color muted = Theme.of(_context(tester)).colorScheme.onSurfaceVariant;
      expect(_textColour(tester, "Blocked 0"), muted);
      expect(tester.widget<Icon>(find.byIcon(Icons.block)).color, muted);
      expect(_textColour(tester, "Blocked 0"), isNot(_foreground(tester, StatusTone.warning)));
    });

    testWidgets("every active tone gives a distinct foreground", (WidgetTester tester) async {
      await pumpApp(
        tester,
        IndicatorChipRow(
          entries: <IndicatorChipEntry>[
            for (final StatusTone tone in StatusTone.values) IndicatorChipEntry(label: tone.name, tone: tone),
          ],
        ),
      );

      final Set<Color?> colours = <Color?>{
        for (final StatusTone tone in StatusTone.values) _textColour(tester, tone.name),
      };
      expect(colours, hasLength(StatusTone.values.length));
      for (final StatusTone tone in StatusTone.values) {
        expect(_chip(tester, tone.name).tone, tone);
        expect(_textColour(tester, tone.name), _foreground(tester, tone));
      }
    });

    testWidgets("every inactive entry is drawn in the neutral tone", (WidgetTester tester) async {
      await pumpApp(
        tester,
        IndicatorChipRow(
          entries: <IndicatorChipEntry>[
            for (final StatusTone tone in StatusTone.values)
              IndicatorChipEntry(label: tone.name, tone: tone, active: false),
          ],
        ),
      );

      for (final StatusTone tone in StatusTone.values) {
        expect(_chip(tester, tone.name).tone, StatusTone.neutral);
      }
    });

    testWidgets("an active neutral entry looks the same as a muted one", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const IndicatorChipRow(
          entries: <IndicatorChipEntry>[
            IndicatorChipEntry(label: "On", icon: Icons.flag),
            IndicatorChipEntry(label: "Off", icon: Icons.flag, active: false),
          ],
        ),
      );

      expect(_chip(tester, "On").tone, StatusTone.neutral);
      expect(_chip(tester, "Off").tone, StatusTone.neutral);
      expect(_textColour(tester, "On"), _textColour(tester, "Off"));
      final List<Icon> icons = tester.widgetList<Icon>(find.byIcon(Icons.flag)).toList();
      expect(icons.first.color, icons.last.color);
    });
  });

  group("layout", () {
    testWidgets("reflows long labels over several runs without overflow", (WidgetTester tester) async {
      const List<IndicatorChipEntry> long = <IndicatorChipEntry>[
        IndicatorChipEntry(label: "First long indicator", icon: Icons.flag),
        IndicatorChipEntry(label: "Second long indicator", icon: Icons.flag),
        IndicatorChipEntry(label: "Third long indicator", icon: Icons.flag),
        IndicatorChipEntry(label: "Fourth long indicator", icon: Icons.flag),
      ];
      await pumpApp(
        tester,
        const SizedBox(width: 160, child: IndicatorChipRow(entries: long)),
        surfaceSize: const Size(400, 600),
      );

      expect(tester.takeException(), isNull);
      final Set<double> rows = <double>{
        for (final IndicatorChipEntry entry in long) tester.getTopLeft(_chipFor(entry.label)).dy,
      };
      expect(rows.length, greaterThan(1));
      for (final IndicatorChipEntry entry in long) {
        expect(tester.getTopRight(_chipFor(entry.label)).dx, lessThanOrEqualTo(160));
      }
    });

    testWidgets("ellipsizes a label wider than the row", (WidgetTester tester) async {
      const String label = "An indicator label far wider than the narrow row hosting it";
      await pumpApp(
        tester,
        const SizedBox(
          width: 120,
          child: IndicatorChipRow(entries: <IndicatorChipEntry>[IndicatorChipEntry(label: label)]),
        ),
        surfaceSize: const Size(400, 200),
      );

      expect(tester.takeException(), isNull);
      expect(tester.widget<Text>(find.text(label)).overflow, TextOverflow.ellipsis);
      expect(tester.getSize(_chipFor(label)).width, lessThanOrEqualTo(120));
    });
  });

  group("semantics", () {
    testWidgets("each chip is labelled by semanticsLabel, else by its label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const IndicatorChipRow(
          entries: <IndicatorChipEntry>[
            IndicatorChipEntry(label: "Late 3", tone: StatusTone.danger, semanticsLabel: "Three late items"),
            IndicatorChipEntry(label: "Blocked 0", active: false),
          ],
        ),
      );

      expect(find.bySemanticsLabel("Three late items"), findsOneWidget);
      expect(find.bySemanticsLabel("Late 3"), findsNothing);
      expect(find.bySemanticsLabel("Blocked 0"), findsOneWidget);
      handle.dispose();
    });
  });

  group("dark theme", () {
    testWidgets("renders active and muted chips with the dark scheme", (WidgetTester tester) async {
      await pumpApp(tester, const IndicatorChipRow(entries: _mixed), theme: AppTheme.dark());

      expect(tester.takeException(), isNull);
      final ColorScheme cs = Theme.of(_context(tester)).colorScheme;
      expect(cs.brightness, Brightness.dark);
      expect(_textColour(tester, "Late 3"), _foreground(tester, StatusTone.danger));
      expect(_textColour(tester, "Blocked 0"), cs.onSurfaceVariant);
    });
  });
}
