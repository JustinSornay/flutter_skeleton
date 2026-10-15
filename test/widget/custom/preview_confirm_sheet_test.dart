// preview_confirm_sheet_test.dart
//
// Widget tests for PreviewConfirmSheet: title (header semantics, style),
// subtitle (hidden, italic), the image header (placeholder, loaded image,
// failed image, semantics), the stat pills (composed PillBadge / StatusPill,
// tone colours, delta stats and their locale-aware digits, captions, one
// semantics node each, wrapping at phone width), the confirm / cancel buttons (labels, callbacks, 48 dp, full
// width), the content-only contract (no handle, no pop), hosting in a modal
// bottom sheet and in AppModal, short heights and the dark theme.

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/providers/modal_provider.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";
import "package:flutter_skeleton/widgets/custom/PreviewConfirmSheet/index.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";
import "package:flutter_skeleton/widgets/layout/AppModal/index.dart";
import "package:flutter_skeleton/widgets/layout/ModalConsumer/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:provider/provider.dart";

import "../../helpers/widget_test_helpers.dart";

/// 1 × 1 transparent PNG.
final Uint8List _transparentPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// Image whose load always fails, synchronously and without any I/O.
final class _FailingImage extends ImageProvider<_FailingImage> {
  const _FailingImage();

  @override
  Future<_FailingImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_FailingImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(_FailingImage key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(Future<ImageInfo>.error(StateError("load failed")));
  }
}

const String _confirmKey = "custom.preview_confirm_sheet.confirm";
const String _cancelKey = "custom.preview_confirm_sheet.cancel";

void _noop() {}

Finder _inSheet(Finder matching) {
  return find.descendant(of: find.byType(PreviewConfirmSheet), matching: matching);
}

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(PreviewConfirmSheet))).colorScheme;
}

ToneColors _tone(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(tester.element(find.byType(PreviewConfirmSheet)), tone);
}

TextStyle _style(WidgetTester tester, String text) {
  return tester.widget<Text>(find.text(text)).style!;
}

/// The placeholder box (SizedBox under the ExcludeSemantics of _Placeholder).
Finder _placeholderBox() {
  return find.ancestor(
    of: find.byIcon(Icons.image_outlined),
    matching: find.byWidgetPredicate((Widget widget) => widget is SizedBox && widget.height != null),
  );
}

void main() {
  group("heading", _headingTests);
  group("image header", _imageHeaderTests);
  group("stats", _statsTests);
  group("actions", _actionsTests);
  group("hosting", _hostingTests);
  testWidgets("dark theme smoke: themed tones and text", _darkSmoke);
}

void _headingTests() {
  testWidgets("renders the title as a header in 20 / w800 onSurface", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpApp(tester, const PreviewConfirmSheet(title: "Item B", onConfirm: _noop));

    final TextStyle style = _style(tester, "Item B");
    expect(style.fontSize, 20);
    expect(style.fontWeight, FontWeight.w800);
    expect(style.color, _scheme(tester).onSurface);
    expect(
      tester.getSemantics(find.text("Item B")),
      matchesSemantics(label: "Item B", isHeader: true),
    );
    handle.dispose();
  });

  testWidgets("renders the subtitle in onSurfaceVariant, upright by default", (WidgetTester tester) async {
    await pumpApp(tester, const PreviewConfirmSheet(title: "Item B", subtitle: "Variant b", onConfirm: _noop));

    final TextStyle style = _style(tester, "Variant b");
    expect(style.fontSize, 13);
    expect(style.fontStyle, FontStyle.normal);
    expect(style.color, _scheme(tester).onSurfaceVariant);
  });

  testWidgets("draws the subtitle in italics when italicSubtitle", (WidgetTester tester) async {
    await pumpApp(
      tester,
      const PreviewConfirmSheet(title: "Item B", subtitle: "Variant b", italicSubtitle: true, onConfirm: _noop),
    );

    expect(_style(tester, "Variant b").fontStyle, FontStyle.italic);
  });

  testWidgets("hides the subtitle when it is null or empty", (WidgetTester tester) async {
    await pumpApp(tester, const PreviewConfirmSheet(title: "Item B", subtitle: "", onConfirm: _noop));
    // Title + confirm label only.
    expect(_inSheet(find.byType(Text)), findsNWidgets(2));

    await pumpApp(tester, const PreviewConfirmSheet(title: "Item B", onConfirm: _noop));
    expect(_inSheet(find.byType(Text)), findsNWidgets(2));
  });
}

