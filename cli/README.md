# CLI

Code generators, run from the repository root with the Dart VM (no Flutter
runtime needed). Templates live next to each generator in `templates/` and are
rendered with `jinja`. Generators never overwrite existing files.

## Widget generator

```bash
dart cli/generation/widget/index.dart --className MyWidget [--path core/render] [--stateless]
```

| Option | Alias | Description |
|---|---|---|
| `--className` | `-c` | PascalCase widget name (required, ≥ 2 chars) |
| `--path` | `-p` | Sub-folder of `lib/widgets/` (`core/render`, `custom`, `layout`, …) |
| `--stateless` | `-l` | Generate `index.dart` + `view.dart` instead of the stateful triad |

Output: `lib/widgets/<path>/<ClassName>/{index,view_model,view}.dart`.

## Service generator

```bash
dart cli/generation/service/index.dart --className MyEntity [--route my-entities]
```

| Option | Alias | Description |
|---|---|---|
| `--className` | `-c` | PascalCase entity name (required, ≥ 2 chars) |
| `--route` | `-r` | API route, no leading slash. Defaults to the snake_case name + `s` |

Output (compiles as generated; add the real fields afterwards):

```
lib/api/services/my_entity_service.dart        get · getList · post · put · delete
lib/api/controllers/my_entity_controller.dart  load · create · update · delete (toasts, confirmation, redirect)
lib/api/dtos/my_entity/output/detail_output.dart
lib/api/dtos/my_entity/output/list_output.dart
lib/api/dtos/my_entity/input/post_input.dart
lib/api/dtos/my_entity/input/put_input.dart
```

Exit codes: 0 = created, 1 = a target file already exists, 2 = invalid class name.
