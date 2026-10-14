// input_interface.dart
//
// Contract that every request body DTO must satisfy. Implementing this
// interface guarantees that Http.input can serialize the body to JSON without
// knowing the concrete DTO type.

/// Marks a class as a serializable HTTP request body.
///
/// Implementors must convert their fields into a [Map<String, dynamic>] that
/// can be passed directly to `jsonEncode`. Only include fields that are set —
/// omit null-optional fields entirely so the backend can distinguish "not
/// provided" from "explicitly null".
abstract interface class InputInterface {
  Map<String, dynamic> toJson();
}