void _imageHeaderTests() {
  testWidgets("without an image shows a 120 dp full-width placeholder with the icon", (WidgetTester tester) async {
    await pumpApp(tester, const PreviewConfirmSheet(title: "Item B", onConfirm: _noop), surfaceSize: const Size(400, 800));

    expect(find.byType(Image), findsNothing);
    final Icon icon = tester.widget<Icon>(find.byIcon(Icons.image_outlined));
    expect(icon.size, 48);
    expect(icon.color, _scheme(tester).onSurfaceVariant);
    expect(tester.getSize(_placeholderBox()), const Size(400, 120));
    expect(
      tester.widget<ColoredBox>(_inSheet(find.byType(ColoredBox)).first).color,
      _scheme(tester).surfaceContainerHighest,
    );
  });

  testWidgets("uses placeholderIcon", (WidgetTester tester) async {
    await pumpApp(
      tester,
      const PreviewConfirmSheet(title: "Item B", placeholderIcon: Icons.inventory_2_outlined, onConfirm: _noop),
    );

    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsNothing);
  });

  testWidgets("with an image shows it at 180 dp, full width, cover", (WidgetTester tester) async {
    await pumpApp(
      tester,
      PreviewConfirmSheet(title: "Item B", image: MemoryImage(_transparentPng), onConfirm: _noop),
      surfaceSize: const Size(400, 800),
    );

    final Image image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.cover);
    expect(tester.getSize(find.byType(Image)), const Size(400, 180));
    expect(find.byIcon(Icons.image_outlined), findsNothing);
  });

  testWidgets("an image that fails to load falls back to a 180 dp placeholder", (WidgetTester tester) async {
    await pumpApp(
      tester,
      const PreviewConfirmSheet(title: "Item B", image: _FailingImage(), onConfirm: _noop),
      surfaceSize: const Size(400, 800),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(tester.getSize(_placeholderBox().first), const Size(400, 180));
  });

  testWidgets("announces imageSemanticLabel and hides the image without it", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      PreviewConfirmSheet(
        title: "Item B",
        image: MemoryImage(_transparentPng),
        imageSemanticLabel: "Front view",
        onConfirm: _noop,
      ),
    );
    expect(find.bySemanticsLabel("Front view"), findsOneWidget);
    expect(tester.widget<Image>(find.byType(Image)).excludeFromSemantics, isFalse);

    await pumpApp(
      tester,
      PreviewConfirmSheet(title: "Item B", image: MemoryImage(_transparentPng), imageSemanticLabel: "", onConfirm: _noop),
    );
    expect(tester.widget<Image>(find.byType(Image)).excludeFromSemantics, isTrue);
    handle.dispose();
  });

  testWidgets("the placeholder is decorative", (WidgetTester tester) async {
    await pumpApp(tester, const PreviewConfirmSheet(title: "Item B", onConfirm: _noop));

    expect(
      find.ancestor(of: find.byIcon(Icons.image_outlined), matching: find.byType(ExcludeSemantics)),
      findsWidgets,
    );
  });
}

