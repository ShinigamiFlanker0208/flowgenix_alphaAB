import 'dart:ui';
import 'package:flutter/material.dart';

class GlassTextField extends StatelessWidget {
  final String hintText;
  final IconData leadingIcon;
  final bool isPassword;

  const GlassTextField({
    super.key,
    required this.hintText,
    required this.leadingIcon,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. ClipRRect to get the rounded corners
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        // 2. BackdropFilter for the blur effect
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: 55,
          decoration: BoxDecoration(
            // 3. The subtle white color and border for the "glass" look
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(width: 1.5, color: Colors.white.withOpacity(0.2)),
          ),
          child: TextFormField(
            // 4. The actual text input field
            obscureText: isPassword, // Hides text for passwords
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              // 5. Styling the input field itself
              border: InputBorder.none, // Removes the default underline
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              // 6. Adding the icon on the left
              prefixIcon: Icon(
                leadingIcon,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}