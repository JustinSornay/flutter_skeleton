// flutter_test_config.dart
//
// Global test configuration hook, executed by the Flutter test runner before
// every test file under test/.

import "dart:async";

import "package:easy_localization/easy_localization.dart";

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Widget tests that do not mount EasyLocalization render raw translation
  // keys ("todos.title"); silence the "key not found" warnings they trigger.
  EasyLocalization.logger.enableBuildModes = [];
  await testMain();
}
