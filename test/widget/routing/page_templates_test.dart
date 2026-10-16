// page_templates_test.dart
//
// Widget tests for the three page templates: title bar and back button,
// body constraints (bounded for FullPage / Splitted panels, scrolling for
// FollowUp), the Splitted wide / narrow layouts and the FollowUp action bar.

import "package:flutter/material.dart";
import "package:flutter_skeleton/routing/templates/FollowUpPageTemplate/index.dart";
import "package:flutter_skeleton/routing/templates/FullPageTemplate/index.dart";
import "package:flutter_skeleton/routing/templates/SplittedPageTemplate/index.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

/// Records the constraints its parent gives it.
final class _Probe extends StatelessWidget {
  final String label;
  final void Function(BoxConstraints constraints) onLayout;

  const _Probe(this.label, this.onLayout);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        onLayout(constraints);
        return Text(label);
      },
    );
  }
}

void main() {
  group("FullPageTemplate", _fullPageTests);
  group("SplittedPageTemplate", _splittedTests);
  group("FollowUpPageTemplate", _followUpTests);
}

void _fullPageTests() {
  testWidgets("shows the title, a back button only with onBack, and the trailing action", (WidgetTester tester) async {
    int back = 0;
    await pumpApp(
      tester,
      FullPageTemplate(title: "Page", onBack: () => back++, trailing: const Icon(Icons.share), child: const Text("body")),
    );

    expect(find.text("Page"), findsOneWidget);
    expect(find.byIcon(Icons.share), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    expect(back, 1);

    await pumpApp(tester, const FullPageTemplate(title: "Page", child: Text("body")));
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
  });

  testWidgets("gives the body bounded height and caps its width", (WidgetTester tester) async {
    BoxConstraints? body;
    await pumpApp(
      tester,
      FullPageTemplate(title: "Page", child: _Probe("body", (BoxConstraints c) => body = c)),
      surfaceSize: const Size(1200, 800),
    );

    expect(body!.hasBoundedHeight, isTrue);
    expect(body!.maxWidth, kContentMaxWidth);
  });
}

void _splittedTests() {
  testWidgets("puts the panels side by side from the breakpoint", (WidgetTester tester) async {
    BoxConstraints? primary;
    BoxConstraints? secondary;
    await pumpApp(
      tester,
      SplittedPageTemplate(
        title: "Split",
        primary: _Probe("primary", (BoxConstraints c) => primary = c),
        secondary: _Probe("secondary", (BoxConstraints c) => secondary = c),
      ),
      surfaceSize: const Size(1000, 700),
    );

    expect(tester.getTopLeft(find.text("secondary")).dx, greaterThan(tester.getTopLeft(find.text("primary")).dx));
    expect(primary!.maxWidth, 400);
    expect(secondary!.maxWidth, 1000 - 400 - 1);
    expect(primary!.hasBoundedHeight && secondary!.hasBoundedHeight, isTrue);
    expect(find.byType(VerticalDivider), findsOneWidget);
  });

  testWidgets("honours primaryWidth and mirrors in RTL", (WidgetTester tester) async {
    BoxConstraints? primary;
    await pumpApp(
      tester,
      Directionality(
        textDirection: TextDirection.rtl,
        child: SplittedPageTemplate(
          title: "Split",
          primaryWidth: 320,
          primary: _Probe("primary", (BoxConstraints c) => primary = c),
          secondary: const Text("secondary"),
        ),
      ),
      surfaceSize: const Size(1000, 700),
    );

    expect(primary!.maxWidth, 320);
    expect(tester.getTopLeft(find.text("primary")).dx, greaterThan(tester.getTopLeft(find.text("secondary")).dx));
  });

  testWidgets("stacks the panels below the breakpoint, half the height each", (WidgetTester tester) async {
    BoxConstraints? primary;
    BoxConstraints? secondary;
    await pumpApp(
      tester,
      SplittedPageTemplate(
        title: "Split",
        primary: _Probe("primary", (BoxConstraints c) => primary = c),
        secondary: _Probe("secondary", (BoxConstraints c) => secondary = c),
      ),
      surfaceSize: const Size(400, 800),
    );

    expect(tester.getTopLeft(find.text("secondary")).dy, greaterThan(tester.getTopLeft(find.text("primary")).dy));
    expect(primary!.maxWidth, 400);
    expect(primary!.maxHeight, closeTo(secondary!.maxHeight, 0.01));
    expect(find.byType(Divider), findsOneWidget);
    expect(find.byType(VerticalDivider), findsNothing);
  });

  testWidgets("shows a back button only with onBack", (WidgetTester tester) async {
    int back = 0;
    await pumpApp(
      tester,
      SplittedPageTemplate(title: "Split", onBack: () => back++, primary: const Text("p"), secondary: const Text("s")),
      surfaceSize: const Size(1000, 700),
    );
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    expect(back, 1);

    await pumpApp(
      tester,
      const SplittedPageTemplate(title: "Split", primary: Text("p"), secondary: Text("s")),
      surfaceSize: const Size(1000, 700),
    );
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
  });
}

void _followUpTests() {
  testWidgets("always shows the back button and calls onBack", (WidgetTester tester) async {
    int back = 0;
    await pumpApp(tester, FollowUpPageTemplate(title: "Next", onBack: () => back++, child: const Text("body")));

    expect(find.text("Next"), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    expect(back, 1);
  });

  testWidgets("scrolls a tall body while the actions stay visible", (WidgetTester tester) async {
    await pumpApp(
      tester,
      FollowUpPageTemplate(
        title: "Next",
        onBack: () {},
        actions: FilledButton(onPressed: () {}, child: const Text("Continue")),
        child: Column(children: <Widget>[for (int i = 0; i < 60; i++) SizedBox(height: 40, child: Text("row $i"))]),
      ),
      surfaceSize: const Size(600, 700),
    );

    expect(find.text("Continue").hitTestable(), findsOneWidget);
    expect(find.text("row 59").hitTestable(), findsNothing);

    await tester.dragUntilVisible(find.text("row 59"), find.byType(SingleChildScrollView), const Offset(0, -300));
    expect(find.text("row 59").hitTestable(), findsOneWidget);
    expect(find.text("Continue").hitTestable(), findsOneWidget);
    expect(tester.getBottomLeft(find.text("row 59")).dy, lessThan(tester.getTopLeft(find.text("Continue")).dy));
  });

  testWidgets("caps the body at kContentMaxWidth and pads it", (WidgetTester tester) async {
    BoxConstraints? body;
    await pumpApp(
      tester,
      FollowUpPageTemplate(title: "Next", onBack: () {}, child: _Probe("body", (BoxConstraints c) => body = c)),
      surfaceSize: const Size(1200, 800),
    );

    expect(body!.maxWidth, kContentMaxWidth);
    expect(body!.hasBoundedHeight, isFalse);
    expect(tester.getTopLeft(find.text("body")).dy, greaterThanOrEqualTo(56 + kDefaultPadding * 2));
  });

  testWidgets("hides the action bar without actions", (WidgetTester tester) async {
    await pumpApp(tester, FollowUpPageTemplate(title: "Next", onBack: () {}, child: const Text("body")));

    expect(find.byType(SafeArea), findsNothing);
  });
}
