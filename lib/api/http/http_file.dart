// http_file.dart
//
// One file part of a multipart/form-data upload sent with Http.multipart.
//
// Holds the raw bytes rather than a package:http MultipartFile: a MultipartFile
// can be sent only once (sending finalizes it), so Http builds a fresh part
// from these bytes for every attempt — the 401 refresh-and-retry re-sends the
// same files. It also keeps services free of any package:http import.
//
// Relationships:
//   - Consumed by Http.multipart (api/http/http.dart)

/// A file sent as one part of a multipart/form-data request.
///
/// [field] is the form field name the server reads the file from, [filename]
/// the name announced in the part's `Content-Disposition` (servers commonly
/// treat a part without filename as a plain text field, hence required).
/// The part is sent as `application/octet-stream`.
final class HttpFile {
  final String field;
  final List<int> bytes;
  final String filename;

  const HttpFile({
    required this.field,
    required this.bytes,
    required this.filename,
  });
}
