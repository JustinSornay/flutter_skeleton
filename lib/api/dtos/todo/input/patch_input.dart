// patch_input.dart
//
// Partial update body sent to `PATCH todos/:id`.

import "package:flutter_skeleton/api/dtos/_base/input/abstract_input.dart";

/// Partial todo update. Only non-null fields are serialized so the backend
/// leaves the others untouched.
final class TodoPatchInput extends AbstractInput {
  final String? title;
  final bool? completed;

  const TodoPatchInput({
    this.title,
    this.completed,
  });

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (title != null) "title": title,
      if (completed != null) "completed": completed,
    };
  }
}
