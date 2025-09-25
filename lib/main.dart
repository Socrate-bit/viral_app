import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';
import 'firebase_options.dart';
import 'presentation/core/theme/theme.dart';
import 'presentation/core/widgets/widgets.dart';
import 'presentation/features/authentication/authentication_wrapper.dart';
import 'core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Superwall
  // FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  const String apiKey = 'pk_RTvsXyxTrr_cz5YrKj8Ta';
  Superwall.configure(apiKey);

  runApp(const MyApp());
}

/// Main application entry point
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Injection.createGlobalProviders(
      child: KeyboardDismisser(
        child: MaterialApp(
          title: 'Reey.AI',
          theme: AppTheme.darkTheme,
          home: const AuthWrapper(),
        ),
      ),
    );
  }
}
