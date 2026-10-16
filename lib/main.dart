// main.dart
//
// Application entry point and root widget.
//
// Responsibilities:
//   - Bootstraps async dependencies before the widget tree mounts:
//     EasyLocalization and .env.local.
//   - Registers all global providers via MultiProvider.
//   - Applies the light / dark themes (theme/app_theme.dart).
//   - Creates the GoRouter once and wraps the navigator in the Layout shell.

import "dart:ui";

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_skeleton/data/locales.dart";
import "package:flutter_skeleton/providers/connectivity_provider.dart";
import "package:flutter_skeleton/providers/error_provider.dart";
import "package:flutter_skeleton/providers/modal_provider.dart";
import "package:flutter_skeleton/routing/router/router.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/layout/layout.dart";
import "package:go_router/go_router.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:provider/provider.dart";

/// Initializes async dependencies in sequence, then launches the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  // DateFormat data for every locale: without it, intl only knows en_US and
  // any other locale throws a LocaleDataException.
  await initializeDateFormatting();
  await dotenv.load(fileName: ".env.local");

  runApp(
    EasyLocalization(
      supportedLocales: AppLocales.supported,
      path: AppLocales.path,
      fallbackLocale: AppLocales.fallback,
      child: const App(),
    ),
  );
}

/// Enables mouse drag-scrolling on Flutter Web and desktop.
///
/// By default Flutter only allows touch-based drag scrolling, so horizontal
/// lists ignore mouse drags. Trackpad is intentionally excluded: it already
/// scrolls through wheel events, and claiming it as a drag device would
/// swallow pinch / two-finger gestures.
final class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => const <PointerDeviceKind>{
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
  };
}

/// Root widget: owns the provider tree, the router and the MaterialApp.
///
/// Stateful so the [GoRouter] is created exactly once — rebuilding it on
/// every provider notification would reset navigation.
final class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

final class _AppState extends State<App> {
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<ErrorProvider>(create: (_) => ErrorProvider()),
        ChangeNotifierProvider<ConnectivityProvider>(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider<ModalProvider>(create: (_) => ModalProvider()),
      ],
      child: MaterialApp.router(
        onGenerateTitle: (BuildContext context) => "app.title".tr(),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        scrollBehavior: _AppScrollBehavior(),
        routerConfig: _router,
        builder: (BuildContext context, Widget? child) =>
            Layout(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
