# Rules:
- Split state and logic into separate files with `part`.
- Use `Cubit<State>` from `bloc` package for state management.
- Inject repositories via constructor.
- Expose async methods for loading/updating state.
- Guard early returns for null/invalid parameters and error states.
- Apply optimistic updates: emit state with updated data before awaiting async call, then reconcile on success/failure.
- Guard against concurrent calls (e.g., track loading/updating state and return early if already loading/updating).

# Exemple:

```dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'feature_state.dart';

class FeatureCubit extends Cubit<FeatureState> {
  FeatureCubit(this._repository) : super(FeatureState());

  final Repository _repository;

  Future<void> load(String param) async {
    if (param.isEmpty) return;
    emit(state.copyWith(status: Status.loading));
    try {
      final data = await _repository.getData(param);
      emit(state.copyWith(status: Status.success, data: data));
    } catch (_) {
      emit(state.copyWith(status: Status.failure));
    }
  }

  Future<void> updateData(DataType newData) async {
    // Optimistic update
    if (state.status == Status.updating) return; 
    emit(state.copyWith(data: newData, status: Status.updating));
    try {
      await _repository.update(newData);
      emit(state.copyWith(status: Status.success));
    } catch (_) {
      emit(state.copyWith(status: Status.failure, data: state.data)); // Rollback or handle
    }
  }
}
```
