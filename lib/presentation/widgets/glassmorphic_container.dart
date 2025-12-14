import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicContainer extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const GlassmorphicContainer({
    super.key,
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0), // Consistent rounding
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            // The blur effect
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 7.0,
                sigmaY: 7.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1), // Glass color
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            ),
            // The border
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.0,
                ),
              ),
            ),
            // The content
            Center(child: child),
          ],
        ),
      ),
    );
  }
}

class ProcessingScreen extends StatelessWidget {
  const ProcessingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 1. The Background
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/your_background.png"), // Your background image
            fit: BoxFit.cover,
          ),
        ),
        // 2. Centered Content
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // We will build these widgets in the next step
              // 3. The Animated Progress Ring (Placeholder)
              CircularProgressIndicator(), // Placeholder for now

              SizedBox(height: 40),

              // 4. The Dynamic Status Text (Placeholder)
              Text(
                'Initializing...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}