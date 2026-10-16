// state_message_view_test.dart
//
// Widget tests for StateMessageView: title / message rendering, the default
// tone icon, the badge / title / message spacing and type, the action stack
// (filled / outlined, icons, taps, order, 48 dp height, max width), the gauge
// (clamping, caption styles and spacing, single semantics node), the empty
// footer, scrolling in a short area, the live-region semantics and the tone
// colours under the light and dark themes.

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/StateMessageView/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _title = "Something went wrong";
const String _message = "Try again in a moment.";
const StateMessageGauge _gauge = StateMessageGauge(
  value: 1,
  leftCaption: "Limit: 1,000 items",
  rightCaption: "Exceeded",
);

Finder _inView(Finder matching) {
  return find.descendant(of: find.byType(StateMessageView), matching: matching);
}

/// The 64 dp badge around the icon.
BoxDecoration _badge(WidgetTester tester, IconData icon) {
  final Container badge = tester.widget<Container>(
    find.ancestor(of: find.byIcon(icon), matching: find.byType(Container)).first,
  );
  return badge.decoration! as BoxDecoration;
}

LinearProgressIndicator _bar(WidgetTester tester) {
  return tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
}

Future<void> _pump(
  WidgetTester tester,
  StateMessageView view, {
  ThemeData? theme,
  Size? surfaceSize,
}) {
  return pumpApp(tester, view, theme: theme, surfaceSize: surfaceSize);
}

void main() {
  _contentTests();
  _actionTests();
  _gaugeTests();
  _layoutAndSemanticsTests();
  _toneTests();
}

void _contentTests() {
  group("content", () {
    testWidgets("renders the title, the message and a decorative icon", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, const StateMessageView(icon: Icons.hourglass_bottom_rounded, title: _title, message: _message));

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_message), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_bottom_rounded), findsOneWidget);
      expect(
        find.ancestor(of: find.byIcon(Icons.hourglass_bottom_rounded), matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
      final Size badge = tester.getSize(
        find.ancestor(of: find.byIcon(Icons.hourglass_bottom_rounded), matching: find.byType(Container)).first,
      );
      expect(badge, const Size(64, 64));
      expect(_badge(tester, Icons.hourglass_bottom_rounded).shape, BoxShape.circle);
      handle.dispose();
    });

    testWidgets("hides the message when it is null or empty", (WidgetTester tester) async {
      await _pump(tester, const StateMessageView(title: _title));
      expect(_inView(find.byType(Text)), findsOneWidget);

      await _pump(tester, const StateMessageView(title: _title, message: ""));
      expect(_inView(find.byType(Text)), findsOneWidget);
    });

    testWidgets("defaults the icon to the tone icon", (WidgetTester tester) async {
      await _pump(tester, const StateMessageView(title: _title, tone: StatusTone.warning));
      expect(find.byIcon(StatusTone.warning.icon), findsOneWidget);

      await _pump(tester, const StateMessageView(title: _title));
      expect(find.byIcon(StatusTone.neutral.icon), findsOneWidget);
    });

    testWidgets("title is titleMedium w700 onSurface and the message onSurfaceVariant", (WidgetTester tester) async {
      await _pump(tester, const StateMessageView(title: _title, message: _message));
      final BuildContext context = tester.element(find.byType(StateMessageView));
      final ColorScheme cs = Theme.of(context).colorScheme;

      final Text title = tester.widget<Text>(find.text(_title));
      expect(title.style?.fontWeight, FontWeight.w700);
      expect(title.style?.color, cs.onSurface);
      expect(title.style?.fontSize, Theme.of(context).textTheme.titleMedium?.fontSize);
      expect(title.textAlign, TextAlign.center);
      final Text message = tester.widget<Text>(find.text(_message));
      expect(message.style?.color, cs.onSurfaceVariant);
      expect(message.style?.fontSize, Theme.of(context).textTheme.bodyMedium?.fontSize);
      expect(message.textAlign, TextAlign.center);
    });

    testWidgets("badge, title and message sit 16 dp then 8 dp apart", (WidgetTester tester) async {
      await _pump(tester, const StateMessageView(title: _title, message: _message));

      final Finder badge = find
          .ancestor(of: find.byIcon(StatusTone.neutral.icon), matching: find.byType(Container))
          .first;
      expect(tester.getTopLeft(find.text(_title)).dy - tester.getBottomLeft(badge).dy, kDefaultPadding * 2);
      expect(tester.getTopLeft(find.text(_message)).dy - tester.getBottomLeft(find.text(_title)).dy, kDefaultPadding);
    });
  });
}

