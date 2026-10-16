// timeline_layout.dart
//
// HistoryTimelineLayout — pure placement maths of HistoryTimeline: how many
// entries collapse into the pill, the x centre of each dot for a strip width
// (nudged apart when dates nearly coincide) and the horizontal hit span of
// each dot. No widgets, so it is unit-tested on its own.

part of "../index.dart";

/// Placement maths of [HistoryTimeline].
@visibleForTesting
final class HistoryTimelineLayout {
  const HistoryTimelineLayout({required this.inset, this.minGap = 0});

  /// Distance between each strip edge and the outermost dot centres.
  final double inset;

  /// Smallest distance between two dot centres when the strip has room.
  final double minGap;

  /// Number of entries collapsed into the pill: none when [expanded] or
  /// when [total] fits in [maxVisible], else `total - maxVisible`.
  int hiddenCount(int total, int maxVisible, {required bool expanded}) {
    if (expanded || total <= maxVisible) return 0;
    return total - maxVisible;
  }

  /// X centre of each dot, in the order of [dates], for a strip [width] wide.
  ///
  /// The earliest date sits at [inset] and the latest at `width - inset`;
  /// the others are placed in proportion to their date, whatever the order
  /// of [dates]. Centres closer than [minGap] are then pushed apart, staying
  /// in date order (equal dates in list order) and inside the insets; when
  /// they cannot all fit [minGap] apart, they are spread evenly. A single
  /// date sits at [inset]. When every date is equal, the dots are spread
  /// evenly in list order. A strip narrower than two insets puts every dot
  /// at [inset].
  List<double> positions(List<DateTime> dates, double width) {
    if (dates.isEmpty) return const <double>[];
    final double length = math.max(0, width - 2 * inset);
    final List<int> times = dates
        .map((DateTime date) => date.millisecondsSinceEpoch)
        .toList(growable: false);
    final int first = times.reduce(math.min);
    final int span = times.reduce(math.max) - first;

    if (span == 0) return _evenly(dates.length, length);
    final List<double> xs = times
        .map((int time) => inset + (time - first) / span * length)
        .toList(growable: false);
    return _separate(xs, length);
  }

  /// Horizontal hit span of each dot centred at [xs], in the order of [xs].
  ///
  /// A span reaches at most [reach] on each side of its centre and stops at
  /// the midpoint with the nearest centre on either side, so the spans never
  /// overlap and a pointer always lands on the nearest dot. Equal centres
  /// split at that x, in list order.
  List<({double left, double right})> hitSpans(List<double> xs, double reach) {
    final List<int> order = _byPosition(xs);
    final List<({double left, double right})> spans = List<({double left, double right})>.filled(
      xs.length,
      (left: 0, right: 0),
    );
    for (int k = 0; k < order.length; k++) {
      final double x = xs[order[k]];
      final double left = k == 0 ? x - reach : math.max(x - reach, (xs[order[k - 1]] + x) / 2);
      final double right = k == order.length - 1 ? x + reach : math.min(x + reach, (x + xs[order[k + 1]]) / 2);
      spans[order[k]] = (left: left, right: right);
    }
    return spans;
  }

  /// Pushes the centres [xs] (spread over [length] from [inset]) at least
  /// [minGap] apart, or evenly when they cannot all fit; mutates [xs].
  List<double> _separate(List<double> xs, double length) {
    if (xs.length < 2 || minGap <= 0) return xs;
    final double gap = math.min(minGap, length / (xs.length - 1));
    final List<int> order = _byPosition(xs);
    for (int k = 1; k < order.length; k++) {
      xs[order[k]] = math.max(xs[order[k]], xs[order[k - 1]] + gap);
    }
    xs[order.last] = math.min(xs[order.last], inset + length);
    for (int k = order.length - 2; k >= 0; k--) {
      xs[order[k]] = math.min(xs[order[k]], xs[order[k + 1]] - gap);
    }
    return xs;
  }

  /// Indices of [xs] sorted by value, equal values in list order.
  List<int> _byPosition(List<double> xs) {
    return List<int>.generate(xs.length, (int i) => i)..sort((int a, int b) {
      final int byX = xs[a].compareTo(xs[b]);
      return byX != 0 ? byX : a - b;
    });
  }

  /// [count] centres spread evenly over [length], starting at [inset].
  List<double> _evenly(int count, double length) {
    if (count == 1) return <double>[inset];
    final double step = length / (count - 1);
    return List<double>.generate(count, (int i) => inset + i * step, growable: false);
  }
}
