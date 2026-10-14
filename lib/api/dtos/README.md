# api/dtos/

Data Transfer Objects — the typed shape of every request body and response
payload. One DTO = one file, grouped by entity:

```
<entity>/
  output/
    detail_output.dart   # GET <entities>/:id
    list_output.dart     # GET <entities> (one item)
  input/
    post_input.dart      # POST <entities>
    put_input.dart       # PUT <entities>/:id
```

## Outputs

- Implement `OutputInterface` and expose `.fromOutput(HttpOutput output)` as
  their **only** constructor (no `const` constructor, no `fromJson`).
- Read fields with `output.cast<T>("key")`, nested objects with
  `output.output("key")`, nested lists with `output.outputList("key")` —
  never read `output.json` directly for typed fields.
- Nested sub-DTOs follow the same rules.

```dart
final class EntityDetailOutput implements OutputInterface {
  final int id;
  final String label;
  final bool? optional;
  final List<SubEntityListOutput> subEntities;
  final ParentEntityDetailOutput parentEntity;

  EntityDetailOutput.fromOutput(HttpOutput output):
    id = output.cast<int>("id"),
    label = output.cast<String>("label"),
    optional = output.cast<bool?>("optional"),
    subEntities = output.outputList("sub_entities").map(SubEntityListOutput.fromOutput).toList(),
    parentEntity = ParentEntityDetailOutput.fromOutput(output.output("parent_entity"));
}
```

`cast<T>` is strict: a missing key or a wrong type throws an `AssertionError`
(and logs it when `LOGGER_ERROR=true`). Nullable types accept an explicit JSON
`null`, but the key must still be present.

## Inputs

Extend `AbstractInput` and implement `toJson()`. Omit unset optional fields so
the backend can tell "not provided" from "explicitly null".

```dart
final class EntityPostInput extends AbstractInput {
  final String label;
  final bool? optional;

  const EntityPostInput({
    required this.label,
    this.optional,
  });

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "label": label,
      if (optional != null) "optional": optional,
    };
  }
}
```

Generate a full entity (service + 4 DTOs) with:

```bash
dart cli/generation/service/index.dart --className MyEntity
```
