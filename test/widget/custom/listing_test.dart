// listing_test.dart
//
// Widget tests for Listing<T>: first page, empty / error states, retry,
// scroll-triggered pagination, and auto-fill of pages shorter than the viewport.

import "package:flutter/material.dart";
import "package:flutter_skeleton/api/dtos/_base/output/output_interface.dart";
import "package:flutter_skeleton/widgets/custom/Listing/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

final class _Item implements OutputInterface {
  final int id;
  _Item(this.id);
}

/// Fake paginated backend holding [total] items; records requested pages.
final class _FakeApi {
  final int total;
  final List<int> requestedPages = <int>[];
  bool fail = false;

  _FakeApi(this.total);

  Future<List<_Item>> call(int page, int itemPerPage) async {
    requestedPages.add(page);
    if (fail) throw Exception("network down");
    final int start = (page - 1) * itemPerPage;
    final int end = (start + itemPerPage).clamp(0, total);
    return <_Item>[for (int i = start; i < end; i++) _Item(i)];
  }
}

Widget _listing(_FakeApi api, {int itemPerPage = 20, double itemHeight = 60}) {
  return Listing<_Item>(
    apiCallback: api.call,
    itemPerPage: itemPerPage,
    itemBuilder: (BuildContext context, _Item item) => SizedBox(height: itemHeight, child: Text("item ${item.id}")),
    separatorBuilder: (BuildContext context, _Item item) => const SizedBox(height: 1),
    emptyBuilder: const Text("empty"),
    errorBuilder: (BuildContext context, VoidCallback retry) => TextButton(onPressed: retry, child: const Text("retry")),
  );
}

void main() {
  testWidgets("renders the first page", (WidgetTester tester) async {
    final _FakeApi api = _FakeApi(5);
    await pumpApp(tester, _listing(api));
    await tester.pumpAndSettle();

    expect(find.text("item 0"), findsOneWidget);
    expect(find.text("item 4"), findsOneWidget);
    // Page shorter than itemPerPage → no further request.
    expect(api.requestedPages, <int>[1]);
  });

  testWidgets("shows emptyBuilder when the first page is empty", (WidgetTester tester) async {
    await pumpApp(tester, _listing(_FakeApi(0)));
    await tester.pumpAndSettle();

    expect(find.text("empty"), findsOneWidget);
  });

  testWidgets("shows errorBuilder on failure and reloads on retry", (WidgetTester tester) async {
    final _FakeApi api = _FakeApi(3)..fail = true;
    await pumpApp(tester, _listing(api));
    await tester.pumpAndSettle();
    expect(find.text("retry"), findsOneWidget);

    api.fail = false;
    await tester.tap(find.text("retry"));
    await tester.pumpAndSettle();

    expect(find.text("item 0"), findsOneWidget);
    expect(api.requestedPages, <int>[1, 1]);
  });

  testWidgets("loads the next page when scrolling near the end", (WidgetTester tester) async {
    final _FakeApi api = _FakeApi(60);
    await pumpApp(tester, _listing(api), surfaceSize: const Size(400, 600));
    await tester.pumpAndSettle();
    expect(api.requestedPages, <int>[1]);

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(api.requestedPages, contains(2));
  });

  testWidgets("a full page shorter than the viewport loads the next one", (WidgetTester tester) async {
    final _FakeApi api = _FakeApi(7);
    await pumpApp(tester, _listing(api, itemPerPage: 3, itemHeight: 20), surfaceSize: const Size(400, 800));
    await tester.pumpAndSettle();

    // 3 + 3 + 1 items: pages 2 and 3 are fetched without any scroll.
    expect(api.requestedPages, <int>[1, 2, 3]);
    expect(find.text("item 6"), findsOneWidget);
  });
}
