# Rules:

* **Enum** for fixed value sets.
* Use `final class` with `Equatable` for immutable state.
* All properties **required and named**.
* Inline `///` doc comments for each **non-obvious field or method**.
* Use **specific types** for all fields.
* Provide **factory methods** for JSON serialization/deserialization.
* Implement `copyWith` for safe updates without mutation.
* Keep model as a **pure data holder** (no business logic).
* **Minimize boilerplate** → extract reusable helpers, refactor common patterns, avoid duplication.
* **Keep it simple**: minimal, focused code.

# Exemple:

```dart
import 'package:equatable/equatable.dart';

/// Example domain model representing a simple entity.
final class Example extends Equatable {
  const Example({
    /// Unique identifier for the entity.
    required this.id,

    /// Counter value associated with this entity.
    required this.count,
  });

  final String id;
  final int count;

  /// Create a copy with modified fields.
  Example copyWith({
    String? id,
    int? count,
  }) {
    return Example(
      id: id ?? this.id,
      count: count ?? this.count,
    );
  }

  /// Deserialize from JSON.
  factory Example.fromJson(Map<String, dynamic> json) {
    return Example(
      id: json['id'] as String,
      count: json['count'] as int,
    );
  }

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'count': count,
      };

  @override
  List<Object?> get props => [id, count];
}
```
