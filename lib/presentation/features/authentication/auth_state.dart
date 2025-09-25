import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state when checking authentication
class AuthInitial extends AuthState {}

/// User is not authenticated
class AuthUnauthenticated extends AuthState {}

/// User is authenticated but not yet initialized in backend
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user.uid];
}

/// User is authenticated and initialized (ready to use app)
class AuthReady extends AuthState {
  final User user;
  final String role;

  const AuthReady({
    required this.user,
    required this.role,
  });

  @override
  List<Object?> get props => [user.uid, role];
}

/// Authentication error
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
