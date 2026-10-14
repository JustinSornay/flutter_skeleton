# api/services/

One class per entity (`TodoService`, …). All methods are `static Future<T>` and
go through `Http` — never through the `http` package directly.

Rules:

- Use `Http.output`, `Http.listOutput`, `Http.input`, `Http.request` or
  `Http.listen`. Routes have no leading `/`.
- Wrap every body in `try { … } catch (e) { Logger().e("Service.method: $e"); rethrow; }`.
  Every catch block is an observability checkpoint — a bare rethrow is incomplete.
- Pass an `ApiFilterBuilder` as `queryBuilder` for filtered / paginated lists.
- Errors 400+ surface as `ApiException(status, detail)`.

```dart
final class EntityService {
  static Future<EntityDetailOutput> get(int id) async {
    try {
      return EntityDetailOutput.fromOutput(await Http.output(
        api: HttpApiEnum.api,
        route: "entities/$id",
      ));
    } catch (e) {
      Logger().e("EntityService.get: $e");
      rethrow;
    }
  }

  static Future<List<EntityListOutput>> getList([ApiFilterBuilder? apiFilterBuilder]) async {
    try {
      final List<HttpOutput> result = await Http.listOutput(
        api: HttpApiEnum.api,
        route: "entities",
        queryBuilder: apiFilterBuilder,
      );
      return result.map(EntityListOutput.fromOutput).toList();
    } catch (e) {
      Logger().e("EntityService.getList: $e");
      rethrow;
    }
  }

  static Future<void> delete(int id) async {
    try {
      await Http.request(
        method: HttpMethodEnum.delete,
        api: HttpApiEnum.api,
        route: "entities/$id",
      );
    } catch (e) {
      Logger().e("EntityService.delete: $e");
      rethrow;
    }
  }
}
```

Static methods are not mockable: widgets and providers receive them through
optional function parameters (injectable seam pattern, see `CLAUDE.md`).
