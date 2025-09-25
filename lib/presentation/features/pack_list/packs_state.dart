part of 'packs_cubit.dart';

enum PacksStatus { initial, loading, success, failure }

final class PacksState extends Equatable {
  const PacksState({
    this.status = PacksStatus.initial,
    this.packs = const [],
  });

  final PacksStatus status;
  final List<Pack> packs;

  PacksState copyWith({
    PacksStatus? status,
    List<Pack>? packs,
  }) {
    return PacksState(
      status: status ?? this.status,
      packs: packs ?? this.packs,
    );
  }

  @override
  List<Object?> get props => [status, packs];
}
