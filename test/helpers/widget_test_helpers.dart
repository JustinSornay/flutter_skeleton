// widget_test_helpers.dart
//
// Shared utilities for widget tests: the real app theme, pump helpers with
// optional providers, a minimal router, and a fully localized app shell.
//
// Without EasyLocalization in the tree, `"key".tr()` returns the key itself —
// enough for structure assertions. Use [pumpLocalizedRouter] when a widget
// reads `context.locale` or when real translated strings matter.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/data/locales.dart";
import "package:flutter_skeleton/providers/connectivity_provider.dart";
import "package:flutter_skeleton/providers/error_provider.dart";
import "package:flutter_skeleton/providers/modal_provider.dart";
import "package:flutter_skeleton/routing/router/router.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/layout/layout.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:nested/nested.dart";
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";

/// Global providers with test-safe defaults (no platform channels).
List<SingleChildWidget> defaultTestProviders({bool offline = false}) {
  return <SingleChildWidget>[
    ChangeNotifierProvider<ErrorProvider>(create: (_) => ErrorProvider()),
    ChangeNotifierProvider<ConnectivityProvider>(
      create: (_) => ConnectivityProvider.withState(offline: offline),
    ),
    ChangeNotifierProvider<ModalProvider>(create: (_) => ModalProvider()),
  ];
}

void _setSurfaceSize(WidgetTester tester, Size? size) {
  if (size == null) return;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Wraps [child] in a themed MaterialApp + Scaffold, with optional providers.
///
/// [theme] defaults to [AppTheme.light]; pass [AppTheme.dark] for the dark
/// smoke test of tone-aware widgets.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<SingleChildWidget> providers = const <SingleChildWidget>[],
  Size? surfaceSize,
  ThemeData? theme,
}) async {
  _setSurfaceSize(tester, surfaceSize);
  final Widget body = providers.isEmpty
      ? child
      : MultiProvider(providers: providers, child: child);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light(),
      home: Scaffold(body: body),
    ),
  );
}

/// Pumps [child] at `/` inside a minimal GoRouter so widgets that call
/// `context.go()` work. [extraRoutes] lets a test observe navigation targets.
Future<void> pumpWithRouter(
  WidgetTester tester,
  Widget child, {
  List<RouteBase> extraRoutes = const <RouteBase>[],
  List<SingleChildWidget> providers = const <SingleChildWidget>[],
}) async {
  final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(path: "/", builder: (_, _) => Scaffold(body: child)),
      ...extraRoutes,
    ],
  );
  addTearDown(router.dispose);

  final Widget app = MaterialApp.router(theme: AppTheme.light(), routerConfig: router);
  await tester.pumpWidget(
    providers.isEmpty ? app : MultiProvider(providers: providers, child: app),
  );
  await tester.pumpAndSettle();
}

/// Pumps the real application shell (EasyLocalization + providers + router +
/// Layout) at [initialLocation], with translations loaded from assets.
Future<GoRouter> pumpLocalizedRouter(
  WidgetTester tester, {
  String initialLocation = "/",
  Locale locale = AppLocales.fallback,
  List<SingleChildWidget>? providers,
  Size? surfaceSize,
}) async {
  _setSurfaceSize(tester, surfaceSize);
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting();

  final GoRouter router = createRouter(initialLocation: initialLocation);
  addTearDown(router.dispose);

  // Translation assets are read with real I/O, which the fake-async test zone
  // never completes on its own.
  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: AppLocales.supported,
        path: AppLocales.path,
        fallbackLocale: AppLocales.fallback,
        startLocale: locale,
        saveLocale: false,
        child: MultiProvider(
          providers: providers ?? defaultTestProviders(),
          child: Builder(
            builder: (BuildContext context) => MaterialApp.router(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              theme: AppTheme.light(),
              routerConfig: router,
              builder: (BuildContext context, Widget? child) =>
                  Layout(child: child ?? const SizedBox.shrink()),
            ),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pumpAndSettle();
  return router;
}
