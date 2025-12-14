// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// Import our new AuthGate
import 'package:flowgenix/features/auth/presentation/widgets/auth_gate.dart';
// Import the generated Firebase options
import 'firebase_options.dart';
// Import the app's theme
import 'presentation/theme/app_theme.dart';

Future<void> main() async {
  // Ensure that Flutter bindings are initialized before calling native code
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase with the platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowGenix',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,

      // --- THE ONLY CHANGE ---
      // Use the AuthGate as the home widget. It will handle the decision
      // of whether to show the LoginScreen or the HomeScreen.
      home: const AuthGate(),
    );
  }
}