// thumbnail_choice_picker_test.dart
//
// Widget tests for ThumbnailChoicePicker: title / subtitle / cards-only
// layouts, side-by-side vs stacked placement (breakpoint and room left to the
// title), no overflow at narrow widths and large text, card order and
// captions, the selected border / badge / caption colours, onChanged (not on
// the selected card, disabled picker, disabled option), button semantics in a
// mutually exclusive group, the excluded thumbnail, tap-target guidelines,
// custom previews, the scheme mockup with and without a background image (and
// a failing one), no Material ancestor, the dark theme and the asserts.

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/ThumbnailChoicePicker/index.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

enum _Mode { first, second, third, fourth }

const List<String> _labels = <String>["Alpha", "Beta", "Gamma", "Delta"];

const String _title = "Title";
const String _subtitle = "Subtitle";

/// 1 × 1 transparent PNG.
final Uint8List _transparentPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

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

/// Records the values reported by onChanged.
final class _Calls {
  final List<_Mode> changed = <_Mode>[];
}

ValueKey<String> _previewKey(String label) => ValueKey<String>("preview $label");

/// [count] choices with keyed custom previews.
List<ThumbnailChoice<_Mode>> _choices(int count) {
  return <ThumbnailChoice<_Mode>>[
    for (int i = 0; i < count; i++)
      ThumbnailChoice<_Mode>(
        option: ChoiceOption<_Mode>(value: _Mode.values[i], label: _labels[i]),
        preview: SizedBox.expand(key: _previewKey(_labels[i])),
      ),
  ];
}

ThumbnailChoicePicker<_Mode> _picker(
  _Calls calls, {
  List<ThumbnailChoice<_Mode>>? choices,
  _Mode? selected = _Mode.second,
  bool enabled = true,
  String? title = _title,
  String? subtitle = _subtitle,
  Size thumbnailSize = const Size(96, 64),
}) {
  return ThumbnailChoicePicker<_Mode>(
    choices: choices ?? _choices(2),
    selected: selected,
    onChanged: enabled ? calls.changed.add : null,
    title: title,
    subtitle: subtitle,
    thumbnailSize: thumbnailSize,
  );
}

/// The InkWell of the card captioned [label].
Finder _card(String label) {
  return find.ancestor(of: find.text(label), matching: find.byType(InkWell));
}

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(ThumbnailChoicePicker<_Mode>))).colorScheme;
}

BoxDecoration _frameDecoration(WidgetTester tester, String label) {
  final Finder frame = find.descendant(
    of: _card(label),
    matching: find.byWidgetPredicate(
      (Widget w) => w is Container && w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).border != null,
    ),
  );
  return tester.widget<Container>(frame).decoration! as BoxDecoration;
}

Color _borderColor(WidgetTester tester, String label) {
  return (_frameDecoration(tester, label).border! as Border).top.color;
}

Color? _captionColor(WidgetTester tester, String label) => tester.widget<Text>(find.text(label)).style?.color;

double _opacity(WidgetTester tester, String label) {
  return tester.widget<Opacity>(find.ancestor(of: _card(label), matching: find.byType(Opacity)).first).opacity;
}

Finder _coloredBox(Color color) => find.byWidgetPredicate((Widget w) => w is ColoredBox && w.color == color);

Finder _decoratedBox(Color color) {
  return find.byWidgetPredicate(
    (Widget w) => w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).color == color,
  );
}

