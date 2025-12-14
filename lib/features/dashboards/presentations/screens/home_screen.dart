// lib/features/dashboard/presentation/screens/home_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animated_background/animated_background.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Import your project files
import 'package:flowgenix/presentation/theme/color_palette.dart';
import 'package:flowgenix/features/profile/presentations/screens/profile_screen.dart';
import 'package:flowgenix/features/dashboards/presentations/screens/canvas_screen.dart';
import 'package:flowgenix/features/dashboards/presentations/screens/dashboard_screen.dart';

// Modern theme colors
const Color _kDarkBackground = Color(0xFF0A0E27);
const Color _kDarkAccent = Color(0xFF1A1F3A);
const Color _kCardBackground = Color(0xFF252B48);
const Color _kAccentGlow = Color(0xFF6C5CE7);
const Color _kSecondaryGlow = Color(0xFF00D4FF);
const Color _kPinkGlow = Color(0xFFFF6584);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _lightingController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  User? _currentUser;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();

    // Get current user
    _currentUser = FirebaseAuth.instance.currentUser;
    _userName = _currentUser?.displayName ?? _currentUser?.email?.split('@')[0] ?? 'User';

    // Ultra-optimized fluid animations
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _lightingController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutQuart),
    ));

    // Start animation immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _lightingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDarkBackground,
      body: RepaintBoundary(
        child: Stack(
          children: [
            // Optimized static gradient background
            const _StaticGradientBackground(),

            // Reduced particle count for performance
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBackground(
                  behaviour: RandomParticleBehaviour(
                    options: ParticleOptions(
                      baseColor: _kAccentGlow.withOpacity(0.18),
                      spawnOpacity: 0.18,
                      opacityChangeRate: -0.008,
                      minOpacity: 0.0,
                      maxOpacity: 0.22,
                      particleCount: 35, // Reduced from 50
                      spawnMaxRadius: 3.5,
                      spawnMinRadius: 1.5,
                      spawnMaxSpeed: 10.0,
                      spawnMinSpeed: 4.0,
                    ),
                  ),
                  vsync: this,
                  child: Container(),
                ),
              ),
            ),

            // Optimized ambient lighting
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _lightingController,
                  builder: (context, child) {
                    final intensity = (math.sin(_lightingController.value * 2 * math.pi * 0.3) + 1) / 14;

                    return IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, -0.4),
                            radius: 1.6,
                            colors: [
                              _kAccentGlow.withOpacity(intensity * 0.35),
                              _kSecondaryGlow.withOpacity(intensity * 0.18),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Main content with optimized animations
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      // Modern App Bar
                      SliverToBoxAdapter(
                        child: RepaintBoundary(child: _buildModernAppBar()),
                      ),

                      // Welcome Section
                      SliverToBoxAdapter(
                        child: RepaintBoundary(child: _buildWelcomeSection()),
                      ),

                      // Quick Actions Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 22,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_kAccentGlow, _kSecondaryGlow],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _kAccentGlow.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'QUICK ACTIONS',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Actions List with optimized RepaintBoundaries
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 40),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            RepaintBoundary(
                              child: _buildActionCard(
                                icon: Icons.add_circle_outline_rounded,
                                title: 'Create New Project',
                                subtitle: 'Start building something amazing',
                                gradientColors: const [_kAccentGlow, _kSecondaryGlow],
                                delay: 500,
                                onTap: () => Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const CanvasScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(
                                        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(milliseconds: 300),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            RepaintBoundary(
                              child: _buildActionCard(
                                icon: Icons.folder_rounded,
                                title: 'My Projects',
                                subtitle: 'Browse all your saved projects',
                                gradientColors: const [_kPinkGlow, Color(0xFFFF8BA7)],
                                delay: 600,
                                onTap: () => Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(
                                        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(milliseconds: 300),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            RepaintBoundary(
                              child: _buildActionCard(
                                icon: Icons.person_rounded,
                                title: 'Settings & Profile',
                                subtitle: 'Manage your account preferences',
                                gradientColors: const [_kSecondaryGlow, Color(0xFF4FACFE)],
                                delay: 700,
                                onTap: () => Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(
                                        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                                        child: child,
                                      );
                                    },
                                    transitionDuration: const Duration(milliseconds: 300),
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: "flowgenix_logo_hero",
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_kCardBackground, _kDarkAccent], //   increasing the size of the logo
                //   increasing the size of the logo


                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _kAccentGlow.withOpacity(0.3), width: 1.8),
                boxShadow: [
                  BoxShadow(
                    color: _kAccentGlow.withOpacity(0.25),
                    blurRadius: 24,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: _kSecondaryGlow.withOpacity(0.15),
                    blurRadius: 32,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/FlowGenix_logo.png',
                height: 56,
                filterQuality: FilterQuality.medium,
              ),
            ),
          )
              .animate(delay: const Duration(milliseconds: 150))
              .fadeIn(duration: const Duration(milliseconds: 800), curve: Curves.easeOutCubic)
              .scale(begin: const Offset(0.88, 0.88), curve: Curves.easeOutBack, duration: const Duration(milliseconds: 900))
              .then()
              .shimmer(
              duration: const Duration(milliseconds: 2000),
              curve: Curves.easeInOutSine,
              color: _kAccentGlow.withOpacity(0.35)),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _kCardBackground.withOpacity(0.75),
                  _kDarkAccent.withOpacity(0.55),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.3),
              boxShadow: [
                BoxShadow(
                  color: _kAccentGlow.withOpacity(0.12),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 4.5,
                  height: 65,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_kAccentGlow, _kSecondaryGlow],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: _kAccentGlow.withOpacity(0.55),
                        blurRadius: 12,
                        spreadRadius: 1.5,
                      ),
                    ],
                  ),
                )
                    .animate(delay: const Duration(milliseconds: 300))
                    .scaleY(
                    begin: 0,
                    duration: const Duration(milliseconds: 750),
                    curve: Curves.easeOutQuart)
                    .then()
                    .shimmer(
                    duration: const Duration(milliseconds: 2000),
                    curve: Curves.easeInOutSine),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.58),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      )
                          .animate(delay: const Duration(milliseconds: 400))
                          .fadeIn(duration: const Duration(milliseconds: 700), curve: Curves.easeOutCubic)
                          .slideX(begin: -0.06, curve: Curves.easeOutQuart),
                      const SizedBox(height: 6),
                      Text(
                        _userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                          .animate(delay: const Duration(milliseconds: 480))
                          .fadeIn(duration: const Duration(milliseconds: 700), curve: Curves.easeOutCubic)
                          .slideX(begin: -0.06, curve: Curves.easeOutQuart)
                          .then()
                          .shimmer(
                          duration: const Duration(milliseconds: 2000),
                          curve: Curves.easeInOutSine,
                          color: _kAccentGlow.withOpacity(0.35)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_kAccentGlow.withOpacity(0.28), _kSecondaryGlow.withOpacity(0.28)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.3),
                  ),
                  child: Icon(
                    Icons.emoji_emotions_rounded,
                    color: Colors.white.withOpacity(0.75),
                    size: 26,
                  ),
                )
                    .animate(delay: const Duration(milliseconds: 560))
                    .scale(
                    begin: const Offset(0.6, 0.6),
                    curve: Curves.easeOutBack,
                    duration: const Duration(milliseconds: 650))
                    .fadeIn(curve: Curves.easeOutCubic),
              ],
            ),
          )
              .animate(delay: const Duration(milliseconds: 350))
              .fadeIn(duration: const Duration(milliseconds: 750), curve: Curves.easeOutCubic)
              .slideY(begin: 0.05, curve: Curves.easeOutQuart),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required int delay,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kCardBackground, _kDarkAccent],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: gradientColors[0].withOpacity(0.28), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          splashColor: gradientColors[0].withOpacity(0.1),
          highlightColor: gradientColors[0].withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.35),
                        blurRadius: 16,
                        spreadRadius: 1.5,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.48),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: gradientColors[0].withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_forward_rounded, color: gradientColors[0], size: 19),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: const Duration(milliseconds: 750), curve: Curves.easeOutCubic)
        .slideX(begin: -0.05, curve: Curves.easeOutQuart)
        .then(delay: const Duration(milliseconds: 250))
        .shimmer(
        duration: const Duration(milliseconds: 2000),
        curve: Curves.easeInOutSine,
        color: gradientColors[0].withOpacity(0.2));
  }
}

// Optimized static gradient background widget
class _StaticGradientBackground extends StatelessWidget {
  const _StaticGradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.5),
          radius: 1.5,
          colors: [_kDarkAccent, _kDarkBackground, Color(0xFF05070F)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}