part of 'pack_generation_cubit.dart';

enum PackGenerationStatus { initial, loading, success, failure, pop }

final class PackGenerationState extends Equatable {
  const PackGenerationState({
    this.status = PackGenerationStatus.initial,
    this.result,
    this.pack,
    this.errorMessage,
  });

  final PackGenerationStatus status;
  final PackGenerationResult? result;
  final Pack? pack;
  final String? errorMessage;

  PackGenerationState copyWith({
    PackGenerationStatus? status,
    PackGenerationResult? result,
    Pack? pack,
    String? errorMessage,
  }) {
    return PackGenerationState(
      status: status ?? this.status,
      result: result ?? this.result,
      pack: pack ?? this.pack,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, result, pack, errorMessage];
}
