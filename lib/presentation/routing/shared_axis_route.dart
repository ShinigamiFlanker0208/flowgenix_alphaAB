import 'package:flutter/material.dart';
import 'package:animations/animations.dart'; // Import the animations package

class SharedAxisRoute extends PageRouteBuilder {
  final Widget widget;

  SharedAxisRoute({required this.widget})
      : super(
    transitionDuration: const Duration(milliseconds: 1850), // A slightly longer duration feels more elegant
    pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
      return widget;
    },
    transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {

      // This is the core of the new transition
      return SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.vertical, // Use horizontal for left/right feel
        fillColor: Colors.transparent, // CRITICAL: Makes the background transparent to show our image
        child: child,
      );
    },
  );
}