// file_path_builder.dart
//
// Fluent builder for constructing file system paths from segments.
// Handles platform-specific separators via dart:io and the path package.
//
// Typical use: build export or cache file paths without manually
// concatenating separators. Start from the current package root with
// FilePathBuilder.currentPackage(), then call addSegment() or concat()
// before calling build().

import "dart:io";
import "package:path/path.dart" as path_package;

/// Builds a file system path incrementally from named segments or sub-paths.
///
/// Uses [Platform.pathSeparator] so the result is correct on every target
/// platform (Windows backslash vs. POSIX forward slash).
final class FilePathBuilder {
  final List<String> _segmentList = [];

  /// Creates an empty builder. Call [addSegment] or [concat] to populate it.
  FilePathBuilder();

  /// Creates a builder pre-seeded with the current package's working directory.
  FilePathBuilder.currentPackage() {
    concat(path_package.current);
  }

  /// Creates a builder pre-seeded with [path].
  ///
  /// [path] must not start or end with a path separator — use [concat] for
  /// multi-segment strings and [addSegment] for individual names.
  FilePathBuilder.fromOrigin(String path) {
    concat(path);
  }

  /// Merges all segments from [builder] into this builder.
  ///
  /// Useful for composing two independently constructed sub-paths.
  void operator +(FilePathBuilder builder) {
    _segmentList.addAll(builder._segmentList);
  }

  /// Appends a single path component (file or directory name).
  ///
  /// [segment] must not contain a path separator — it is a leaf name only,
  /// e.g. `"exports"` or `"report.pdf"`.
  void addSegment(String segment) {
    assert(!segment.contains(Platform.pathSeparator));
    _segmentList.add(segment);
  }

  /// Splits [path] on the platform separator and appends all resulting parts.
  ///
  /// [path] must not start or end with a separator. Use this to absorb a
  /// known sub-path such as `"data/exports"` in one call.
  void concat(String path) {
    assert(!path.startsWith(Platform.pathSeparator) && !path.endsWith(Platform.pathSeparator));
    _segmentList.addAll(path.split(Platform.pathSeparator));
  }

  /// Joins all accumulated segments with the platform separator and returns
  /// the resulting path string.
  String build() {
    return _segmentList.join(Platform.pathSeparator);
  }

  @override
  String toString() {
    return build();
  }
}
