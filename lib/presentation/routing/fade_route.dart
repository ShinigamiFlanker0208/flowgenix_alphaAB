import 'package:flutter/material.dart';

class FadeRoute extends PageRouteBuilder {
  final Widget widget;

  FadeRoute({required this.widget})
      : super(
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      return widget;
    },
    transitionsBuilder: (BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child) {
      // Use a FadeTransition to fade the new screen in
      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
        child: child,
      );
    },
  );
}