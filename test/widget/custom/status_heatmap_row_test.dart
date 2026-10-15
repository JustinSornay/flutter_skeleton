// status_heatmap_row_test.dart
//
// Tests for StatusHeatmapRow: cell order and equal widths without scrolling,
// the optional header, the count-up (and its reduced-motion bypass), the
// default locale-aware and custom formatters, empty cells, one semantics
// node per cell, tone colours of the value / icon / tint / border, the icon
// override, long captions and the dark theme.

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/StatusHeatmapRow/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const Size _phone = Size(360, 640);
const String _noValueKey = "custom.status_heatmap_row.no_value";

const List<StatusHeatmapCell> _fiveCells = <StatusHeatmapCell>[
  StatusHeatmapCell(label: "A", value: 0.85, statusLabel: "high", tone: StatusTone.success),
  StatusHeatmapCell(label: "B", value: 0.72, statusLabel: "good", tone: StatusTone.info),
  StatusHeatmapCell(label: "C", value: 0.58, statusLabel: "fair", tone: StatusTone.warning),
  StatusHeatmapCell(label: "D", value: 0.32, statusLabel: "poor", tone: StatusTone.danger),
  StatusHeatmapCell(label: "E", value: 0.15, statusLabel: "unknown"),
];

Finder _inRow(Finder matching) {
  return find.descendant(of: find.byType(StatusHeatmapRow), matching: matching);
}

/// The tinted box of every cell, left to right.
Finder _cellBoxes() {
  return _inRow(
    find.byWidgetPredicate((Widget widget) {
      final Decoration? decoration = widget is Container ? widget.decoration : null;
      return decoration is BoxDecoration && decoration.border != null;
    }),
  );
}

BoxDecoration _decorationAt(WidgetTester tester, int index) {
  return tester.widget<Container>(_cellBoxes().at(index)).decoration! as BoxDecoration;
}

Color _foreground(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(tester.element(find.byType(StatusHeatmapRow)), tone).foreground;
}

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(StatusHeatmapRow))).colorScheme;
}

Future<void> _pumpRow(
  WidgetTester tester, {
  List<StatusHeatmapCell> cells = _fiveCells,
  String? title,
  StatusHeatmapValueFormatter? formatValue,
  ThemeData? theme,
}) async {
  await pumpApp(
    tester,
    StatusHeatmapRow(cells: cells, title: title, formatValue: formatValue),
    surfaceSize: _phone,
    theme: theme,
  );
}

