import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      // We don't need a scaffold background color now that we have an image
      primaryColor: const Color(0xFFF9A826), // Our glowing accent color

      // Set the default font for the entire app to Poppins
      fontFamily: 'Poppins',

      textTheme: const TextTheme(
        // Example of defining a specific text style we can reuse
        headlineSmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}