// lib/features/auth/presentation/widgets/auth_gate.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flowgenix/features/auth/presentation/screens/login_screen.dart';
import 'package:flowgenix/features/dashboards/presentations/screens/home_screen.dart'; // Corrected path

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens for changes in the authentication state
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. If the stream is still loading, show a loading indicator
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 2. If the snapshot has data, it means a user is logged in
        if (snapshot.hasData) {
          return const HomeScreen(); // Go to the Home Screen
        }
        // 3. If there is no data, the user is logged out
        else {
          return const LoginScreen(); // Go to the Login Screen
        }
      },
    );
  }
}