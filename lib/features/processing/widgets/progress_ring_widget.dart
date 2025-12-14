import 'package:flutter/material.dart';
import 'dart:math' as math;

class ProgressRingWidget extends StatefulWidget {
  const ProgressRingWidget({super.key});

  @override
  _ProgressRingWidgetState createState() => _ProgressRingWidgetState();
}

class _ProgressRingWidgetState extends State<ProgressRingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Example duration
    )..forward(); // Start the animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(150, 150),
          painter: ProgressRingPainter(progress: _controller.value),
        );
      },
    );
  }
}

class ProgressRingPainter extends CustomPainter {
  final double progress; // Value from 0.0 to 1.0

  ProgressRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: size.width / 2);
    final accentColor = Color(0xFFF9A826); // Use your theme's primary color

    // The background track of the ring
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // The glowing progress part of the ring
    final progressPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6.0
      ..shader = SweepGradient( // This creates the gradient glow
        colors: [accentColor.withOpacity(0.3), accentColor],
        startAngle: -math.pi / 2,
        endAngle: (2 * math.pi) * progress,
      ).createShader(rect);

    canvas.drawCircle(center, size.width / 2, trackPaint);
    canvas.drawArc(
      rect,
      -math.pi / 2, // Start from the top
      (2 * math.pi) * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}