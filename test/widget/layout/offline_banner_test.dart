// offline_banner_test.dart
//
// Widget tests for OfflineBanner driven by ConnectivityProvider.

import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/layout/OfflineBanner/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

void main() {
  testWidgets("hidden while online", (WidgetTester tester) async {
    await pumpApp(tester, const OfflineBanner(), providers: defaultTestProviders());

    expect(find.byIcon(Icons.cloud_off), findsNothing);
  });

  testWidgets("visible and announced while offline", (WidgetTester tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpApp(tester, const OfflineBanner(), providers: defaultTestProviders(offline: true));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    expect(find.bySemanticsLabel("offline.banner"), findsOneWidget);
    semantics.dispose();
  });
}
