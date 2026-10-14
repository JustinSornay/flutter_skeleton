// output_interface.dart
//
// Contract that every response DTO must satisfy. The named constructor
// pattern enforces a consistent deserialization signature so services can
// pass HttpOutput instances to any DTO without knowing the concrete type.

import "package:flutter_skeleton/api/http/http_output.dart";

/// Marks a class as deserializable from an [HttpOutput].
///
/// Every concrete DTO output class must provide a
/// `ClassName.fromOutput(HttpOutput output)` named constructor. This
/// constructor is called by services after `Http.output` or `Http.listOutput`
/// returns the raw wrapper, keeping deserialization logic inside the DTO
/// and out of the service layer.
abstract interface class OutputInterface {
  OutputInterface.fromOutput(HttpOutput output);
}
