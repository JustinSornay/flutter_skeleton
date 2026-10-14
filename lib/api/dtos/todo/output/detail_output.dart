// detail_output.dart
//
// Full todo representation returned by `GET todos/:id` and `PATCH todos/:id`.

import "package:flutter_skeleton/api/dtos/_base/output/output_interface.dart";
import "package:flutter_skeleton/api/http/http_output.dart";

/// A single todo with all its fields.
final class TodoDetailOutput implements OutputInterface {
  final int id;
  final int userId;
  final String title;
  final bool completed;

  TodoDetailOutput.fromOutput(HttpOutput output):
    id = output.cast<int>("id"),
    userId = output.cast<int>("userId"),
    title = output.cast<String>("title"),
    completed = output.cast<bool>("completed");
}
