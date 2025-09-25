# Rules:
- Use dependency injection for clients/services.
- Always annotate constructor parameters with required.
- Never expose implementation details or clients publicly.
- Keep repositories stateless, except for explicit lightweight caches when needed.
- Cache only immutable, fetch-heavy data.
- Use private fields for internal state.
- Never handle domain errors in repository; let upper layers (e.g., cubit) handle them.
- Use async/await for one-off calls; return Future for single fetch/update.
- Use Stream only when data must update reactively (e.g., live UI).
- Inline doc comments for each non-obvious field or method.

# Exemple:
class FooRepositoryRemote implements FooRepository {
  FooRepositoryRemote({required ApiClient apiClient}) : _apiClient = apiClient;
  final ApiClient _apiClient;
  List<Item>? _cache;
  
  Future<Foo> getFoo(String param) async {
    final info = await _client.getInfo(param);
    final data = await _client.getData(info.id);
    return Foo(
        value: data.value,
        name: info.name,
    );
    }
}
