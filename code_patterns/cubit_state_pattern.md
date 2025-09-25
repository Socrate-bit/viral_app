# Rules:

- Use **subclasses** (`sealed` or `abstract class`) for *global lifecycle phases* (e.g., `Initial`, `Loading`, `Error`, `Loaded`).
- Inside *rich states* (like `Loaded`), use `enum` for **fixed sub-status sets**.
- Use extension methods for enum utilities.
- Use `final class` with `Equatable` for immutable state.
- Provide default values in constructors when logic to do it.
- Use nullable constructor params with fallback (`??`) for defaults.
- Implement `copyWith` for state updates.
- Organise the properties of the state:
    - Maintain a **consistent ordering pattern** across all states to improve readability.
    - **By category** → group related fields together.
    - **By importance / usage** → place the most important fields first (e.g. status, then main data, then flags).
    - **Specify each category only once in the constructor parameter list** as a `//` comment. Do **not** repeat the category labels
- Add `///` comments for fields or methods whose purpose isn’t obvious from the name.
- Minimize boilerplate → extract reusable helpers, refactor common patterns, and avoid duplicating logic across methods or services.
- Keep it Simple: Minimal, focused code.

# Exemple:

```dart
// Fixed set of statuses for a sub-process
enum ProcessStatus { idle, loading, success, failure }

// Global lifecycle states
sealed class AppState extends Equatable {
  const AppState();
  @override
  List<Object?> get props => [];
}

final class AppInitial extends AppState {}

final class AppError extends AppState {
  const AppError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

final class AppLoaded extends AppState {
  const AppLoaded({
    this.data = '',
    this.processStatus = ProcessStatus.idle,
  });

  final String data; // example field
  final ProcessStatus processStatus;

  AppLoaded copyWith({
    String? data,
    ProcessStatus? processStatus,
  }) {
    return AppLoaded(
      data: data ?? this.data,
      processStatus: processStatus ?? this.processStatus,
    );
  }

  @override
  List<Object?> get props => [data, processStatus];
}
```