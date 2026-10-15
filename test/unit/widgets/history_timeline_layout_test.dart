// history_timeline_layout_test.dart
//
// Unit tests for HistoryTimelineLayout
// (lib/widgets/custom/HistoryTimeline/controllers/timeline_layout.dart): the
// pill's hidden count, the date-proportional dot positions (single-entry,
// equal-date, unsorted and narrow-strip cases), the minimum gap between
// close dots, and the non-overlapping hit spans.

import "package:flutter_skeleton/widgets/custom/HistoryTimeline/index.dart";
import "package:flutter_test/flutter_test.dart";

const HistoryTimelineLayout _layout = HistoryTimelineLayout(inset: 24);
const HistoryTimelineLayout _spaced = HistoryTimelineLayout(inset: 24, minGap: 12);

/// 1 March 2026 (UTC) plus [days].
DateTime _day(int days) => DateTime.utc(2026, 3).add(Duration(days: days));

void main() {
  group("hiddenCount", () {
    test("hides nothing when the entries fit", () {
      expect(_layout.hiddenCount(5, 6, expanded: false), 0);
      expect(_layout.hiddenCount(6, 6, expanded: false), 0);
    });

    test("hides the entries past maxVisible", () {
      expect(_layout.hiddenCount(8, 6, expanded: false), 2);
    });

    test("hides nothing once expanded", () {
      expect(_layout.hiddenCount(8, 6, expanded: true), 0);
    });
  });

  group("positions", () {
    test("returns nothing for no dates", () {
      expect(_layout.positions(const <DateTime>[], 400), isEmpty);
    });

    test("puts a single date at the left inset", () {
      expect(_layout.positions(<DateTime>[_day(0)], 400), <double>[24]);
    });

    test("puts the earliest and latest dates at the insets", () {
      expect(_layout.positions(<DateTime>[_day(0), _day(9)], 448), <double>[24, 424]);
    });

    test("places dates in proportion to their time", () {
      expect(
        _layout.positions(<DateTime>[_day(0), _day(10), _day(40)], 448),
        <double>[24, 124, 424],
      );
    });

    test("keeps the input order whatever the date order", () {
      expect(
        _layout.positions(<DateTime>[_day(40), _day(10), _day(0)], 448),
        <double>[424, 124, 24],
      );
    });

    test("spreads equal dates evenly in list order", () {
      final DateTime same = _day(3);
      expect(
        _layout.positions(<DateTime>[same, same, same], 448),
        <double>[24, 224, 424],
      );
    });

    test("puts every dot at the inset when the strip is narrower than two insets", () {
      expect(_layout.positions(<DateTime>[_day(0), _day(5)], 30), <double>[24, 24]);
      expect(_layout.positions(<DateTime>[_day(1), _day(1)], 30), <double>[24, 24]);
    });
  });
  group("positions with a minimum gap", () {
    test("leaves dots that are far enough apart in place", () {
      expect(
        _spaced.positions(<DateTime>[_day(0), _day(10), _day(40)], 448),
        <double>[24, 124, 424],
      );
    });

    test("pushes a dot away from a close later neighbour", () {
      expect(
        _spaced.positions(<DateTime>[_day(0), _day(39), _day(40)], 448),
        <double>[24, 412, 424],
      );
    });

    test("pushes a dot away from a close earlier neighbour", () {
      expect(
        _spaced.positions(<DateTime>[_day(0), _day(1), _day(40)], 448),
        <double>[24, 36, 424],
      );
    });

    test("separates equal dates in list order", () {
      expect(
        _spaced.positions(<DateTime>[_day(0), _day(40), _day(40)], 448),
        <double>[24, 412, 424],
      );
    });

    test("keeps the input order whatever the date order", () {
      expect(
        _spaced.positions(<DateTime>[_day(40), _day(39), _day(0)], 448),
        <double>[424, 412, 24],
      );
    });

    test("spreads the dots evenly when they cannot all fit the gap", () {
      expect(
        _spaced.positions(<DateTime>[_day(0), _day(1), _day(40)], 68),
        <double>[24, 34, 44],
      );
    });
  });

  group("hitSpans", () {
    test("returns nothing for no dots", () {
      expect(_layout.hitSpans(const <double>[], 24), isEmpty);
    });

    test("reaches the full width around dots far apart", () {
      expect(_layout.hitSpans(<double>[24, 224, 424], 24), <({double left, double right})>[
        (left: 0, right: 48),
        (left: 200, right: 248),
        (left: 400, right: 448),
      ]);
    });

    test("stops at the midpoint with a close neighbour", () {
      expect(_layout.hitSpans(<double>[24, 412, 424], 24), <({double left, double right})>[
        (left: 0, right: 48),
        (left: 388, right: 418),
        (left: 418, right: 448),
      ]);
    });

    test("keeps the input order whatever the position order", () {
      expect(_layout.hitSpans(<double>[424, 412, 24], 24), <({double left, double right})>[
        (left: 418, right: 448),
        (left: 388, right: 418),
        (left: 0, right: 48),
      ]);
    });

    test("splits equal centres at that x in list order", () {
      expect(_layout.hitSpans(<double>[100, 100], 24), <({double left, double right})>[
        (left: 76, right: 100),
        (left: 100, right: 124),
      ]);
    });
  });
}
