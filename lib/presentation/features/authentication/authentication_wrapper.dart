import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'onboarding_page.dart';
import '../navigation/home_page.dart';
import 'auth_cubit.dart';
import 'auth_state.dart';
import '../usage/token_cubit.dart';
import '../../../core/di/injection.dart';

/// Authentication wrapper that provides appropriate UI based on auth state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // State
  String? _lastIdentifiedUserId;

  // Actions
  void _handleUserSignIn(String userId) {
    if (_lastIdentifiedUserId != userId) {
      _lastIdentifiedUserId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Use TokenCubit to identify user with Superwall
        final tokenCubit = context.read<TokenCubit>();
        tokenCubit.identifyUserWithSuperwall(userId);
      });
    }
  }

  void _handleUserSignOut() {
    if (_lastIdentifiedUserId != null) {
      _lastIdentifiedUserId = null;
      // TokenCubit will handle Superwall reset in onUserLogout()
    }
  }

  // Main build
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return switch (state) {
          AuthInitial() => _buildLoading(),
          AuthUnauthenticated() => _buildUnauthenticated(),
          AuthAuthenticated() => _buildAuthenticating(),
          AuthReady() => _buildAuthenticated(state),
          AuthError() => _buildUnauthenticated(), // Redirect errors to onboarding
          _ => _buildLoading(),
        };
      },
    );
  }

  // Components
  Widget _buildLoading() {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildUnauthenticated() {
    _handleUserSignOut();
    return const OnboardingPage();
  }

  Widget _buildAuthenticating() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Setting up your account...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticated(AuthReady state) {
    _handleUserSignIn(state.user.uid);
    
    // Provide user-specific business logic cubits only for authenticated users
    return Injection.createUserSpecificProviders(
      child: Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const HomePage(),
            settings: settings,
          );
        },
      ),
    );
  }
}
