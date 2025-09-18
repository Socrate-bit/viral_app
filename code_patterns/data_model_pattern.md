# Rules:
- Use `freezed_annotation` for immutable data classes and unions
- Separate part files for `.freezed.dart` and `.g.dart`
- Enum for fixed value sets
- `@freezed` annotation for code generation
- `const factory` constructor for model definition
- All properties required and named
- Inline doc comments for each non-obvious field or method.
- Use specific types for all fields
- Factory method for JSON serialization/deserialization
- File naming: match Dart class and part names
- Don't put business logic in it keep model pure data holder
- Inline doc comments for each non-obvious field or method.

# Exemple:
@freezed
class Example with _$Example {
  const factory Example({
    required String id,
    required int count,
  }) = _Example;
  factory Example.fromJson(Map<String, Object?> json) => _$ExampleFromJson(json);
}
