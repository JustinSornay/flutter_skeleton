// search_field_test.dart
//
// Widget tests for SearchField: search icon vs Loader, default and custom
// hint, onChanged, the listener-driven clear button (visibility, tap,
// caller-owned clearing, 48 dp target, semantics), the focus border and glow,
// reduced motion, autofocus, focus node ownership and disposal, listener
// removal on controller / focus node swaps (didUpdateWidget) and on unmount,
// the full-height tap area and a narrow layout under the light and dark
// themes.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";
import "package:flutter_skeleton/widgets/custom/SearchField/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _hintKey = "custom.search_field.hint";
const String _clearKey = "custom.search_field.clear";

Finder _inField(Finder matching) {
  return find.descendant(of: find.byType(SearchField), matching: matching);
}

Finder _clearButton() => _inField(find.byIcon(Icons.close_rounded));

AnimatedContainer _box(WidgetTester tester) {
  return tester.widget<AnimatedContainer>(_inField(find.byType(AnimatedContainer)));
}

BorderSide _borderSide(WidgetTester tester) {
  final BoxDecoration foreground = _box(tester).foregroundDecoration! as BoxDecoration;
  return (foreground.border! as Border).top;
}

List<BoxShadow> _shadows(WidgetTester tester) {
  final BoxDecoration decoration = _box(tester).decoration! as BoxDecoration;
  return decoration.boxShadow ?? const <BoxShadow>[];
}

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(SearchField))).colorScheme;
}

TextEditingController _controller([String text = ""]) {
  final TextEditingController controller = TextEditingController(text: text);
  addTearDown(controller.dispose);
  return controller;
}

FocusNode _focusNode() {
  final FocusNode node = FocusNode();
  addTearDown(node.dispose);
  return node;
}

/// Focus node that exposes whether anything still listens to it.
final class _ProbeFocusNode extends FocusNode {
  bool get listened => hasListeners;
}

_ProbeFocusNode _probeFocusNode() {
  final _ProbeFocusNode node = _ProbeFocusNode();
  addTearDown(node.dispose);
  return node;
}

/// The focus node the inner TextField uses (the internal one when the host
/// passes none).
FocusNode _fieldFocusNode(WidgetTester tester) {
  return tester.widget<TextField>(find.byType(TextField)).focusNode!;
}

void _expectDisposed(FocusNode node) {
  expect(() => ChangeNotifier.debugAssertNotDisposed(node), throwsFlutterError);
}

/// Host whose parameters a test changes through [_Host.update].
final class _Host {
  late StateSetter _setState;
  TextEditingController controller;
  FocusNode? focusNode;
  bool visible = true;

  _Host(this.controller, {this.focusNode});

  Widget build(VoidCallback onClear) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        _setState = setState;
        if (!visible) return const SizedBox.shrink();
        return SearchField(controller: controller, focusNode: focusNode, onClear: onClear);
      },
    );
  }

  Future<void> update(WidgetTester tester, VoidCallback change) async {
    _setState(change);
    await tester.pump();
  }
}