void _statsTests() {
  testWidgets("renders each label above its value pill", (WidgetTester tester) async {
    await pumpApp(
      tester,
      const PreviewConfirmSheet(
        title: "Item B",
        stats: <PreviewStat>[
          PreviewStat(label: "Now", value: "0.72"),
          PreviewStat(label: "Later", value: "0.85"),
        ],
        onConfirm: _noop,
      ),
    );

    expect(find.text("Now"), findsOneWidget);
    expect(find.text("0.72"), findsOneWidget);
    expect(find.text("Later"), findsOneWidget);
    expect(find.text("0.85"), findsOneWidget);
    expect(tester.getBottomLeft(find.text("Now")).dy, lessThan(tester.getTopLeft(find.text("0.72")).dy));
    expect(tester.getTopLeft(find.text("Now")).dy, tester.getTopLeft(find.text("Later")).dy);

    final TextStyle label = _style(tester, "Now");
    expect(label.fontWeight, FontWeight.w700);
    expect(label.color, _scheme(tester).onSurfaceVariant);
  });

  testWidgets("an untoned stat is an outlined PillBadge without a dot", (WidgetTester tester) async {
    await pumpApp(
      tester,
      const PreviewConfirmSheet(
        title: "Item B",
        stats: <PreviewStat>[PreviewStat(label: "Now", value: "0.72")],
        onConfirm: _noop,
      ),
    );

    final PillBadge pill = tester.widget<PillBadge>(find.byType(PillBadge));
    expect(pill.label, "0.72");
    expect(pill.outlined, isTrue);
    expect(pill.icon, isNull);
    expect(pill.tone, StatusTone.neutral);
    expect(find.byType(StatusPill), findsNothing);
  });

  testWidgets("a toned stat is an outlined PillBadge with a dot in the tone foreground", (WidgetTester tester) async {
    await pumpApp(
      tester,
      const PreviewConfirmSheet(
        title: "Item B",
        stats: <PreviewStat>[PreviewStat(label: "Now", value: "0.72", tone: StatusTone.warning)],
        onConfirm: _noop,
      ),
    );

    final PillBadge pill = tester.widget<PillBadge>(find.byType(PillBadge));
    expect(pill.outlined, isTrue);
    expect(pill.tone, StatusTone.warning);
    expect(pill.icon, Icons.fiber_manual_record);
    final Color foreground = _tone(tester, StatusTone.warning).foreground;
    expect(tester.widget<Icon>(find.byIcon(Icons.fiber_manual_record)).color, foreground);
    expect(_style(tester, "0.72").color, foreground);
  });

  testWidgets("a tinted stat is a StatusPill with the tone icon, text in onContainer", (WidgetTester tester) async {
    await pumpApp(
      tester,
      const PreviewConfirmSheet(
        title: "Item B",
        stats: <PreviewStat>[PreviewStat(label: "Change", value: "+0.13", tone: StatusTone.success, tinted: true)],
        onConfirm: _noop,
      ),
    );

    final StatusPill pill = tester.widget<StatusPill>(find.byType(StatusPill));
    expect(pill.label, "+0.13");
    expect(pill.tone, StatusTone.success);
    expect(pill.icon, StatusTone.success.icon);
    final ToneColors colors = _tone(tester, StatusTone.success);
    expect(_style(tester, "+0.13").color, colors.onContainer);
    expect(tester.widget<PillBadge>(find.byType(PillBadge)).backgroundColor, colors.container);
  });

  testWidgets("a tinted stat without a tone is a neutral StatusPill", (WidgetTester tester) async {
    await pumpApp(
      tester,
      const PreviewConfirmSheet(
        title: "Item B",
        stats: <PreviewStat>[PreviewStat(label: "Change", value: "1", tinted: true)],
        onConfirm: _noop,
      ),
    );

    final StatusPill pill = tester.widget<StatusPill>(find.byType(StatusPill));
    expect(pill.tone, StatusTone.neutral);
    // Neutral carries no status, so no glyph.
    expect(pill.icon, isNull);
    expect(find.byIcon(StatusTone.neutral.icon), findsNothing);
  });

  testWidgets("delta stats render as tinted pills", (WidgetTester tester) async {
    await pumpApp(
      tester,
      PreviewConfirmSheet(
        title: "Item B",
        stats: <PreviewStat>[
          PreviewStat.delta(label: "Up", delta: 0.13),
          PreviewStat.delta(label: "Down", delta: -0.05),
          PreviewStat.delta(label: "Flat", delta: 0.001),
        ],
        onConfirm: _noop,
      ),
    );

    final List<StatusPill> pills = tester.widgetList<StatusPill>(find.byType(StatusPill)).toList();
    expect(pills.map((StatusPill pill) => pill.label), <String>["+0.13", "-0.05", "="]);
    expect(
      pills.map((StatusPill pill) => pill.tone),
      <StatusTone>[StatusTone.success, StatusTone.danger, StatusTone.neutral],
    );
    // "=" shows no minus-like neutral glyph.
    expect(
      pills.map((StatusPill pill) => pill.icon),
      <IconData?>[StatusTone.success.icon, StatusTone.danger.icon, null],
    );
    expect(find.byIcon(StatusTone.neutral.icon), findsNothing);
  });

  testWidgets("delta stats format their digits for the ambient locale", _deltaLocaleTest);

  testWidgets("a caption is shown after the value and announced with it", _captionTest);

  testWidgets("each stat is one semantics node: 'label: value' or semanticsLabel", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      const PreviewConfirmSheet(
        title: "Item B",
        stats: <PreviewStat>[
          PreviewStat(label: "Now", value: "0.72", tone: StatusTone.success),
          PreviewStat(label: "Change", value: "+0.13", tinted: true, semanticsLabel: "Change up 0.13, good"),
          PreviewStat(label: "Later", value: "0.85", semanticsLabel: ""),
        ],
        onConfirm: _noop,
      ),
    );

    expect(find.bySemanticsLabel("Now: 0.72"), findsOneWidget);
    expect(find.bySemanticsLabel("Change up 0.13, good"), findsOneWidget);
    expect(find.bySemanticsLabel("Later: 0.85"), findsOneWidget);
    // The caption and the pill are not announced a second time.
    expect(find.bySemanticsLabel("Now"), findsNothing);
    expect(find.bySemanticsLabel("0.72"), findsNothing);
    expect(find.bySemanticsLabel("+0.13"), findsNothing);
    handle.dispose();
  });

  testWidgets("no stats renders no Wrap", (WidgetTester tester) async {
    await pumpApp(tester, const PreviewConfirmSheet(title: "Item B", onConfirm: _noop));

    expect(find.byType(Wrap), findsNothing);
  });

  testWidgets("long stats wrap onto several runs at phone width without overflow", (WidgetTester tester) async {
    await pumpApp(
      tester,
      PreviewConfirmSheet(
        title: "Item B",
        stats: <PreviewStat>[
          const PreviewStat(label: "First long caption for this stat", value: "0.72", tone: StatusTone.success),
          const PreviewStat(label: "Second long caption for this stat", value: "0.85", tone: StatusTone.info),
          PreviewStat.delta(label: "Third long caption for this stat", delta: 0.13),
          const PreviewStat(
            label: "A caption that is much longer than the available width of the sheet on a phone",
            value: "A value that is also much longer than the available width of the sheet on a phone",
          ),
        ],
        onConfirm: _noop,
      ),
      surfaceSize: const Size(360, 800),
    );

    expect(tester.takeException(), isNull);
    final double firstTop = tester.getTopLeft(find.text("First long caption for this stat")).dy;
    final double thirdTop = tester.getTopLeft(find.text("Third long caption for this stat")).dy;
    expect(thirdTop, greaterThan(firstTop));
    expect(tester.getTopRight(find.byType(Wrap)).dx, lessThanOrEqualTo(360 - kDefaultPadding * 3));
  });
}

