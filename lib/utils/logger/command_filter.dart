// command_filter.dart
//
// Log filter that allows every log event through unconditionally.
// Applied when the LOGGER_* env flags are not yet loaded (e.g. at cold-start)
// or when the developer wants full verbosity regardless of log level.
//
// The env-driven filter (configured in main.dart) replaces this once the
// .env.local file has been parsed.

import "package:logger/logger.dart";

/// Prints all logs
class CommandFilter extends LogFilter {
  /// Always returns true, so every [LogEvent] is forwarded to the printer.
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}
