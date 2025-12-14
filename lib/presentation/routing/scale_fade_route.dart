import 'package:flutter/material.dart';

class ScaleFadeRoute extends PageRouteBuilder {
  final Widget widget;

  ScaleFadeRoute({required this.widget})
      : super(
    // Set a slightly longer duration for a more graceful effect
    transitionDuration: const Duration(milliseconds: 2500),
    // Make the route transparent to see the screen behind
    opaque: false,
    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
      return widget;
    },
    transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {

      // Use a CurvedAnimation to add easing (makes the animation feel more natural)
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic, // A smooth, elegant curve
      );

      // Combine a FadeTransition with a ScaleTransition
      return ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
        child: FadeTransition(
          opacity: curvedAnimation, // The curve is applied to the fade as well
          child: child,
        ),
      );
    },
  );
}