void _actionsTests() {
  testWidgets("confirm shows the default key and calls onConfirm once per tap", (WidgetTester tester) async {
    int taps = 0;
    await pumpApp(tester, PreviewConfirmSheet(title: "Item B", onConfirm: () => taps++));

    expect(find.widgetWithText(FilledButton, _confirmKey), findsOneWidget);
    expect(_style(tester, _confirmKey).fontWeight, FontWeight.w700);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(taps, 1);
    // Content only: the sheet never closes itself.
    expect(find.byType(PreviewConfirmSheet), findsOneWidget);
  });

  testWidgets("confirmLabel replaces the default; an empty one falls back", (WidgetTester tester) async {
    await pumpApp(tester, const PreviewConfirmSheet(title: "Item B", confirmLabel: "Use this one", onConfirm: _noop));
    expect(find.widgetWithText(FilledButton, "Use this one"), findsOneWidget);
    expect(find.text(_confirmKey), findsNothing);

    await pumpApp(tester, const PreviewConfirmSheet(title: "Item B", confirmLabel: "", onConfirm: _noop));
    expect(find.widgetWithText(FilledButton, _confirmKey), findsOneWidget);
  });

  testWidgets("no cancel button without onCancel", (WidgetTester tester) async {
    await pumpApp(tester, const PreviewConfirmSheet(title: "Item B", cancelLabel: "Back", onConfirm: _noop));

    expect(find.byType(TextButton), findsNothing);
    expect(find.text("Back"), findsNothing);
    expect(find.text(_cancelKey), findsNothing);
  });

  testWidgets("cancel shows the default key and calls onCancel once per tap", (WidgetTester tester) async {
    int cancels = 0;
    int confirms = 0;
    await pumpApp(
      tester,
      PreviewConfirmSheet(title: "Item B", onConfirm: () => confirms++, onCancel: () => cancels++),
    );

    expect(find.widgetWithText(TextButton, _cancelKey), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(TextButton)).dy,
      greaterThan(tester.getBottomLeft(find.byType(FilledButton)).dy),
    );
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    expect(cancels, 1);
    expect(confirms, 0);
  });

  testWidgets("cancelLabel replaces the default; an empty one falls back", (WidgetTester tester) async {
    await pumpApp(
      tester,
      const PreviewConfirmSheet(title: "Item B", cancelLabel: "Back", onConfirm: _noop, onCancel: _noop),
    );
    expect(find.widgetWithText(TextButton, "Back"), findsOneWidget);

    await pumpApp(
      tester,
      const PreviewConfirmSheet(title: "Item B", cancelLabel: "", onConfirm: _noop, onCancel: _noop),
    );
    expect(find.widgetWithText(TextButton, _cancelKey), findsOneWidget);
  });

  testWidgets("both buttons are at least 48 dp tall and span the content width", (WidgetTester tester) async {
    await pumpApp(
      tester,
      const PreviewConfirmSheet(title: "Item B", onConfirm: _noop, onCancel: _noop),
      surfaceSize: const Size(400, 800),
    );

    const double contentWidth = 400 - kDefaultPadding * 6;
    for (final Finder button in <Finder>[find.byType(FilledButton), find.byType(TextButton)]) {
      final Size size = tester.getSize(button);
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.width, contentWidth);
    }
  });

  testWidgets("buttons expose button semantics with their label", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpApp(tester, const PreviewConfirmSheet(title: "Item B", onConfirm: _noop, onCancel: _noop));

    for (final String label in <String>[_confirmKey, _cancelKey]) {
      expect(
        tester.getSemantics(find.text(label)),
        matchesSemantics(
          label: label,
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
    }
    handle.dispose();
  });
}