void main() {
  group("ThumbnailChoicePicker layout", () {
    testWidgets("renders the title and subtitle beside the cards when wide", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls()));

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_subtitle), findsOneWidget);
      final Rect card = tester.getRect(_card("Alpha"));
      final Offset title = tester.getCenter(find.text(_title));
      expect(tester.getTopRight(find.text(_title)).dx, lessThan(card.left));
      expect(title.dy, inExclusiveRange(card.top, card.bottom));
      expect(tester.getTopLeft(find.text(_title)).dy, lessThan(tester.getTopLeft(find.text(_subtitle)).dy));
    });

    testWidgets("stacks the title above the cards below the breakpoint", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls()), surfaceSize: const Size(320, 600));

      expect(
        tester.getBottomLeft(find.text(_subtitle)).dy,
        lessThan(tester.getTopLeft(_card("Alpha")).dy),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets("stays side by side at exactly the breakpoint", (WidgetTester tester) async {
      await pumpApp(
        tester,
        ThumbnailChoicePicker<_Mode>(
          choices: _choices(2),
          selected: null,
          onChanged: null,
          title: _title,
          padding: EdgeInsets.zero,
        ),
        surfaceSize: const Size(360, 600),
      );

      expect(tester.getTopRight(find.text(_title)).dx, lessThan(tester.getTopLeft(_card("Alpha")).dx));
    });

    testWidgets("stacks when the cards leave too little room to the title", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls(), choices: _choices(4)), surfaceSize: const Size(480, 600));

      expect(
        tester.getBottomLeft(find.text(_subtitle)).dy,
        lessThan(tester.getTopLeft(_card("Alpha")).dy),
      );
    });

    testWidgets("renders only the cards without title and subtitle", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls(), title: null, subtitle: null));

      expect(find.byType(Text), findsNWidgets(2));
      expect(find.byType(MergeSemantics), findsNothing);
      expect(find.byType(Row), findsNothing);
    });

    testWidgets("renders the subtitle alone when the title is null", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls(), title: null));

      expect(find.text(_title), findsNothing);
      expect(find.text(_subtitle), findsOneWidget);
    });

    testWidgets("renders one card per choice, in order, with its caption", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls(), choices: _choices(3), title: null, subtitle: null));

      expect(find.byType(InkWell), findsNWidgets(3));
      final double alpha = tester.getCenter(find.text("Alpha")).dx;
      final double beta = tester.getCenter(find.text("Beta")).dx;
      final double gamma = tester.getCenter(find.text("Gamma")).dx;
      expect(alpha < beta && beta < gamma, isTrue);
      expect(tester.getSize(_card("Alpha")).width, 96);
    });

    testWidgets("never overflows at 320, 375 and 480 dp with 2 and 4 choices", (WidgetTester tester) async {
      for (final double width in <double>[320, 375, 480]) {
        for (final int count in <int>[2, 4]) {
          await pumpApp(tester, _picker(_Calls(), choices: _choices(count)), surfaceSize: Size(width, 800));
          expect(tester.takeException(), isNull, reason: "$count choices at $width dp");
          expect(tester.getTopRight(_card(_labels[count - 1])).dx, lessThanOrEqualTo(width));
        }
      }
    });

    testWidgets("never overflows with large text", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
            child: _picker(_Calls(), choices: _choices(4)),
          ),
        ),
        surfaceSize: const Size(320, 800),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group("ThumbnailChoicePicker selection", () {
    testWidgets("only the selected card shows the check badge and a primary border", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls()));
      final ColorScheme cs = _scheme(tester);

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.descendant(of: _card("Beta"), matching: find.byIcon(Icons.check_rounded)), findsOneWidget);
      expect(_borderColor(tester, "Beta"), cs.primary);
      expect(_borderColor(tester, "Alpha"), cs.outlineVariant);
      expect(_frameDecoration(tester, "Beta").boxShadow, isNotEmpty);
      expect(_frameDecoration(tester, "Alpha").boxShadow, isNull);
    });

    testWidgets("a null selection shows no badge", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls(), selected: null));
      final ColorScheme cs = _scheme(tester);

      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(_borderColor(tester, "Alpha"), cs.outlineVariant);
      expect(_borderColor(tester, "Beta"), cs.outlineVariant);
    });

    testWidgets("captions are primary when selected and muted otherwise", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls()));
      final ColorScheme cs = _scheme(tester);

      expect(_captionColor(tester, "Beta"), cs.primary);
      expect(_captionColor(tester, "Alpha"), cs.onSurfaceVariant);
    });

    testWidgets("tapping an unselected card reports its value once", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _picker(calls));

      await tester.tap(_card("Alpha"));
      await tester.pump();

      expect(calls.changed, <_Mode>[_Mode.first]);
    });

    testWidgets("tapping the selected card does not call onChanged", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _picker(calls));

      await tester.tap(_card("Beta"));
      await tester.pump();

      expect(calls.changed, isEmpty);
    });

    testWidgets("a null onChanged disables and dims every card", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _picker(calls, enabled: false));

      await tester.tap(_card("Alpha"));
      await tester.pump();

      expect(calls.changed, isEmpty);
      expect(tester.widget<InkWell>(_card("Alpha")).onTap, isNull);
      expect(_opacity(tester, "Alpha"), 0.38);
      expect(_opacity(tester, "Beta"), 0.38);
    });

    testWidgets("a disabled option is dimmed and ignores taps", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      final List<ThumbnailChoice<_Mode>> choices = <ThumbnailChoice<_Mode>>[
        const ThumbnailChoice<_Mode>(
          option: ChoiceOption<_Mode>(value: _Mode.first, label: "Alpha", enabled: false),
          preview: SizedBox.expand(),
        ),
        ..._choices(3).skip(1),
      ];
      await pumpApp(tester, _picker(calls, choices: choices));

      await tester.tap(_card("Alpha"));
      await tester.tap(_card("Gamma"));
      await tester.pump();

      expect(calls.changed, <_Mode>[_Mode.third]);
      expect(_opacity(tester, "Alpha"), 0.38);
      expect(_opacity(tester, "Gamma"), 1);
    });
  });

  group("ThumbnailChoicePicker semantics", () {
    testWidgets("each card is a selectable button of a mutually exclusive group", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _picker(_Calls()));

      expect(
        tester.getSemantics(find.bySemanticsLabel("Beta")),
        isSemantics(
          label: "Beta",
          isButton: true,
          isInMutuallyExclusiveGroup: true,
          hasSelectedState: true,
          isSelected: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel("Alpha")),
        isSemantics(label: "Alpha", isButton: true, hasSelectedState: true, isSelected: false),
      );
      handle.dispose();
    });

    testWidgets("disabled cards report enabled false", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _picker(_Calls(), enabled: false));

      expect(
        tester.getSemantics(find.bySemanticsLabel("Alpha")),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false, hasTapAction: false),
      );
      handle.dispose();
    });

    testWidgets("semanticsLabel replaces the caption for screen readers", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<ThumbnailChoice<_Mode>> choices = <ThumbnailChoice<_Mode>>[
        const ThumbnailChoice<_Mode>(
          option: ChoiceOption<_Mode>(value: _Mode.first, label: "Alpha", semanticsLabel: "Spoken alpha"),
          preview: SizedBox.expand(),
        ),
      ];
      await pumpApp(tester, _picker(_Calls(), choices: choices));

      expect(find.bySemanticsLabel("Spoken alpha"), findsOneWidget);
      expect(find.bySemanticsLabel("Alpha"), findsNothing);
      handle.dispose();
    });

    testWidgets("the thumbnail content is excluded from semantics", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<ThumbnailChoice<_Mode>> choices = <ThumbnailChoice<_Mode>>[
        const ThumbnailChoice<_Mode>(
          option: ChoiceOption<_Mode>(value: _Mode.first, label: "Alpha"),
          preview: Center(child: Text("Inside")),
        ),
      ];
      await pumpApp(tester, _picker(_Calls(), choices: choices));

      expect(find.text("Inside"), findsOneWidget);
      expect(find.bySemanticsLabel("Inside"), findsNothing);
      handle.dispose();
    });

    testWidgets("title and subtitle are announced together", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _picker(_Calls()));

      expect(find.bySemanticsLabel(RegExp("^$_title\\s+$_subtitle\$")), findsOneWidget);
      handle.dispose();
    });

    testWidgets("cards meet the tap target guidelines", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _picker(_Calls(), thumbnailSize: const Size(kMinTapTarget, kMinTapTarget)));

      final Size size = tester.getSize(_card("Alpha"));
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group("ThumbnailChoicePicker thumbnails", () {
    testWidgets("a custom preview fills the frame inside its border", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls(), thumbnailSize: const Size(120, 80)));

      expect(tester.getSize(find.byKey(_previewKey("Alpha"))), const Size(116, 76));
      expect(find.ancestor(of: find.byKey(_previewKey("Alpha")), matching: find.byType(ClipRRect)), findsOneWidget);
    });

    testWidgets("a scheme mockup is drawn from the given ColorScheme", (WidgetTester tester) async {
      final ColorScheme dark = AppTheme.dark().colorScheme;
      await pumpApp(
        tester,
        _picker(
          _Calls(),
          selected: null,
          choices: <ThumbnailChoice<_Mode>>[
            ThumbnailChoice<_Mode>.scheme(
              option: const ChoiceOption<_Mode>(value: _Mode.first, label: "Alpha"),
              scheme: dark,
            ),
          ],
        ),
      );

      Finder inCard(Finder finder) => find.descendant(of: _card("Alpha"), matching: finder);
      expect(inCard(_coloredBox(dark.surface)), findsOneWidget);
      expect(inCard(_coloredBox(dark.surfaceContainerHigh)), findsOneWidget);
      expect(inCard(_coloredBox(dark.surfaceContainer)), findsOneWidget);
      expect(inCard(_decoratedBox(dark.primary)), findsOneWidget);
      expect(inCard(_decoratedBox(dark.outlineVariant)), findsNWidgets(2));
      expect(inCard(find.byType(Image)), findsNothing);
    });

    testWidgets("a background image is drawn under a surface veil", (WidgetTester tester) async {
      final ColorScheme light = AppTheme.light().colorScheme;
      await pumpApp(
        tester,
        _picker(
          _Calls(),
          choices: <ThumbnailChoice<_Mode>>[
            ThumbnailChoice<_Mode>.scheme(
              option: const ChoiceOption<_Mode>(value: _Mode.first, label: "Alpha"),
              scheme: light,
              backgroundImage: MemoryImage(_transparentPng),
            ),
          ],
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(_coloredBox(light.surface.withValues(alpha: 0.42)), findsOneWidget);
      expect(_coloredBox(light.surfaceContainerHigh.withValues(alpha: 0.89)), findsOneWidget);
      expect(_decoratedBox(light.surface.withValues(alpha: 0.7)), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets("an image that fails to load falls back to the plain surface", (WidgetTester tester) async {
      final ColorScheme light = AppTheme.light().colorScheme;
      await pumpApp(
        tester,
        _picker(
          _Calls(),
          choices: <ThumbnailChoice<_Mode>>[
            ThumbnailChoice<_Mode>.scheme(
              option: const ChoiceOption<_Mode>(value: _Mode.first, label: "Alpha"),
              scheme: light,
              backgroundImage: _FailingImage(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.descendant(of: find.byType(Image), matching: find.byType(RawImage)), findsNothing);
      expect(_coloredBox(light.surface), findsOneWidget);
    });

    testWidgets("the mockup fits the smallest frame", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _picker(
          _Calls(),
          thumbnailSize: const Size(kMinTapTarget, kMinTapTarget),
          choices: <ThumbnailChoice<_Mode>>[
            ThumbnailChoice<_Mode>.scheme(
              option: const ChoiceOption<_Mode>(value: _Mode.first, label: "Alpha"),
              scheme: AppTheme.light().colorScheme,
              backgroundImage: MemoryImage(_transparentPng),
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group("ThumbnailChoicePicker environment", () {
    testWidgets("works without a Material ancestor", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: Center(child: _picker(calls))),
      );

      await tester.tap(_card("Alpha"));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(calls.changed, <_Mode>[_Mode.first]);
    });

    testWidgets("renders under the dark theme", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _picker(
          _Calls(),
          choices: <ThumbnailChoice<_Mode>>[
            ThumbnailChoice<_Mode>.scheme(
              option: const ChoiceOption<_Mode>(value: _Mode.first, label: "Alpha"),
              scheme: AppTheme.light().colorScheme,
            ),
            ThumbnailChoice<_Mode>.scheme(
              option: const ChoiceOption<_Mode>(value: _Mode.second, label: "Beta"),
              scheme: AppTheme.dark().colorScheme,
            ),
          ],
        ),
        theme: AppTheme.dark(),
      );
      final ColorScheme cs = _scheme(tester);

      expect(tester.takeException(), isNull);
      expect(cs.brightness, Brightness.dark);
      expect(_borderColor(tester, "Beta"), cs.primary);
      expect(_captionColor(tester, "Alpha"), cs.onSurfaceVariant);
      expect(tester.widget<Text>(find.text(_title)).style?.color, cs.onSurface);
    });

    testWidgets("asserts on an empty choice list", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls(), choices: <ThumbnailChoice<_Mode>>[]));

      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets("asserts on a thumbnail smaller than the tap target", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls(), thumbnailSize: const Size(40, 40)));

      expect(tester.takeException(), isA<AssertionError>());
    });
  });
}
