import 'package:equatable/equatable.dart';

abstract class TokenState extends Equatable {
  const TokenState();

  @override
  List<Object?> get props => [];
}

class TokenInitial extends TokenState {}

class TokenLoaded extends TokenState {
  final int balance;
  final String subscriptionStatus;
  final String? subscriptionProductId;
  final String? lastUpdated;
  final String role;

  const TokenLoaded({
    required this.balance,
    required this.subscriptionStatus,
    this.subscriptionProductId,
    this.lastUpdated,
    this.role = 'normal',
  });

  @override
  List<Object?> get props => [balance, subscriptionStatus, subscriptionProductId, lastUpdated, role];

  TokenLoaded copyWith({
    int? balance,
    String? subscriptionStatus,
    String? subscriptionProductId,
    String? lastUpdated,
    String? role,
  }) {
    return TokenLoaded(
      balance: balance ?? this.balance,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionProductId: subscriptionProductId ?? this.subscriptionProductId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      role: role ?? this.role,
    );
  }
}

class TokenError extends TokenState {
  final String message;

  const TokenError(this.message);

  @override
  List<Object?> get props => [message];
}

class TokenUnauthenticated extends TokenState {}
