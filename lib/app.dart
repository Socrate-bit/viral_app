import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/onboarding_page.dart';
import 'pages/home_page.dart';
import 'services/auth_service.dart';
import 'core/theme/theme.dart';
import 'editor/editing_cubit.dart';
import 'gallery/gallery_cubit.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EditingCubit>(create: (context) => EditingCubit()),
        BlocProvider<GalleryCubit>(create: (context) => GalleryCubit()),
      ],
      child: MaterialApp(
        title: 'Viral App',
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Show onboarding if user is not signed in
        if (snapshot.data == null) {
          return const OnboardingPage();
        }
        
        // Show main app if user is signed in
        return const HomePage();
      },
    );
  }
}
