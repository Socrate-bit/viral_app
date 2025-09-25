import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/features/authentication/auth_cubit.dart';
import '../../presentation/features/navigation/navigation_cubit.dart';
import '../../presentation/features/usage/token_cubit.dart';
import '../../presentation/features/image_gallery/gallery_cubit.dart';
import '../../presentation/features/pack_generation/pack_generation_cubit.dart';
import '../../presentation/features/image_editor/editing_cubit.dart';
import '../../presentation/features/pack_list/packs_cubit.dart';
import '../../data/repositories/firebase_service.dart';
import '../../data/repositories/cloud_ai_service.dart';

/// Service locator for dependency injection
/// Provides centralized bloc provider configuration
class Injection {
  
  /// Get global app-level providers (available throughout app lifecycle)
  static List<BlocProvider> getGlobalProviders() {
    return [
      BlocProvider<AuthCubit>(
        create: (context) => AuthCubit(),
      ),
      BlocProvider<PacksCubit>(
        create: (context) => PacksCubit(FirebaseService())..loadPacks(),
      ),
    ];
  }

  /// Get user-specific providers (only available for authenticated users)
  static List<BlocProvider> getUserSpecificProviders() {
    return [
      BlocProvider<NavigationCubit>(
        create: (context) => NavigationCubit(),
      ),
      BlocProvider<TokenCubit>(
        create: (context) => TokenCubit()..onUserLogin(),
      ),
      BlocProvider<GalleryCubit>(
        create: (context) => GalleryCubit(),
      ),
      BlocProvider<PackGenerationCubit>(
        create: (context) => PackGenerationCubit(
          CloudAIService(),
          context.read<TokenCubit>(),
          context.read<GalleryCubit>(),
        ),
      ),
      BlocProvider<EditingCubit>(
        create: (context) => EditingCubit(
          galleryCubit: context.read<GalleryCubit>(),
          tokenCubit: context.read<TokenCubit>(),
        )..initialize(),
      ),
    ];
  }

  /// Create MultiBlocProvider widget with global providers
  static Widget createGlobalProviders({required Widget child}) {
    return MultiBlocProvider(
      providers: getGlobalProviders(),
      child: child,
    );
  }

  /// Create MultiBlocProvider widget with user-specific providers
  static Widget createUserSpecificProviders({required Widget child}) {
    return MultiBlocProvider(
      providers: getUserSpecificProviders(),
      child: child,
    );
  }
}
