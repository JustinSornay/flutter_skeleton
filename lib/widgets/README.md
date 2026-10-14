# widgets/

| Folder | Content |
|---|---|
| `core/render/` | Page / section-level MVVM components (own state, call services) |
| `core/decorators/` | Content-agnostic wrappers (animation, styling) |
| `custom/` | Generic reusable widgets driven by parameters |
| `layout/` | App shell: header, banners, toasts, modals |
| `constants.dart` | Spacing grid, content width, motion durations, `resolveMotion()` |

Every widget lives in its own PascalCase folder and is split across files with
`part` / `part of`. **Never put UI and logic in the same file.** Generate the
boilerplate with:

```bash
dart cli/generation/widget/index.dart --className MyWidget --path core/render
dart cli/generation/widget/index.dart --className MyBadge --path custom --stateless
```

## Widget declaration

### StatefulWidget

*index.dart*
```dart
import "package:flutter/material.dart";

part "view_model.dart";
part "view.dart";

final class Example extends StatefulWidget {
  const Example({
    super.key
  });

  @override
  State<Example> createState() => _ExampleState();
}
```

*view_model.dart*
```dart
part of "index.dart";

final class _ExampleState extends State<Example> with _ViewMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}
```

*view.dart*
```dart
part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, _ExampleState state) {
    return const SizedBox.shrink();
  }
}
```

### StatelessWidget

*index.dart*
```dart
import "package:flutter/material.dart";

part "view.dart";

final class Example extends StatelessWidget with _ViewMixin {
  const Example({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}
```

*view.dart*
```dart
part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, Example widget) {
    return const SizedBox.shrink();
  }
}
```
