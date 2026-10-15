// thumbnail_metric_card_test.dart
//
// Widget tests for ThumbnailMetricCard: title and subtitle, value columns and
// their tone markers, the StatusPill change badge and its spoken label, the
// thumbnail (placeholder, loading, failed image), tap handling and button
// semantics, the card surface, the merged semantics node, a narrow layout and
// the dark theme.

import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";
import "package:flutter_skeleton/widgets/custom/ThumbnailMetricCard/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _title = "Item A";
const String _deltaKey = "custom.thumbnail_metric_card.delta";

const List<ThumbnailMetric> _twoMetrics = <ThumbnailMetric>[
  ThumbnailMetric(label: "BEFORE", value: "0.87", tone: StatusTone.success, toneLabel: "Good"),
  ThumbnailMetric(label: "AFTER", value: "0.74", tone: StatusTone.warning, toneLabel: "Fair"),
];

/// An image whose load always fails (no I/O).
final class _FailingImage extends ImageProvider<_FailingImage> {
  @override
  Future<_FailingImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_FailingImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(_FailingImage key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(Future<ImageInfo>.error(StateError("no image")));
  }
}

/// An image that never finishes loading (no I/O).
final class _PendingImage extends ImageProvider<_PendingImage> {
  @override
  Future<_PendingImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_PendingImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(_PendingImage key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
  }
}

Finder _inCard(Finder matching) {
  return find.descendant(of: find.byType(ThumbnailMetricCard), matching: matching);
}

Text _text(WidgetTester tester, String data) => tester.widget<Text>(find.text(data));

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(ThumbnailMetricCard).first)).colorScheme;
}

ToneColors _tone(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(tester.element(find.byType(ThumbnailMetricCard).first), tone);
}

/// Pumps [card] in a 360 dp-wide column.
Future<void> _pumpCard(WidgetTester tester, ThumbnailMetricCard card, {ThemeData? theme}) {
  return pumpApp(
    tester,
    Align(alignment: Alignment.topLeft, child: SizedBox(width: 360, child: card)),
    theme: theme,
  );
}

