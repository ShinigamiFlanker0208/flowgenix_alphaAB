// lib/features/profile/presentation/screens/profile_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:animated_background/animated_background.dart';
import 'package:intl/intl.dart';

// Import your login screen - ADJUST THIS PATH TO MATCH YOUR PROJECT STRUCTURE
import 'package:flowgenix/features/auth/presentation/screens/login_screen.dart';

// Dark aesthetic colors - MATCHING YOUR APP THEME
const Color _kDarkBackground = Color(0xFF1a1a2e);
const Color _kDarkAccent = Color(0xFF16213e);
const Color _kPrimaryColor = Color(0xFF6C63FF); // Your app's primary purple

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {

  User? _currentUser;
  bool _isSigningOut = false;

  // ULTRA-SMOOTH GYROSCOPE - BUTTERY PERFORMANCE
  double _currentRotateX = 0;
  double _currentRotateY = 0;
  double _targetRotateX = 0;
  double _targetRotateY = 0;
  StreamSubscription? _gyroscopeSubscription;
  Timer? _resetTimer;
  Timer? _smoothingTimer;

  // PERFECTLY TUNED for BUTTER-SMOOTH experience
  static const double _deadZone = 0.15;
  static const double _sensitivity = 0.008;
  static const double _maxTilt = 0.15;
  static const double _smoothingFactor = 0.12;
  static const double _resetDamping = 0.96;

  // Animation controllers
  late AnimationController _entranceController;
  late AnimationController _glowController;
  late AnimationController _atmosphereController;
  late AnimationController _lightingController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _currentUser = FirebaseAuth.instance.currentUser;

    // BUTTER-SMOOTH entrance animations
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _atmosphereController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _lightingController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _glowAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOutSine,
    ));

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _entranceController.forward();
    });

    _setupSmoothGyroscope();
    _startSmoothingLoop();
  }

  void _setupSmoothGyroscope() {
    _gyroscopeSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
      if (event.x.abs() > _deadZone || event.y.abs() > _deadZone) {
        _resetTimer?.cancel();

        final deltaY = (event.x * _sensitivity).clamp(-0.015, 0.015);
        final deltaX = (event.y * _sensitivity).clamp(-0.015, 0.015);

        _targetRotateY = (_targetRotateY + deltaY).clamp(-_maxTilt, _maxTilt);
        _targetRotateX = (_targetRotateX + deltaX).clamp(-_maxTilt, _maxTilt);

        _resetTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) _startSmoothReset();
        });
      }
    });
  }

  void _startSmoothingLoop() {
    _smoothingTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _currentRotateX += (_targetRotateX - _currentRotateX) * _smoothingFactor;
      _currentRotateY += (_targetRotateY - _currentRotateY) * _smoothingFactor;

      if ((_currentRotateX - _targetRotateX).abs() > 0.001 ||
          (_currentRotateY - _targetRotateY).abs() > 0.001) {
        setState(() {});
      }
    });
  }

  void _startSmoothReset() {
    Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      _targetRotateX *= _resetDamping;
      _targetRotateY *= _resetDamping;

      if (_targetRotateX.abs() < 0.001 && _targetRotateY.abs() < 0.001) {
        _targetRotateX = 0;
        _targetRotateY = 0;
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _glowController.dispose();
    _atmosphereController.dispose();
    _lightingController.dispose();
    _gyroscopeSubscription?.cancel();
    _resetTimer?.cancel();
    _smoothingTimer?.cancel();
    super.dispose();
  }

  void _triggerGlow() {
    if (mounted && !_glowController.isAnimating) {
      _glowController.forward().then((_) {
        if (mounted) _glowController.reverse();
      });
    }
  }

  Future<void> _handleSignOut() async {
    if (_isSigningOut) return;

    final shouldSignOut = await _showSignOutDialog();
    if (!shouldSignOut) return;

    setState(() => _isSigningOut = true);

    try {
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        // Use pushAndRemoveUntil with MaterialPageRoute instead of named route
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to sign out: ${e.toString()}');
        setState(() => _isSigningOut = false);
      }
    }
  }

  Future<bool> _showSignOutDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _kDarkAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _shortenUID(String uid) {
    if (uid.length <= 16) return uid;
    return '${uid.substring(0, 8)}...${uid.substring(uid.length - 8)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: _kDarkBackground,
        body: Center(
          child: Text(
            'No user logged in',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kDarkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _kDarkAccent,
              _kDarkBackground,
              _kDarkBackground,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Subtle particle background
            Positioned.fill(
              child: AnimatedBackground(
                behaviour: RandomParticleBehaviour(
                  options: ParticleOptions(
                    baseColor: _kPrimaryColor.withOpacity(0.15),
                    spawnOpacity: 0.15,
                    opacityChangeRate: -0.01,
                    minOpacity: 0.0,
                    maxOpacity: 0.2,
                    particleCount: 60,
                    spawnMaxRadius: 3.0,
                    spawnMinRadius: 1.0,
                    spawnMaxSpeed: 12.0,
                    spawnMinSpeed: 3.0,
                  ),
                ),
                vsync: this,
                child: Container(),
              ),
            ),

            // Ambient lighting
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _lightingController,
                builder: (context, child) {
                  final lightingTime = _lightingController.value * 2 * math.pi;
                  final intensity = (math.sin(lightingTime * 0.3) + 1) / 12;

                  return Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(
                          math.sin(lightingTime * 0.1) * 0.1,
                          -0.3,
                        ),
                        radius: 1.5,
                        colors: [
                          _kPrimaryColor.withOpacity(intensity * 0.3),
                          _kPrimaryColor.withOpacity(intensity * 0.15),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 3D Profile Card
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: GestureDetector(
                    onTap: _triggerGlow,
                    child: AnimatedBuilder(
                      animation: _atmosphereController,
                      builder: (context, child) {
                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateX(_currentRotateX)
                            ..rotateY(_currentRotateY),
                          alignment: FractionalOffset.center,
                          child: child,
                        );
                      },
                      child: AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          final glowIntensity = _glowAnimation.value;

                          return Container(
                            width: 340,
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: _kDarkAccent.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _kPrimaryColor.withOpacity(0.3 * glowIntensity),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _kPrimaryColor.withOpacity(0.15 * glowIntensity),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildUserInfo(),
                            const SizedBox(height: 32),
                            Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    _kPrimaryColor.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            _buildAccountDetails(),
                            const SizedBox(height: 32),
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    // Get username or fallback to email username part
    String displayName = _currentUser!.displayName ??
        _currentUser!.email?.split('@').first ??
        'User';

    return Column(
      children: [
        Text(
          displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _currentUser!.emailVerified
                ? Colors.green.withOpacity(0.2)
                : Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _currentUser!.emailVerified
                  ? Colors.green.withOpacity(0.5)
                  : Colors.orange.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _currentUser!.emailVerified ? Icons.verified : Icons.pending,
                color: _currentUser!.emailVerified ? Colors.green : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _currentUser!.emailVerified ? 'Verified Account' : 'Unverified',
                style: TextStyle(
                  color: _currentUser!.emailVerified ? Colors.green : Colors.orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountDetails() {
    return Column(
      children: [
        _buildDetailRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: _currentUser!.email ?? 'No email',
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          icon: Icons.fingerprint,
          label: 'User ID',
          value: _shortenUID(_currentUser!.uid),
          isMonospace: true,
        ),
        const SizedBox(height: 16),
        _buildDetailRow(
          icon: Icons.calendar_today_outlined,
          label: 'Joined',
          value: _formatDate(_currentUser!.metadata.creationTime),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMonospace = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _kPrimaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: _kPrimaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: isMonospace ? 'monospace' : null,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSigningOut ? null : _handleSignOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              disabledBackgroundColor: Colors.red.shade600.withOpacity(0.5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSigningOut
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, size: 18),
                SizedBox(width: 8),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}