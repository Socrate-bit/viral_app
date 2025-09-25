import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({AuthService? authService}) : super(AuthInitial()) {
    _authService = authService ?? AuthService();
    _initializeAuth();
  }

  late final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  /// Initialize authentication listener
  void _initializeAuth() {
    _authSubscription = _authService.authStateChanges.listen(
      _handleAuthStateChange,
    );
  }

  /// Handle Firebase auth state changes
  void _handleAuthStateChange(User? user) async {
    if (user == null) {
      emit(AuthUnauthenticated());
    } else {
      emit(AuthAuthenticated(user));
      await _handleUserInitialization(user);
    }
  }

  /// Handle user initialization after authentication
  Future<void> _handleUserInitialization(User user) async {
    try {
      final responseData = await _authService.initializeUser(user);
      final isNewUser = responseData['isNewUser'] ?? false;
      final role = responseData['role'] ?? 'normal';

      emit(AuthReady(user: user, role: role));

      if (isNewUser) {
        print(
          'New user initialized with role: $role and ${responseData['welcomeTokens']} tokens',
        );
      }
    } catch (e) {
      print('Warning: Failed to initialize user: $e');
      // Still emit ready state with default values to not block the app
      emit(AuthReady(user: user, role: 'normal'));
    }
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    try {
      await _authService.signInWithApple();
      // State change is handled automatically by the auth state listener
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      await _authService.signInWithGoogle();
      // State change is handled automatically by the auth state listener
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      // State change is handled automatically by the auth state listener
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // State change is handled automatically by the auth state listener
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      // State change is handled automatically by the auth state listener
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      await _authService.deleteAccount();
      // State change is handled automatically by the auth state listener
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Get current user
  User? get currentUser => _authService.currentUser;

  /// Get user ID for database operations
  String? getUserId() => _authService.getUserId();

  /// Get user email
  String? getUserEmail() => _authService.getUserEmail();

  /// Get user display name
  String? getUserDisplayName() => _authService.getUserDisplayName();

  /// Check if user is signed in
  bool isSignedIn() => _authService.isSignedIn();

  /// Check if Apple Sign In is available
  Future<bool> isAppleSignInAvailable() =>
      _authService.isAppleSignInAvailable();

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
