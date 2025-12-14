import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for HapticFeedback

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // 1. GestureDetector to handle the tap event
    return GestureDetector(
      onTap: () {
        // 2. HAPTIC FEEDBACK IMPLEMENTATION
        print("button pressed");
        HapticFeedback.vibrate();
        onPressed(); // Execute the original function passed to the button
      },
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          // 3. Use the theme's primary color
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(15),
          // 4. Add a subtle shadow to make the button "pop"
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}