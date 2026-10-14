// abstract_input.dart
//
// Base class for all request body DTOs. Extend this instead of implementing
// InputInterface directly — it provides a useful toString() for debug logging
// without requiring each subclass to write its own.

import "package:flutter_skeleton/api/dtos/_base/input/input_interface.dart";

/// Shared base for HTTP request body DTOs.
///
/// Subclasses must override [toJson] to return only the fields they want
/// to send. The [toString] override delegates to [toJson] so the payload
/// appears in debug logs automatically.
abstract class AbstractInput implements InputInterface {
  const AbstractInput();

  @override
  String toString() {
    return toJson().toString();
  }
}