void _actionTests() {
  group("actions", () {
    testWidgets("a primary action renders a FilledButton that calls back once", (WidgetTester tester) async {
      int taps = 0;
      await _pump(
        tester,
        StateMessageView(title: _title, primaryAction: StateMessageAction(label: "Retry", onPressed: () => taps++)),
      );

      expect(find.widgetWithText(FilledButton, "Retry"), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      await tester.tap(find.text("Retry"));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets("an action icon is rendered next to the label", (WidgetTester tester) async {
      await _pump(
        tester,
        StateMessageView(
          title: _title,
          primaryAction: StateMessageAction(label: "Open", icon: Icons.edit_rounded, onPressed: () {}),
          secondaryAction: StateMessageAction(label: "Close", icon: Icons.close_rounded, onPressed: () {}),
        ),
      );

      expect(find.descendant(of: find.byType(FilledButton), matching: find.byIcon(Icons.edit_rounded)), findsOneWidget);
      expect(find.descendant(of: find.byType(OutlinedButton), matching: find.byIcon(Icons.close_rounded)), findsOneWidget);
      expect(tester.widget<Icon>(find.byIcon(Icons.edit_rounded)).size, 18);
      expect(find.text("Open"), findsOneWidget);
    });

    testWidgets("a secondary action renders an OutlinedButton 8 dp below the primary", (WidgetTester tester) async {
      int primary = 0;
      int secondary = 0;
      await _pump(
        tester,
        StateMessageView(
          title: _title,
          primaryAction: StateMessageAction(label: "Retry", onPressed: () => primary++),
          secondaryAction: StateMessageAction(label: "Back", onPressed: () => secondary++),
        ),
      );

      final Finder filled = find.byType(FilledButton);
      final Finder outlined = find.widgetWithText(OutlinedButton, "Back");
      expect(outlined, findsOneWidget);
      expect(tester.getTopLeft(outlined).dy - tester.getBottomLeft(filled).dy, kDefaultPadding);

      await tester.tap(find.text("Back"));
      await tester.pump();
      expect(secondary, 1);
      expect(primary, 0);
    });

    testWidgets("a secondary action alone renders no FilledButton", (WidgetTester tester) async {
      await _pump(
        tester,
        StateMessageView(title: _title, secondaryAction: StateMessageAction(label: "Back", onPressed: () {})),
      );
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets("buttons are at least kMinTapTarget tall", (WidgetTester tester) async {
      await _pump(
        tester,
        StateMessageView(
          title: _title,
          primaryAction: StateMessageAction(label: "Retry", onPressed: () {}),
          secondaryAction: StateMessageAction(label: "Back", icon: Icons.arrow_back, onPressed: () {}),
        ),
      );
      // The visible surface (Material), not only the padded hit area.
      for (final Type type in <Type>[FilledButton, OutlinedButton]) {
        final Finder surface = find.descendant(of: find.byType(type), matching: find.byType(Material));
        expect(tester.getSize(surface).height, greaterThanOrEqualTo(kMinTapTarget), reason: "$type");
      }
    });

    testWidgets("buttons and gauge stretch to actionsMaxWidth on a wide surface", (WidgetTester tester) async {
      final StateMessageAction retry = StateMessageAction(label: "Retry", onPressed: () {});
      final StateMessageAction back = StateMessageAction(label: "Back", onPressed: () {});

      await _pump(
        tester,
        StateMessageView(title: _title, gauge: _gauge, primaryAction: retry, secondaryAction: back),
        surfaceSize: const Size(1200, 800),
      );
      expect(tester.getSize(find.byType(FilledButton)).width, 320);
      expect(tester.getSize(find.byType(OutlinedButton)).width, 320);
      expect(tester.getSize(find.byType(LinearProgressIndicator)).width, 320);

      await _pump(
        tester,
        StateMessageView(title: _title, primaryAction: retry, secondaryAction: back, actionsMaxWidth: 400),
        surfaceSize: const Size(1200, 800),
      );
      expect(tester.getSize(find.byType(FilledButton)).width, 400);
      expect(tester.getSize(find.byType(OutlinedButton)).width, 400);
    });

    testWidgets("buttons shrink to the available width on a narrow surface", (WidgetTester tester) async {
      await _pump(
        tester,
        StateMessageView(title: _title, primaryAction: StateMessageAction(label: "Retry", onPressed: () {})),
        surfaceSize: const Size(300, 600),
      );
      expect(tester.getSize(find.byType(FilledButton)).width, 300 - kDefaultPadding * 8);
      expect(tester.takeException(), isNull);
    });

    testWidgets("no gauge and no action: no footer at all", (WidgetTester tester) async {
      await _pump(tester, const StateMessageView(title: _title, message: _message));

      expect(find.byType(ButtonStyleButton), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(
        _inView(find.byWidgetPredicate((Widget w) => w is SizedBox && w.height == kSectionGap)),
        findsNothing,
      );
      expect(
        _inView(find.byWidgetPredicate((Widget w) => w is ConstrainedBox && w.constraints.maxWidth == 320)),
        findsNothing,
      );
    });

    testWidgets("a footer is preceded by a kSectionGap", (WidgetTester tester) async {
      await _pump(
        tester,
        StateMessageView(title: _title, primaryAction: StateMessageAction(label: "Retry", onPressed: () {})),
      );
      expect(
        tester.getTopLeft(find.byType(FilledButton)).dy - tester.getBottomLeft(find.text(_title)).dy,
        kSectionGap,
      );
    });
  });
}

void _gaugeTests() {
  group("gauge", () {
    testWidgets("clamps the value to 0..1", (WidgetTester tester) async {
      for (final (double input, double expected) in <(double, double)>[(1.4, 1), (-0.2, 0), (0.5, 0.5)]) {
        await _pump(
          tester,
          StateMessageView(
            title: _title,
            gauge: StateMessageGauge(value: input, leftCaption: "Left", rightCaption: "Right"),
          ),
        );
        expect(_bar(tester).value, expected, reason: "value $input");
      }
    });

    testWidgets("shows both captions above a rounded 8 dp bar", (WidgetTester tester) async {
      await _pump(tester, const StateMessageView(title: _title, gauge: _gauge));

      expect(find.text(_gauge.leftCaption), findsOneWidget);
      expect(find.text(_gauge.rightCaption), findsOneWidget);
      expect(
        tester.getBottomLeft(find.text(_gauge.leftCaption)).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(LinearProgressIndicator)).dy),
      );
      expect(_bar(tester).minHeight, kDefaultPadding);
      final ClipRRect clip = tester.widget<ClipRRect>(
        find.ancestor(of: find.byType(LinearProgressIndicator), matching: find.byType(ClipRRect)),
      );
      expect(clip.borderRadius, BorderRadius.circular(999));
      expect(
        tester.getTopLeft(find.byType(LinearProgressIndicator)).dx,
        tester.getTopLeft(find.text(_gauge.leftCaption)).dx,
      );
      expect(
        tester.getTopRight(find.byType(LinearProgressIndicator)).dx,
        tester.getTopRight(find.text(_gauge.rightCaption)).dx,
      );
    });

    testWidgets("is announced once: one node, label = left caption, value = right caption", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, const StateMessageView(title: _title, gauge: _gauge));

      final SemanticsNode node = tester.getSemantics(find.byType(LinearProgressIndicator));
      final SemanticsData data = node.getSemanticsData();
      expect(data.label, _gauge.leftCaption);
      // The status is a value, not a hint: VoiceOver can mute hints.
      expect(data.value, _gauge.rightCaption);
      expect(data.hint, isEmpty);
      // Captions and bar share the node; no child repeats them.
      expect(tester.getSemantics(find.text(_gauge.leftCaption)), same(node));
      expect(tester.getSemantics(find.text(_gauge.rightCaption)), same(node));
      expect(node.hasChildren, isFalse);
      expect(find.bySemanticsLabel(_gauge.leftCaption), findsOneWidget);
      expect(find.bySemanticsLabel(_gauge.rightCaption), findsNothing);
      handle.dispose();
    });

    testWidgets("captions are labelSmall: left onSurfaceVariant, right w600; 4 dp above the bar", (
      WidgetTester tester,
    ) async {
      await _pump(tester, const StateMessageView(title: _title, gauge: _gauge));
      final ThemeData theme = Theme.of(tester.element(find.byType(StateMessageView)));

      final TextStyle? left = tester.widget<Text>(find.text(_gauge.leftCaption)).style;
      final TextStyle? right = tester.widget<Text>(find.text(_gauge.rightCaption)).style;
      expect(left?.color, theme.colorScheme.onSurfaceVariant);
      expect(left?.fontSize, theme.textTheme.labelSmall?.fontSize);
      expect(right?.fontWeight, FontWeight.w600);
      expect(right?.fontSize, theme.textTheme.labelSmall?.fontSize);

      final Finder row = find.ancestor(of: find.text(_gauge.leftCaption), matching: find.byType(Row)).first;
      expect(
        tester.getTopLeft(find.byType(LinearProgressIndicator)).dy - tester.getBottomLeft(row).dy,
        kDefaultPadding / 2,
      );
    });

    testWidgets("sits above the actions", (WidgetTester tester) async {
      await _pump(
        tester,
        StateMessageView(
          title: _title,
          gauge: _gauge,
          primaryAction: StateMessageAction(label: "Edit", onPressed: () {}),
        ),
      );
      expect(
        tester.getBottomLeft(find.byType(LinearProgressIndicator)).dy,
        lessThan(tester.getTopLeft(find.byType(FilledButton)).dy),
      );
    });
  });
}

void _layoutAndSemanticsTests() {
  group("layout and semantics", () {
    testWidgets("scrolls without overflow in a short area", (WidgetTester tester) async {
      int taps = 0;
      await _pump(
        tester,
        StateMessageView(
          title: _title,
          message: _message,
          gauge: _gauge,
          primaryAction: StateMessageAction(label: "Retry", onPressed: () {}),
          secondaryAction: StateMessageAction(label: "Back", onPressed: () => taps++),
        ),
        surfaceSize: const Size(320, 260),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      await tester.dragUntilVisible(find.text("Back"), find.byType(SingleChildScrollView), const Offset(0, -50));
      await tester.tap(find.text("Back"));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets("is centred in a large area", (WidgetTester tester) async {
      await _pump(tester, const StateMessageView(title: _title), surfaceSize: const Size(800, 600));
      expect(tester.getCenter(find.text(_title)).dx, 400);
    });

    testWidgets("title and message form one live-region header node", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, const StateMessageView(title: _title, message: _message));

      final SemanticsData data = tester.getSemantics(find.text(_title)).getSemanticsData();
      expect(data.flagsCollection.isLiveRegion, isTrue);
      expect(data.flagsCollection.isHeader, isTrue);
      expect(data.label, "$_title\n$_message");
      handle.dispose();
    });
  });
}

void _toneTests() {
  group("tones", () {
    Future<void> expectTone(WidgetTester tester, StatusTone tone, ThemeData theme) async {
      await _pump(
        tester,
        StateMessageView(title: _title, tone: tone, gauge: _gauge),
        theme: theme,
      );
      final BuildContext context = tester.element(find.byType(StateMessageView));
      final ToneColors colors = StatusTones.colorsOf(context, tone);

      expect(tester.widget<Icon>(find.byIcon(tone.icon)).color, colors.foreground, reason: "$tone icon");
      expect(_badge(tester, tone.icon).color, colors.container, reason: "$tone badge");
      expect(
        (_bar(tester).valueColor! as AlwaysStoppedAnimation<Color?>).value,
        colors.foreground,
        reason: "$tone bar",
      );
      expect(tester.widget<Text>(find.text(_gauge.rightCaption)).style?.color, colors.foreground);
      expect(_bar(tester).backgroundColor, Theme.of(context).colorScheme.surfaceContainerHighest);
    }

    testWidgets("neutral and primary come from the ColorScheme", (WidgetTester tester) async {
      await _pump(tester, const StateMessageView(title: _title));
      final ColorScheme cs = Theme.of(tester.element(find.byType(StateMessageView))).colorScheme;
      expect(tester.widget<Icon>(find.byIcon(StatusTone.neutral.icon)).color, cs.onSurfaceVariant);
      expect(_badge(tester, StatusTone.neutral.icon).color, cs.surfaceContainerHighest);

      await _pump(tester, const StateMessageView(title: _title, tone: StatusTone.primary));
      expect(tester.widget<Icon>(find.byIcon(StatusTone.primary.icon)).color, cs.primary);
      expect(_badge(tester, StatusTone.primary.icon).color, cs.primaryContainer);
    });

    testWidgets("every tone drives badge, icon and gauge under the light theme", (WidgetTester tester) async {
      for (final StatusTone tone in StatusTone.values) {
        await expectTone(tester, tone, AppTheme.light());
      }
    });

    testWidgets("dark theme smoke test", (WidgetTester tester) async {
      for (final StatusTone tone in StatusTone.values) {
        await expectTone(tester, tone, AppTheme.dark());
      }
      await _pump(
        tester,
        StateMessageView(
          title: _title,
          message: _message,
          tone: StatusTone.danger,
          gauge: _gauge,
          primaryAction: StateMessageAction(label: "Retry", onPressed: () {}),
          secondaryAction: StateMessageAction(label: "Back", onPressed: () {}),
        ),
        theme: AppTheme.dark(),
      );
      final ColorScheme cs = Theme.of(tester.element(find.byType(StateMessageView))).colorScheme;
      expect(cs.brightness, Brightness.dark);
      expect(tester.widget<Text>(find.text(_title)).style?.color, cs.onSurface);
      expect(tester.widget<Icon>(find.byIcon(StatusTone.danger.icon)).color, cs.error);
      expect(tester.takeException(), isNull);
    });
  });
}
