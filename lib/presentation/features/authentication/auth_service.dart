import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../data/constants/api_constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get user ID for database operations
  String? getUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get user email
  String? getUserEmail() {
    return _auth.currentUser?.email;
  }

  /// Get user display name
  String? getUserDisplayName() {
    return _auth.currentUser?.displayName;
  }

  /// Check if user is signed in
  bool isSignedIn() {
    return _auth.currentUser != null;
  }

  /// Initialize user in backend and return user info
  Future<Map<String, dynamic>> initializeUser(User user) async {
    final callable = _functions.httpsCallable('handle_first_time_user');
    final result = await callable.call({
      'email': user.email,
      'name': user.displayName,
    });
    
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Check if Apple Sign In is available
  Future<bool> isAppleSignInAvailable() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      return false;
    }
    return await SignInWithApple.isAvailable();
  }

  /// Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      // Check if Apple Sign In is available
      if (!await isAppleSignInAvailable()) {
        throw Exception('Apple Sign In is not available on this device');
      }

      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: APIConstants.appleClientId,
          redirectUri: Uri.parse(APIConstants.appleRedirectUri),
        ),
      );

      // Create OAuth credential for Firebase
      final oauthCredential = OAuthProvider(APIConstants.appleProvider).credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the Apple credential
      final UserCredential userCredential = await _auth.signInWithCredential(oauthCredential);

      // Update user profile with Apple ID information if available
      if (userCredential.user != null && appleCredential.givenName != null) {
        await userCredential.user!.updateDisplayName(
          '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'.trim(),
        );
      }

      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          throw Exception('Apple Sign In was canceled');
        case AuthorizationErrorCode.failed:
          throw Exception('Apple Sign In failed');
        case AuthorizationErrorCode.invalidResponse:
          throw Exception('Invalid response from Apple Sign In');
        case AuthorizationErrorCode.notHandled:
          throw Exception('Apple Sign In not handled');
        case AuthorizationErrorCode.unknown:
          throw Exception('Unknown error during Apple Sign In');
        default:
          throw Exception('Apple Sign In error: ${e.message}');
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception('An account already exists with a different sign-in method');
        case 'invalid-credential':
          throw Exception('Invalid Apple Sign In credential');
        case 'operation-not-allowed':
          throw Exception('Apple Sign In is not enabled for this project');
        case 'user-disabled':
          throw Exception('This user account has been disabled');
        case 'user-not-found':
          throw Exception('No user found for this Apple ID');
        case 'wrong-password':
          throw Exception('Wrong password provided');
        default:
          throw Exception('Authentication error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to sign in with Apple: $e');
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        throw Exception('Google Sign In was canceled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception('An account already exists with a different sign-in method');
        case 'invalid-credential':
          throw Exception('Invalid Google Sign In credential');
        case 'operation-not-allowed':
          throw Exception('Google Sign In is not enabled for this project');
        case 'user-disabled':
          throw Exception('This user account has been disabled');
        case 'user-not-found':
          throw Exception('No user found for this Google account');
        case 'wrong-password':
          throw Exception('Wrong password provided');
        default:
          throw Exception('Authentication error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  /// Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw Exception('The password provided is too weak');
        case 'email-already-in-use':
          throw Exception('An account already exists for this email');
        case 'invalid-email':
          throw Exception('The email address is not valid');
        case 'operation-not-allowed':
          throw Exception('Email/password accounts are not enabled');
        default:
          throw Exception('Sign up error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found for this email');
        case 'wrong-password':
          throw Exception('Wrong password provided');
        case 'invalid-email':
          throw Exception('The email address is not valid');
        case 'user-disabled':
          throw Exception('This user account has been disabled');
        case 'too-many-requests':
          throw Exception('Too many failed attempts. Please try again later');
        default:
          throw Exception('Sign in error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw Exception('The email address is not valid');
        case 'user-not-found':
          throw Exception('No user found for this email');
        default:
          throw Exception('Password reset error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google if signed in
      await GoogleSignIn().signOut();
      // Sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}