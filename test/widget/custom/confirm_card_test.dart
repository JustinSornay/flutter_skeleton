// confirm_card_test.dart
//
// Widget tests for ConfirmCard: content, callbacks, destructive styling,
// tap targets and the header semantics of the title.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/ConfirmCard/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

ConfirmCard _card({String? message, bool destructive = false, VoidCallback? onConfirm, VoidCallback? onCancel}) {
  return ConfirmCard(
    title: "Delete item?",
    message: message,
    confirmLabel: "Delete",
    cancelLabel: "Cancel",
    destructive: destructive,
    onConfirm: onConfirm ?? () {},
    onCancel: onCancel ?? () {},
  );
}

void main() {
  testWidgets("renders title, message and both buttons", (WidgetTester tester) async {
    await pumpApp(tester, _card(message: "This cannot be undone."));

    expect(find.text("Delete item?"), findsOneWidget);
    expect(find.text("This cannot be undone."), findsOneWidget);
    expect(find.widgetWithText(TextButton, "Cancel"), findsOneWidget);
    expect(find.widgetWithText(FilledButton, "Delete"), findsOneWidget);
  });

  testWidgets("hides an empty message", (WidgetTester tester) async {
    await pumpApp(tester, _card(message: ""));

    expect(find.byType(Text), findsNWidgets(3));
  });

  testWidgets("calls onConfirm and onCancel", (WidgetTester tester) async {
    final List<String> calls = <String>[];
    await pumpApp(tester, _card(onConfirm: () => calls.add("confirm"), onCancel: () => calls.add("cancel")));

    await tester.tap(find.text("Delete"));
    await tester.tap(find.text("Cancel"));

    expect(calls, <String>["confirm", "cancel"]);
  });

  testWidgets("destructive paints the confirm button with the error colours", (WidgetTester tester) async {
    await pumpApp(tester, _card(destructive: true));
    final ColorScheme cs = AppTheme.light().colorScheme;

    final FilledButton button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.style?.backgroundColor?.resolve(<WidgetState>{}), cs.error);
    expect(button.style?.foregroundColor?.resolve(<WidgetState>{}), cs.onError);
  });

  testWidgets("a regular card keeps the theme's filled button colours", (WidgetTester tester) async {
    await pumpApp(tester, _card());

    final FilledButton button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.style?.backgroundColor, isNull);
  });

  testWidgets("both buttons are at least 48 dp", (WidgetTester tester) async {
    await pumpApp(tester, _card());

    for (final String label in <String>["Delete", "Cancel"]) {
      final Size size = tester.getSize(
        find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((Widget w) => w is ButtonStyleButton)),
      );
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
    }
  });

  testWidgets("announces the title as a header", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpApp(tester, _card());

    expect(tester.getSemantics(find.text("Delete item?")), matchesSemantics(label: "Delete item?", isHeader: true));
    handle.dispose();
  });

  testWidgets("renders in the dark theme", (WidgetTester tester) async {
    await pumpApp(tester, _card(destructive: true), theme: AppTheme.dark());

    expect(find.text("Delete item?"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