void main() {
  group("SearchField prefix and hint", () {
    testWidgets("renders a TextField with the search icon", (WidgetTester tester) async {
      await pumpApp(tester, SearchField(controller: _controller()));

      expect(_inField(find.byType(TextField)), findsOneWidget);
      expect(_inField(find.byIcon(Icons.search_rounded)), findsOneWidget);
      expect(_inField(find.byType(Loader)), findsNothing);
    });

    testWidgets("loading swaps the search icon for a 16 dp Loader", (WidgetTester tester) async {
      await pumpApp(tester, SearchField(controller: _controller(), loading: true));
      await tester.pump(const Duration(milliseconds: 100));

      expect(_inField(find.byIcon(Icons.search_rounded)), findsNothing);
      expect(_inField(find.byType(Loader)), findsOneWidget);
      expect(tester.widget<Loader>(_inField(find.byType(Loader))).size, 16);
      expect(find.bySemanticsLabel("common.loading"), findsOneWidget);
    });

    testWidgets("hint defaults to the i18n key", (WidgetTester tester) async {
      await pumpApp(tester, SearchField(controller: _controller()));

      expect(find.text(_hintKey), findsOneWidget);
    });

    testWidgets("hintText overrides the default hint", (WidgetTester tester) async {
      await pumpApp(tester, SearchField(controller: _controller(), hintText: "Find"));

      expect(find.text("Find"), findsOneWidget);
      expect(find.text(_hintKey), findsNothing);
    });
  });

  group("SearchField input", () {
    testWidgets("typing calls onChanged with the text", (WidgetTester tester) async {
      final List<String> changes = <String>[];
      await pumpApp(tester, SearchField(controller: _controller(), onChanged: changes.add));

      await tester.enterText(find.byType(TextField), "abc");

      expect(changes, <String>["abc"]);
    });

    testWidgets("the field is kMinTapTarget tall, centres the text and focuses on its whole height", (WidgetTester tester) async {
      final FocusNode node = _focusNode();
      await pumpApp(tester, SearchField(controller: _controller(), focusNode: node));

      expect(tester.getSize(_inField(find.byType(AnimatedContainer))).height, kMinTapTarget);
      expect(tester.getSize(find.byType(TextField)).height, kMinTapTarget);
      expect(
        tester.getCenter(find.byType(EditableText)).dy,
        moreOrLessEquals(tester.getCenter(find.byType(TextField)).dy, epsilon: 1),
      );

      await tester.tapAt(tester.getTopLeft(find.byType(TextField)) + const Offset(4, 2));
      await tester.pump();

      expect(node.hasFocus, isTrue);
    });

    testWidgets("keeps the height and centred text under compact density", (WidgetTester tester) async {
      await pumpApp(
        tester,
        SearchField(controller: _controller("abc"), onClear: () {}),
        theme: AppTheme.light().copyWith(visualDensity: VisualDensity.compact),
      );

      expect(tester.getSize(_inField(find.byType(AnimatedContainer))).height, kMinTapTarget);
      expect(tester.getSize(find.byType(TextField)).height, kMinTapTarget);
      expect(
        tester.getCenter(find.byType(EditableText)).dy,
        moreOrLessEquals(tester.getCenter(find.byType(TextField)).dy, epsilon: 1),
      );
      expect(tester.getSize(_inField(find.byType(InkWell))), const Size.square(kMinTapTarget));
    });
  });

  group("SearchField clear button", () {
    testWidgets("is absent without onClear, even with text", (WidgetTester tester) async {
      await pumpApp(tester, SearchField(controller: _controller("abc")));

      expect(_clearButton(), findsNothing);
    });

    testWidgets("follows the controller text when onClear is set", (WidgetTester tester) async {
      final TextEditingController controller = _controller();
      await pumpApp(tester, SearchField(controller: controller, onClear: () {}));

      expect(_clearButton(), findsNothing);

      controller.text = "abc";
      await tester.pump();
      expect(_clearButton(), findsOneWidget);

      controller.clear();
      await tester.pump();
      expect(_clearButton(), findsNothing);
    });

    testWidgets("tap calls onClear once and leaves clearing to the caller", (WidgetTester tester) async {
      final TextEditingController controller = _controller("abc");
      int clears = 0;
      await pumpApp(tester, SearchField(controller: controller, onClear: () => clears++));

      await tester.tap(_clearButton());
      await tester.pump();

      expect(clears, 1);
      expect(controller.text, "abc");
    });

    testWidgets("has a kMinTapTarget hit area and button semantics", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, SearchField(controller: _controller("abc"), onClear: () {}));

      final Size size = tester.getSize(_inField(find.byType(InkWell)));
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
      expect(
        tester.getSemantics(find.bySemanticsLabel(_clearKey)),
        isSemantics(label: _clearKey, isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });
  });

  group("SearchField focus and motion", () {
    testWidgets("focus animates the border to primary and adds a glow", (WidgetTester tester) async {
      final FocusNode node = _focusNode();
      await pumpApp(tester, SearchField(controller: _controller(), focusNode: node));
      final ColorScheme cs = _scheme(tester);

      expect(_borderSide(tester).color, cs.outlineVariant);
      expect(_borderSide(tester).width, 0.5);
      expect(_shadows(tester), isEmpty);

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(_borderSide(tester).color, cs.primary);
      expect(_borderSide(tester).width, 1);
      expect(_shadows(tester), hasLength(1));
      expect(_shadows(tester).single.color, cs.primary.withAlpha(20));

      node.unfocus();
      await tester.pump();
      expect(_borderSide(tester).color, cs.outlineVariant);
      expect(_shadows(tester), isEmpty);
    });

    testWidgets("animates over kMotionShort", (WidgetTester tester) async {
      await pumpApp(tester, SearchField(controller: _controller()));

      expect(_box(tester).duration, kMotionShort);
    });

    testWidgets("reduced motion makes the focus change instant", (WidgetTester tester) async {
      final TextEditingController controller = _controller();
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: SearchField(controller: controller),
          ),
        ),
      );

      expect(_box(tester).duration, Duration.zero);
    });

    testWidgets("autofocus gives the field focus", (WidgetTester tester) async {
      final FocusNode node = _focusNode();
      await pumpApp(tester, SearchField(controller: _controller(), focusNode: node, autofocus: true));
      await tester.pump();

      expect(node.hasFocus, isTrue);
      expect(_borderSide(tester).color, _scheme(tester).primary);
    });
  });

  group("SearchField ownership and updates", () {
    testWidgets("a caller focus node is released but not disposed on unmount", (WidgetTester tester) async {
      final _ProbeFocusNode node = _probeFocusNode();
      final _Host host = _Host(_controller(), focusNode: node);
      await pumpApp(tester, host.build(() {}));
      expect(node.listened, isTrue);

      await host.update(tester, () => host.visible = false);

      expect(find.byType(SearchField), findsNothing);
      expect(node.listened, isFalse);
      expect(() => ChangeNotifier.debugAssertNotDisposed(node), returnsNormally);
      expect(tester.takeException(), isNull);
    });

    testWidgets("an internal focus node is disposed on unmount", (WidgetTester tester) async {
      final _Host host = _Host(_controller("abc"));
      await pumpApp(tester, host.build(() {}));
      final FocusNode internal = _fieldFocusNode(tester);
      await tester.tap(find.byType(TextField));
      await tester.pump();

      await host.update(tester, () => host.visible = false);

      expect(find.byType(SearchField), findsNothing);
      _expectDisposed(internal);
      expect(tester.takeException(), isNull);
    });

    testWidgets("the controller listener is removed on unmount", (WidgetTester tester) async {
      final TextEditingController controller = _controller("abc");
      final _Host host = _Host(controller);
      await pumpApp(tester, host.build(() {}));

      await host.update(tester, () => host.visible = false);
      controller.clear();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets("a new controller moves the text listener", (WidgetTester tester) async {
      final TextEditingController first = _controller();
      final TextEditingController second = _controller("abc");
      final _Host host = _Host(first);
      await pumpApp(tester, host.build(() {}));
      expect(_clearButton(), findsNothing);

      await host.update(tester, () => host.controller = second);
      expect(_clearButton(), findsOneWidget);

      second.clear();
      await tester.pump();
      expect(_clearButton(), findsNothing);

      second.text = "abc";
      await tester.pump();
      expect(_clearButton(), findsOneWidget);

      // Once unmounted, edits to either controller must not reach the state.
      await host.update(tester, () => host.visible = false);
      second.clear();
      first.text = "x";
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets("a new focus node moves the focus listener", (WidgetTester tester) async {
      final _ProbeFocusNode external = _probeFocusNode();
      final _Host host = _Host(_controller());
      await pumpApp(tester, host.build(() {}));
      final FocusNode internal = _fieldFocusNode(tester);

      await host.update(tester, () => host.focusNode = external);
      _expectDisposed(internal);
      external.requestFocus();
      await tester.pumpAndSettle();
      expect(_borderSide(tester).color, _scheme(tester).primary);

      await host.update(tester, () => host.focusNode = null);
      expect(_borderSide(tester).color, _scheme(tester).outlineVariant);
      expect(external.listened, isFalse);
      expect(() => ChangeNotifier.debugAssertNotDisposed(external), returnsNormally);

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(_borderSide(tester).color, _scheme(tester).primary);
      expect(tester.takeException(), isNull);
    });
  });

  group("SearchField themes", () {
    for (final (String name, ThemeData Function() theme) in <(String, ThemeData Function())>[
      ("light", AppTheme.light),
      ("dark", AppTheme.dark),
    ]) {
      testWidgets("renders at 320 px without overflow ($name)", (WidgetTester tester) async {
        await pumpApp(
          tester,
          SearchField(
            controller: _controller("a long query that does not fit in a narrow field"),
            hintText: "Find",
            onClear: () {},
            loading: true,
          ),
          surfaceSize: const Size(320, 200),
          theme: theme(),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.takeException(), isNull);
        final ColorScheme cs = _scheme(tester);
        final BoxDecoration decoration = _box(tester).decoration! as BoxDecoration;
        expect(decoration.color, cs.surfaceContainerHighest);
        expect(_borderSide(tester).color, cs.outlineVariant);
        expect(tester.widget<Icon>(_clearButton()).color, cs.onSurfaceVariant);
        expect(tester.widget<TextField>(find.byType(TextField)).style?.color, cs.onSurface);
      });
    }
  });
}
