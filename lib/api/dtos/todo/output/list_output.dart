// list_output.dart
//
// Compact todo representation returned by `GET todos` (one item per row).

import "package:flutter_skeleton/api/dtos/_base/output/output_interface.dart";
import "package:flutter_skeleton/api/http/http_output.dart";

/// A todo as listed in a paginated collection.
final class TodoListOutput implements OutputInterface {
  final int id;
  final String title;
  final bool completed;

  TodoListOutput.fromOutput(HttpOutput output):
    id = output.cast<int>("id"),
    title = output.cast<String>("title"),
    completed = output.cast<bool>("completed");
}
