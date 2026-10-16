// future_extensions_test.dart
//
// Unit tests for FutureErrorLog.withErrorLog: values pass through, errors are
// logged with their context and rethrown unchanged.

import "package:flutter_skeleton/utils/extensions/future_extensions.dart";
import "package:flutter_test/flutter_test.dart";
import "package:logger/logger.dart";

/// Captures what Logger would print.
final class _MemoryOutput extends LogOutput {
  final List<String> lines = <String>[];

  @override
  void output(OutputEvent event) => lines.addAll(event.lines);
}

void main() {
  late _MemoryOutput output;

  setUp(() {
    output = _MemoryOutput();
    Logger.defaultOutput = () => output;
    Logger.defaultFilter = ProductionFilter.new;
  });

  tearDown(() {
    Logger.defaultOutput = ConsoleOutput.new;
    Logger.defaultFilter = DevelopmentFilter.new;
  });

  test("passes the value through without logging", () async {
    expect(await Future<int>.value(42).withErrorLog("Service.get"), 42);
    expect(output.lines, isEmpty);
  });

  test("logs the context and rethrows the same error", () async {
    final StateError error = StateError("boom");

    await expectLater(Future<int>.error(error).withErrorLog("Service.get"), throwsA(same(error)));
    expect(output.lines.join("\n"), contains("Service.get: Bad state: boom"));
  });
}