void _hostingTests() {
  testWidgets("draws no drag handle and no background of its own", (WidgetTester tester) async {
    await pumpApp(tester, const PreviewConfirmSheet(title: "Item B", onConfirm: _noop));

    // Nothing above the image header.
    expect(tester.getTopLeft(_placeholderBox()), tester.getTopLeft(find.byType(PreviewConfirmSheet)));
    // The only coloured box is the image placeholder.
    expect(_inSheet(find.byType(ColoredBox)), findsOneWidget);
    expect(find.ancestor(of: find.byType(ColoredBox), matching: find.byType(ExcludeSemantics)), findsWidgets);
  });

  testWidgets("in a modal bottom sheet, the host closes it from onConfirm", (WidgetTester tester) async {
    int confirms = 0;
    await pumpApp(
      tester,
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (BuildContext sheetContext) => PreviewConfirmSheet(
              title: "Item B",
              stats: const <PreviewStat>[PreviewStat(label: "Now", value: "0.72")],
              onConfirm: () {
                confirms++;
                Navigator.of(sheetContext).pop();
              },
            ),
          ),
          child: const Text("open"),
        ),
      ),
    );

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    expect(find.byType(PreviewConfirmSheet), findsOneWidget);
    expect(tester.widget<BottomSheet>(find.byType(BottomSheet)).showDragHandle, isTrue);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(confirms, 1);
    expect(find.byType(PreviewConfirmSheet), findsNothing);
  });

  testWidgets("in a modal bottom sheet, a confirm that does not close keeps it open", (WidgetTester tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (BuildContext context) => TextButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext sheetContext) => const PreviewConfirmSheet(title: "Item B", onConfirm: _noop),
          ),
          child: const Text("open"),
        ),
      ),
    );

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.byType(PreviewConfirmSheet), findsOneWidget);
  });

  testWidgets("in AppModal through ModalProvider, onConfirm dismisses the modal", (WidgetTester tester) async {
    int confirms = 0;
    await pumpApp(
      tester,
      // Like the shell: the page under ModalConsumer fills the screen.
      ModalConsumer(
        child: SizedBox.expand(
          child: Builder(
            builder: (BuildContext context) => Center(
              child: TextButton(
                onPressed: () {
                  final ModalProvider modal = context.read<ModalProvider>();
                  modal.show(
                    AppModal(
                      isVisible: true,
                      onDismiss: modal.dismiss,
                      child: PreviewConfirmSheet(
                        title: "Item B",
                        onConfirm: () {
                          confirms++;
                          modal.dismiss();
                        },
                        onCancel: modal.dismiss,
                      ),
                    ),
                  );
                },
                child: const Text("open"),
              ),
            ),
          ),
        ),
      ),
      providers: defaultTestProviders(),
    );

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    expect(find.byType(PreviewConfirmSheet), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(confirms, 1);
    expect(find.byType(PreviewConfirmSheet), findsNothing);
  });

  testWidgets("needs no Material ancestor: the buttons bring their own", (WidgetTester tester) async {
    int taps = 0;
    // Not pumpApp: its Scaffold would provide a Material.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: PreviewConfirmSheet(
          title: "Item B",
          stats: const <PreviewStat>[PreviewStat(label: "Now", value: "0.72", tone: StatusTone.success)],
          onConfirm: () => taps++,
        ),
      ),
    );
    expect(find.ancestor(of: find.byType(PreviewConfirmSheet), matching: find.byType(Material)), findsNothing);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(taps, 1);
  });

  testWidgets("scrolls instead of overflowing in a short host", (WidgetTester tester) async {
    await pumpApp(
      tester,
      SizedBox(
        height: 200,
        child: PreviewConfirmSheet(
          title: "Item B",
          subtitle: "Variant b",
          image: MemoryImage(_transparentPng),
          stats: const <PreviewStat>[PreviewStat(label: "Now", value: "0.72")],
          onConfirm: _noop,
          onCancel: _noop,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(_inSheet(find.byType(SingleChildScrollView)), findsOneWidget);
    await tester.drag(find.byType(PreviewConfirmSheet), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _deltaLocaleTest(WidgetTester tester) async {
  final SemanticsHandle handle = tester.ensureSemantics();
  await pumpApp(
    tester,
    Builder(
      builder: (BuildContext context) => Localizations.override(
        context: context,
        locale: const Locale("fr"),
        child: PreviewConfirmSheet(
          title: "Item B",
          stats: <PreviewStat>[
            PreviewStat.delta(label: "Up", delta: 0.05),
            PreviewStat.delta(label: "Down", delta: -0.05, caption: "Worse"),
            PreviewStat.delta(label: "Flat", delta: 0.001),
            PreviewStat.delta(label: "Whole", delta: 3, fractionDigits: 0),
            PreviewStat.delta(label: "Large", delta: 1234.5),
          ],
          onConfirm: _noop,
        ),
      ),
    ),
  );

  expect(tester.takeException(), isNull);
  // Decimal comma and French grouping (narrow no-break space), explicit "+".
  expect(
    tester.widgetList<StatusPill>(find.byType(StatusPill)).map((StatusPill pill) => pill.label),
    <String>["+0,05", "-0,05 · Worse", "=", "+3", "+1\u202F234,50"],
  );
  expect(find.bySemanticsLabel("Up: +0,05"), findsOneWidget);
  expect(find.bySemanticsLabel("Down: -0,05, Worse"), findsOneWidget);
  expect(find.bySemanticsLabel("Flat: ="), findsOneWidget);
  handle.dispose();
}

Future<void> _captionTest(WidgetTester tester) async {
  final SemanticsHandle handle = tester.ensureSemantics();
  await pumpApp(
    tester,
    PreviewConfirmSheet(
      title: "Item B",
      stats: <PreviewStat>[
        const PreviewStat(label: "A", value: "1", tone: StatusTone.success, caption: "Good"),
        const PreviewStat(label: "B", value: "1", tone: StatusTone.danger, caption: "Bad"),
        PreviewStat.delta(label: "C", delta: 0.05, higherIsBetter: false, caption: "Worse"),
        const PreviewStat(label: "D", value: "2", tone: StatusTone.info, caption: "Info", semanticsLabel: "Custom D"),
        const PreviewStat(label: "E", value: "3", caption: ""),
      ],
      onConfirm: _noop,
    ),
  );

  // Visible: the same value with a different tone reads differently.
  expect(find.text("1 · Good"), findsOneWidget);
  expect(find.text("1 · Bad"), findsOneWidget);
  expect(find.text("+0.05 · Worse"), findsOneWidget);
  expect(find.text("2 · Info"), findsOneWidget);
  expect(find.text("3"), findsOneWidget);
  // Announced: the caption is appended unless semanticsLabel replaces it all.
  expect(find.bySemanticsLabel("A: 1, Good"), findsOneWidget);
  expect(find.bySemanticsLabel("B: 1, Bad"), findsOneWidget);
  expect(find.bySemanticsLabel("C: +0.05, Worse"), findsOneWidget);
  expect(find.bySemanticsLabel("Custom D"), findsOneWidget);
  expect(find.bySemanticsLabel("E: 3"), findsOneWidget);
  handle.dispose();
}

Future<void> _darkSmoke(WidgetTester tester) async {
  await pumpApp(
    tester,
    PreviewConfirmSheet(
      title: "Item B",
      subtitle: "Variant b",
      stats: <PreviewStat>[
        const PreviewStat(label: "Now", value: "0.72", tone: StatusTone.warning),
        PreviewStat.delta(label: "Change", delta: -0.05),
      ],
      onConfirm: _noop,
      onCancel: _noop,
    ),
    theme: AppTheme.dark(),
  );

  expect(tester.takeException(), isNull);
  final ColorScheme dark = AppTheme.dark().colorScheme;
  final StatusTones tones = StatusTones.fromScheme(dark);
  expect(_style(tester, "Item B").color, dark.onSurface);
  expect(_style(tester, "0.72").color, tones.warning.foreground);
  expect(_style(tester, "-0.05").color, tones.danger.onContainer);
}