void main() {
  group("layout", () {
    testWidgets("renders the cells in the given order, never re-sorted", (WidgetTester tester) async {
      const List<StatusHeatmapCell> cells = <StatusHeatmapCell>[
        StatusHeatmapCell(label: "Z", value: 0.1, statusLabel: "s"),
        StatusHeatmapCell(label: "M", value: 0.9, statusLabel: "s"),
        StatusHeatmapCell(label: "A", value: 0.5, statusLabel: "s"),
      ];
      await _pumpRow(tester, cells: cells);
      await tester.pumpAndSettle();

      final double z = tester.getCenter(find.text("Z")).dx;
      final double m = tester.getCenter(find.text("M")).dx;
      final double a = tester.getCenter(find.text("A")).dx;
      expect(z, lessThan(m));
      expect(m, lessThan(a));
    });

    testWidgets("five cells at 360 dp: equal widths, no scroll, no overflow", (WidgetTester tester) async {
      await _pumpRow(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_inRow(find.byType(Scrollable)), findsNothing);
      expect(_cellBoxes(), findsNWidgets(5));
      final double first = tester.getSize(_cellBoxes().first).width;
      for (int i = 1; i < 5; i++) {
        expect(tester.getSize(_cellBoxes().at(i)).width, moreOrLessEquals(first));
      }
      expect(tester.getSize(_cellBoxes().first).height, greaterThanOrEqualTo(72));
    });

    testWidgets("no title → no header text", (WidgetTester tester) async {
      await _pumpRow(tester);
      await tester.pumpAndSettle();

      // Each cell holds two texts (value + caption); nothing else is drawn.
      expect(_inRow(find.byType(Text)), findsNWidgets(10));
    });

    testWidgets("title is shown as a semantics header", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpRow(tester, title: "Header");
      await tester.pumpAndSettle();

      expect(find.text("Header"), findsOneWidget);
      expect(
        tester.getSemantics(find.text("Header")),
        isSemantics(label: "Header", isHeader: true),
      );
      handle.dispose();
    });

    testWidgets("a long caption stays on one line with an ellipsis", (WidgetTester tester) async {
      const String long = "A very long caption that cannot fit in a narrow cell";
      await _pumpRow(
        tester,
        cells: <StatusHeatmapCell>[
          const StatusHeatmapCell(label: long, value: 0.5, statusLabel: "s"),
          ..._fiveCells.skip(1),
        ],
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final Text caption = tester.widget<Text>(find.text(long));
      expect(caption.maxLines, 1);
      expect(caption.overflow, TextOverflow.ellipsis);
      expect(tester.renderObject<RenderParagraph>(find.text(long)).didExceedMaxLines, isTrue);
    });
  });

  group("count-up", () {
    testWidgets("counts up linearly from 0 to the value over 500 ms", (WidgetTester tester) async {
      await _pumpRow(
        tester,
        cells: const <StatusHeatmapCell>[StatusHeatmapCell(label: "A", value: 0.58, statusLabel: "s")],
      );

      expect(find.text("0.00"), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text("0.29"), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text("0.58"), findsOneWidget);
    });

    testWidgets("reduced motion shows the final value on the first frame", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: StatusHeatmapRow(
            cells: <StatusHeatmapCell>[StatusHeatmapCell(label: "A", value: 0.58, statusLabel: "s")],
          ),
        ),
        surfaceSize: _phone,
      );

      expect(find.text("0.58"), findsOneWidget);
      expect(_inRow(find.byType(TweenAnimationBuilder<double>)), findsNothing);
    });
  });

  group("formatting", () {
    testWidgets("custom formatter drives the text, every frame and the semantics", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpRow(
        tester,
        cells: const <StatusHeatmapCell>[StatusHeatmapCell(label: "A", value: 0.58, statusLabel: "fair")],
        formatValue: (double v) => "${(v * 100).round()} %",
      );

      expect(find.text("0 %"), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text("29 %"), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text("58 %"), findsOneWidget);
      expect(find.bySemanticsLabel("A, 58 %, fair"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("default formatter follows the ambient locale", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => Localizations.override(
            context: context,
            locale: const Locale("fr"),
            child: const StatusHeatmapRow(
              cells: <StatusHeatmapCell>[StatusHeatmapCell(label: "A", value: 0.58, statusLabel: "s")],
            ),
          ),
        ),
        surfaceSize: _phone,
      );
      await tester.pumpAndSettle();

      expect(find.text("0,58"), findsOneWidget);
    });
  });

  group("empty cell", () {
    testWidgets("shows a dash and the neutral icon in onSurfaceVariant", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpRow(
        tester,
        cells: const <StatusHeatmapCell>[
          StatusHeatmapCell(label: "A", value: 0.5, statusLabel: "s", tone: StatusTone.success),
          StatusHeatmapCell.empty(label: "B"),
        ],
      );
      await tester.pumpAndSettle();

      final Color muted = _scheme(tester).onSurfaceVariant;
      expect(tester.widget<Text>(find.text("—")).style?.color, muted);
      expect(tester.widget<Icon>(find.byIcon(StatusTone.neutral.icon)).color, muted);
      expect(find.bySemanticsLabel("B, $_noValueKey"), findsOneWidget);
      handle.dispose();
    });

    test("the empty constructor holds no value, no status and the neutral tone", () {
      const StatusHeatmapCell cell = StatusHeatmapCell.empty(label: "B");
      expect(cell.isEmpty, isTrue);
      expect(cell.value, isNull);
      expect(cell.statusLabel, isNull);
      expect(cell.tone, StatusTone.neutral);
      expect(cell.icon, isNull);
    });
  });

  group("semantics", () {
    testWidgets("one node per cell: label, formatted value, status", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpRow(tester);
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel("A, 0.85, high"), findsOneWidget);
      expect(find.bySemanticsLabel("B, 0.72, good"), findsOneWidget);
      expect(find.bySemanticsLabel("C, 0.58, fair"), findsOneWidget);
      expect(find.bySemanticsLabel("D, 0.32, poor"), findsOneWidget);
      expect(find.bySemanticsLabel("E, 0.15, unknown"), findsOneWidget);
      // The caption and value texts are excluded, so nothing is read twice.
      expect(find.bySemanticsLabel("A"), findsNothing);
      expect(find.bySemanticsLabel("0.85"), findsNothing);
      handle.dispose();
    });
  });

  group("tones", () {
    testWidgets("value, icon, tint and border use the tone foreground", (WidgetTester tester) async {
      await _pumpRow(tester);
      await tester.pumpAndSettle();

      final Map<String, StatusTone> tones = <String, StatusTone>{
        "0.85": StatusTone.success,
        "0.72": StatusTone.info,
        "0.58": StatusTone.warning,
        "0.32": StatusTone.danger,
        "0.15": StatusTone.neutral,
      };
      int index = 0;
      for (final MapEntry<String, StatusTone> entry in tones.entries) {
        final Color color = _foreground(tester, entry.value);
        expect(tester.widget<Text>(find.text(entry.key)).style?.color, color, reason: entry.key);
        expect(tester.widget<Icon>(find.byIcon(entry.value.icon)).color, color, reason: entry.key);
        final BoxDecoration decoration = _decorationAt(tester, index);
        expect(decoration.color, color.withValues(alpha: 0.1), reason: entry.key);
        expect((decoration.border! as Border).top.color, color.withValues(alpha: 0.25), reason: entry.key);
        index++;
      }
    });

    testWidgets("neutral tone resolves to onSurfaceVariant", (WidgetTester tester) async {
      await _pumpRow(tester);
      await tester.pumpAndSettle();

      expect(_foreground(tester, StatusTone.neutral), _scheme(tester).onSurfaceVariant);
      expect(tester.widget<Text>(find.text("0.15")).style?.color, _scheme(tester).onSurfaceVariant);
    });

    testWidgets("icon overrides the tone icon, keeping the tone colour", (WidgetTester tester) async {
      await _pumpRow(
        tester,
        cells: const <StatusHeatmapCell>[
          StatusHeatmapCell(label: "A", value: 0.9, statusLabel: "s", tone: StatusTone.success, icon: Icons.star),
          StatusHeatmapCell(label: "B", value: 0.7, statusLabel: "s", tone: StatusTone.success),
        ],
      );
      await tester.pumpAndSettle();

      final Color color = _foreground(tester, StatusTone.success);
      expect(tester.widget<Icon>(find.byIcon(Icons.star)).color, color);
      expect(find.byIcon(StatusTone.success.icon), findsOneWidget);
    });

    testWidgets("builds under the dark theme with its tone colours", (WidgetTester tester) async {
      await _pumpRow(tester, title: "Header", theme: AppTheme.dark());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(Theme.of(tester.element(find.byType(StatusHeatmapRow))).brightness, Brightness.dark);
      expect(tester.widget<Text>(find.text("0.85")).style?.color, _foreground(tester, StatusTone.success));
      expect(tester.widget<Text>(find.text("0.32")).style?.color, _foreground(tester, StatusTone.danger));
    });
  });
}
