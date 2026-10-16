// future_extensions.dart
//
// Extension on Future<T> for the service-layer error log: the shorthand for
// `try { … } catch (e) { Logger().e("Service.method: $e"); rethrow; }`.

import "package:logger/logger.dart";

/// Error logging on any future.
extension FutureErrorLog<T> on Future<T> {
  /// Logs `"<context>: <error>"` (context format: `"ClassName.method"`), then
  /// rethrows the same error with its stack trace. The value passes through.
  ///
  /// ```dart
  /// static Future<EntityDetailOutput> get(int id) => (() async {
  ///   return EntityDetailOutput.fromOutput(await Http.output(…));
  /// })().withErrorLog("EntityService.get");
  /// ```
  Future<T> withErrorLog(String context) async {
    try {
      return await this;
    } catch (e) {
      Logger().e("$context: $e");
      rethrow;
    }
  }
}