void main() {
  group("titles", () {
    testWidgets("shows the title on one line, 13 / w800 in cs.onSurface", (WidgetTester tester) async {
      await _pumpCard(tester, const ThumbnailMetricCard(title: _title));

      final Text title = _text(tester, _title);
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
      expect(title.style!.fontSize, 13);
      expect(title.style!.fontWeight, FontWeight.w800);
      expect(title.style!.color, _scheme(tester).onSurface);
    });

    testWidgets("shows the subtitle under the title, 11 / w500 muted", (WidgetTester tester) async {
      await _pumpCard(tester, const ThumbnailMetricCard(title: _title, subtitle: "Group B"));

      final Text subtitle = _text(tester, "Group B");
      expect(subtitle.maxLines, 1);
      expect(subtitle.overflow, TextOverflow.ellipsis);
      expect(subtitle.style!.fontSize, 11);
      expect(subtitle.style!.fontWeight, FontWeight.w500);
      expect(subtitle.style!.color, _scheme(tester).onSurfaceVariant);
      expect(tester.getTopLeft(find.text("Group B")).dy, greaterThan(tester.getTopLeft(find.text(_title)).dy));
    });

    testWidgets("a null or empty subtitle is hidden", (WidgetTester tester) async {
      await _pumpCard(tester, const ThumbnailMetricCard(title: _title));
      expect(_inCard(find.byType(Text)), findsOneWidget);

      await _pumpCard(tester, const ThumbnailMetricCard(title: _title, subtitle: ""));
      expect(_inCard(find.byType(Text)), findsOneWidget);
    });
  });

  group("metrics", () {
    testWidgets("one label / value column per metric, in order", (WidgetTester tester) async {
      await _pumpCard(tester, const ThumbnailMetricCard(title: _title, metrics: _twoMetrics));

      for (final String data in <String>["BEFORE", "0.87", "AFTER", "0.74"]) {
        expect(find.text(data), findsOneWidget);
      }
      expect(tester.getCenter(find.text("AFTER")).dx, greaterThan(tester.getCenter(find.text("BEFORE")).dx));
      expect(tester.getCenter(find.text("0.87")).dy, greaterThan(tester.getCenter(find.text("BEFORE")).dy));
      expect(tester.getCenter(find.text("BEFORE")).dx, greaterThan(tester.getCenter(find.text(_title)).dx));
    });

    testWidgets("labels are 9 / w700 muted, values 12 / w800 in cs.onSurface", (WidgetTester tester) async {
      await _pumpCard(tester, const ThumbnailMetricCard(title: _title, metrics: _twoMetrics));

      final TextStyle label = _text(tester, "BEFORE").style!;
      expect(label.fontSize, 9);
      expect(label.fontWeight, FontWeight.w700);
      expect(label.letterSpacing, 0.5);
      expect(label.color, _scheme(tester).onSurfaceVariant);

      final TextStyle value = _text(tester, "0.87").style!;
      expect(value.fontSize, 12);
      expect(value.fontWeight, FontWeight.w800);
      expect(value.color, _scheme(tester).onSurface);
    });

    testWidgets("no metrics renders no columns", (WidgetTester tester) async {
      await _pumpCard(tester, const ThumbnailMetricCard(title: _title));

      expect(_inCard(find.byType(Text)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("a tone draws its StatusTone.icon in the tone foreground before the value", (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, const ThumbnailMetricCard(title: _title, metrics: _twoMetrics));

      final Icon success = tester.widget<Icon>(find.byIcon(StatusTone.success.icon));
      expect(success.size, 12);
      expect(success.color, _tone(tester, StatusTone.success).foreground);
      expect(success.semanticLabel, "Good");
      expect(tester.getCenter(find.byIcon(StatusTone.success.icon)).dx, lessThan(tester.getCenter(find.text("0.87")).dx));

      final Icon warning = tester.widget<Icon>(find.byIcon(StatusTone.warning.icon));
      expect(warning.color, _tone(tester, StatusTone.warning).foreground);
    });

    testWidgets("a metric without tone has no marker", (WidgetTester tester) async {
      await _pumpCard(
        tester,
        const ThumbnailMetricCard(
          title: _title,
          metrics: <ThumbnailMetric>[ThumbnailMetric(label: "NOW", value: "12 ms")],
        ),
      );

      expect(find.text("12 ms"), findsOneWidget);
      expect(_inCard(find.byType(Icon)), findsOneWidget); // the placeholder only
    });
  });

  group("delta badge", () {
    testWidgets("renders a dense StatusPill with the text and tone", (WidgetTester tester) async {
      await _pumpCard(
        tester,
        const ThumbnailMetricCard(title: _title, metrics: _twoMetrics, delta: "+0.13", deltaTone: StatusTone.success),
      );

      final StatusPill pill = tester.widget<StatusPill>(find.byType(StatusPill));
      expect(pill.label, "+0.13");
      expect(pill.tone, StatusTone.success);
      expect(pill.dense, isTrue);
      expect(find.text("+0.13"), findsOneWidget);
      expect(tester.getCenter(find.byType(StatusPill)).dx, greaterThan(tester.getCenter(find.text("AFTER")).dx));
    });

    testWidgets("the tone defaults to neutral", (WidgetTester tester) async {
      await _pumpCard(tester, const ThumbnailMetricCard(title: _title, delta: "-0.05"));

      expect(tester.widget<StatusPill>(find.byType(StatusPill)).tone, StatusTone.neutral);
    });

    testWidgets("a null or empty delta shows no badge", (WidgetTester tester) async {
      await _pumpCard(tester, const ThumbnailMetricCard(title: _title));
      expect(find.byType(StatusPill), findsNothing);

      await _pumpCard(tester, const ThumbnailMetricCard(title: _title, delta: ""));
      expect(find.byType(StatusPill), findsNothing);
    });

    testWidgets("is announced with the delta key by default", (WidgetTester tester) async {
      await _pumpCard(tester, const ThumbnailMetricCard(title: _title, delta: "+0.13"));

      expect(tester.widget<StatusPill>(find.byType(StatusPill)).semanticsLabel, _deltaKey);
    });

    testWidgets("deltaSemanticsLabel replaces the default label; empty falls back", (WidgetTester tester) async {
      await _pumpCard(
        tester,
        const ThumbnailMetricCard(title: _title, delta: "+0.13", deltaSemanticsLabel: "Up 0.13, better"),
      );
      expect(tester.widget<StatusPill>(find.byType(StatusPill)).semanticsLabel, "Up 0.13, better");

      await _pumpCard(tester, const ThumbnailMetricCard(title: _title, delta: "+0.13", deltaSemanticsLabel: ""));
      expect(tester.widget<StatusPill>(find.byType(StatusPill)).semanticsLabel, _deltaKey);
    });
  });

  group("thumbnail", () {
    testWidgets("a null image shows the default placeholder on cs.surfaceContainerHighest", (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, const ThumbnailMetricCard(title: _title));

      final Icon icon = tester.widget<Icon>(find.byIcon(Icons.image_outlined));
      expect(icon.size, 24);
      expect(icon.color, _scheme(tester).onSurfaceVariant);
      final ColoredBox box = tester.widget<ColoredBox>(
        find.ancestor(of: find.byIcon(Icons.image_outlined), matching: find.byType(ColoredBox)).first,
      );
      expect(box.color, _scheme(tester).surfaceContainerHighest);
      expect(tester.getSize(find.byType(ClipRRect)), const Size(56, 56));
    });

    testWidgets("placeholderIcon replaces the default icon", (WidgetTester tester) async {
      await _pumpCard(tester, const ThumbnailMetricCard(title: _title, placeholderIcon: Icons.dns_outlined));

      expect(find.byIcon(Icons.dns_outlined), findsOneWidget);
      expect(find.byIcon(Icons.image_outlined), findsNothing);
    });

    testWidgets("an image is drawn 56 × 56, scaled to cover", (WidgetTester tester) async {
      final _PendingImage image = _PendingImage();
      await _pumpCard(tester, ThumbnailMetricCard(title: _title, image: image));

      final Image widget = tester.widget<Image>(find.byType(Image));
      expect(widget.image, same(image));
      expect(widget.fit, BoxFit.cover);
      expect(tester.getSize(find.byType(Image)), const Size(56, 56));
      expect(find.byIcon(Icons.image_outlined), findsNothing);
    });

    testWidgets("a failed image falls back to the placeholder", (WidgetTester tester) async {
      await _pumpCard(tester, ThumbnailMetricCard(title: _title, image: _FailingImage()));
      await tester.pump();

      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group("tap", () {
    testWidgets("tapping the card calls onTap once", (WidgetTester tester) async {
      int taps = 0;
      await _pumpCard(tester, ThumbnailMetricCard(title: _title, metrics: _twoMetrics, onTap: () => taps++));

      expect(_inCard(find.byType(InkWell)), findsOneWidget);
      await tester.tap(find.text(_title));
      expect(taps, 1);
    });

    testWidgets("without onTap there is no ink", (WidgetTester tester) async {
      await _pumpCard(tester, const ThumbnailMetricCard(title: _title));

      expect(_inCard(find.byType(InkWell)), findsNothing);
    });

    testWidgets("the card is at least 48 dp tall", (WidgetTester tester) async {
      await _pumpCard(tester, ThumbnailMetricCard(title: _title, onTap: () {}));

      expect(tester.getSize(find.byType(ThumbnailMetricCard)).height, greaterThanOrEqualTo(48));
    });
  });

  group("card", () {
    testWidgets("is a cs.surfaceContainerLow Material with a radius-16 cs.outlineVariant border", (
      WidgetTester tester,
    ) async {
      await _pumpCard(tester, const ThumbnailMetricCard(title: _title));

      final Material material = tester.widget<Material>(_inCard(find.byType(Material)).first);
      expect(material.color, _scheme(tester).surfaceContainerLow);
      final RoundedRectangleBorder shape = material.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(16));
      expect(shape.side.color, _scheme(tester).outlineVariant);
    });

    testWidgets("pads its content by 12 dp", (WidgetTester tester) async {
      await _pumpCard(tester, const ThumbnailMetricCard(title: _title));

      final Offset card = tester.getTopLeft(find.byType(ThumbnailMetricCard));
      final Offset thumbnail = tester.getTopLeft(find.byType(ClipRRect));
      expect(thumbnail - card, const Offset(12, 12));
    });
  });

  group("semantics", () {
    testWidgets("one merged button node reading titles, columns and badge", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpCard(
        tester,
        ThumbnailMetricCard(
          title: _title,
          subtitle: "Group B",
          metrics: _twoMetrics,
          delta: "+0.13",
          deltaTone: StatusTone.success,
          onTap: () {},
        ),
      );

      expect(
        tester.getSemantics(find.byType(ThumbnailMetricCard)),
        isSemantics(
          label: "$_title\nGroup B\nBEFORE\nGood\n0.87\nAFTER\nFair\n0.74\n$_deltaKey",
          isButton: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets("without onTap the node is not a button", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpCard(tester, const ThumbnailMetricCard(title: _title));

      expect(
        tester.getSemantics(find.byType(ThumbnailMetricCard)),
        isSemantics(label: _title, isButton: false, hasTapAction: false),
      );
      handle.dispose();
    });

    testWidgets("the thumbnail and an unlabelled tone marker are not announced", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpCard(
        tester,
        ThumbnailMetricCard(
          title: _title,
          image: _PendingImage(),
          metrics: const <ThumbnailMetric>[ThumbnailMetric(label: "NOW", value: "1", tone: StatusTone.info)],
        ),
      );

      expect(tester.getSemantics(find.byType(ThumbnailMetricCard)).label, "$_title\nNOW\n1");
      handle.dispose();
    });
  });

  group("layout", () {
    testWidgets("a long title ellipsizes at 360 dp without overflow", (WidgetTester tester) async {
      const String longTitle = "An item name long enough to never fit next to two columns and a badge";
      await _pumpCard(
        tester,
        const ThumbnailMetricCard(
          title: longTitle,
          subtitle: "A subtitle that is also far too long for the space left",
          metrics: _twoMetrics,
          delta: "-0.05",
          deltaTone: StatusTone.danger,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(ThumbnailMetricCard)).width, 360);
      expect(tester.getTopRight(find.text(longTitle)).dx, lessThan(tester.getTopLeft(find.text("BEFORE")).dx));
    });
  });

  testWidgets("dark theme: renders with the dark scheme and tones", (WidgetTester tester) async {
    await _pumpCard(
      tester,
      ThumbnailMetricCard(
        title: _title,
        subtitle: "Group B",
        metrics: _twoMetrics,
        delta: "-0.05",
        deltaTone: StatusTone.danger,
        onTap: () {},
      ),
      theme: AppTheme.dark(),
    );

    expect(tester.takeException(), isNull);
    expect(_scheme(tester).brightness, Brightness.dark);
    expect(_text(tester, _title).style!.color, _scheme(tester).onSurface);
    expect(
      tester.widget<Icon>(find.byIcon(StatusTone.success.icon)).color,
      _tone(tester, StatusTone.success).foreground,
    );
    expect(
      tester.widget<Material>(_inCard(find.byType(Material)).first).color,
      _scheme(tester).surfaceContainerLow,
    );
  });
}
