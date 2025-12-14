import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flowgenix/presentation/theme/color_palette.dart'; // Note: This import is not used
import 'package:flowgenix/core/services/auth_service.dart';
import 'package:flowgenix/features/dashboards/presentations/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Modern theme colors matching the new design
const Color _kDarkBackground = Color(0xFF0A0E27);
const Color _kDarkAccent = Color(0xFF1A1F3A);
const Color _kCardBackground = Color(0xFF252B48);
const Color _kAccentGlow = Color(0xFF6C5CE7);
const Color _kSecondaryGlow = Color(0xFF00D4FF);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoginView = true;
  late PageController _pageController;
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  bool _isKeyboardVisible = false;
  final GlobalKey _logoKey = GlobalKey();
  final GlobalKey<_TypingParticlesState> _particlesKey = GlobalKey();

  late AnimationController _animationController;
  late Animation<double> _blueBoxHeightAnimation;
  late Animation<double> _whiteBoxHeightAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _logoSizeAnimation;
  late Animation<double> _formFadeSlideAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _usernameFocusNode.addListener(_onFocusChange);
    _emailFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
    _confirmPasswordFocusNode.addListener(_onFocusChange);

    _animationController = AnimationController(
        vsync: this, duration: const Duration(seconds: 4));

    _blueBoxHeightAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 0, end: 1)
              .chain(CurveTween(curve: Curves.fastOutSlowIn)),
          weight: 0.25),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1), weight: 0.41),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1, end: 0.5)
              .chain(CurveTween(curve: Curves.decelerate)),
          weight: 0.33),
    ]).animate(CurvedAnimation(
        parent: _animationController, curve: const Interval(0, 0.75)));

    _whiteBoxHeightAnimation = Tween<double>(begin: 0, end: 0.5).animate(
        CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.5, 0.75, curve: Curves.decelerate)));
    _logoOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.25, 0.35, curve: Curves.fastOutSlowIn)));
    _logoSizeAnimation = Tween<double>(begin: 4, end: 2).animate(
        CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.5, 0.75, curve: Curves.decelerate)));
    _formFadeSlideAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.65, 0.9, curve: Curves.decelerate)));

    _animationController.forward();
  }

  void _onFocusChange() {
    setState(() {
      _isKeyboardVisible = _usernameFocusNode.hasFocus ||
          _emailFocusNode.hasFocus ||
          _passwordFocusNode.hasFocus ||
          _confirmPasswordFocusNode.hasFocus;
    });
  }

  void _onTextChanged(GlobalKey fieldKey) {
    _particlesKey.currentState?.emitParticlesFromField(fieldKey);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _kDarkBackground,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, _) {
            return Stack(
              children: [
                // Typing particles background
                Positioned.fill(
                  child: TypingParticles(key: _particlesKey),
                ),
                // Top box with gradient
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: TopBox(
                    logoKey: _logoKey,
                    blueBoxHeightAnimation: _blueBoxHeightAnimation,
                    commonFadeSlideAnimation: _formFadeSlideAnimation,
                    logoOpacityAnimation: _logoOpacityAnimation,
                    logoSizeAnimation: _logoSizeAnimation,
                    isLoginView: _isLoginView,
                    onLoginTap: () {
                      FocusScope.of(context).unfocus();
                      _pageController.animateToPage(0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut);
                    },
                    onSignupTap: () {
                      FocusScope.of(context).unfocus();
                      _pageController.animateToPage(1,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut);
                    },
                  ),
                ),
                // Bottom box slides up with keyboard
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  bottom: _isKeyboardVisible ? keyboardHeight : 0,
                  left: 0,
                  right: 0,
                  child: BottomBox(
                    whiteBoxHeightAnimation: _whiteBoxHeightAnimation,
                    commonFadeSlideAnimation: _formFadeSlideAnimation,
                    pageController: _pageController,
                    usernameFocusNode: _usernameFocusNode,
                    emailFocusNode: _emailFocusNode,
                    passwordFocusNode: _passwordFocusNode,
                    confirmPasswordFocusNode: _confirmPasswordFocusNode,
                    onTextChanged: _onTextChanged,
                    onPageChanged: (page) {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _isLoginView = page == 0;
                      });
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class Particle {
  Offset position;
  Offset velocity;
  double size;
  double life;
  Color color;

  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.life,
    required this.color,
  });
}

class TypingParticles extends StatefulWidget {
  const TypingParticles({super.key});

  @override
  State<TypingParticles> createState() => _TypingParticlesState();
}

class _TypingParticlesState extends State<TypingParticles>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();
  Duration _lastTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;

    final dt = (_lastTime == Duration.zero)
        ? 16
        : (elapsed - _lastTime).inMilliseconds;
    _lastTime = elapsed;

    setState(() {
      _particles.removeWhere((p) => p.life <= 0);

      for (var particle in _particles) {
        particle.position += particle.velocity * (dt / 16.0);
        particle.life -= 0.015;
        particle.velocity = Offset(
          particle.velocity.dx * 0.98,
          particle.velocity.dy + 0.15,
        );
      }
    });
  }

  void emitParticlesFromField(GlobalKey fieldKey) {
    final RenderBox? fieldBox =
    fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (fieldBox == null) return;

    final fieldPosition = fieldBox.localToGlobal(Offset.zero);
    final fieldSize = fieldBox.size;

    final particleCount = 2 + _random.nextInt(2);
    for (int i = 0; i < particleCount; i++) {
      final x = fieldPosition.dx + _random.nextDouble() * fieldSize.width;
      final y = fieldPosition.dy + fieldSize.height * 0.5;

      final angle = -math.pi / 2 + (_random.nextDouble() - 0.5) * 0.8;
      final speed = _random.nextDouble() * 1.5 + 1.0;

      _particles.add(Particle(
        position: Offset(x, y),
        velocity: Offset(
          math.cos(angle) * speed,
          math.sin(angle) * speed,
        ),
        size: _random.nextDouble() * 2.5 + 1.5,
        life: 1.0,
        color: _random.nextBool()
            ? _kAccentGlow.withOpacity(0.7) // Use withOpacity for clarity
            : _kSecondaryGlow.withOpacity(0.6), // Use withOpacity for clarity
      ));
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ParticlePainter(particles: _particles),
      child: Container(),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      paint.color = particle.color
          .withOpacity(particle.life * 0.7); // Use withOpacity for clarity
      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class BottomBox extends StatelessWidget {
  final Animation<double> whiteBoxHeightAnimation;
  final Animation<double> commonFadeSlideAnimation;
  final PageController pageController;
  final FocusNode usernameFocusNode;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final FocusNode confirmPasswordFocusNode;
  final Function(GlobalKey) onTextChanged;
  final ValueChanged<int> onPageChanged;

  const BottomBox({
    super.key,
    required this.whiteBoxHeightAnimation,
    required this.commonFadeSlideAnimation,
    required this.pageController,
    required this.usernameFocusNode,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.confirmPasswordFocusNode,
    required this.onTextChanged,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
      MediaQuery.of(context).size.height * whiteBoxHeightAnimation.value,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _kCardBackground.withOpacity(0.95),
            _kDarkBackground,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _kAccentGlow.withOpacity(0.2), // Use withOpacity for clarity
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SlideFadeWidget(
        commonFadeSlideAnimation: commonFadeSlideAnimation,
        child: PageView(
          controller: pageController,
          onPageChanged: onPageChanged,
          children: [
            AuthForm(
              isLoginView: true,
              usernameFocusNode: usernameFocusNode,
              emailFocusNode: emailFocusNode,
              passwordFocusNode: passwordFocusNode,
              confirmPasswordFocusNode: confirmPasswordFocusNode,
              onTextChanged: onTextChanged,
            ),
            AuthForm(
              isLoginView: false,
              usernameFocusNode: usernameFocusNode,
              emailFocusNode: emailFocusNode,
              passwordFocusNode: passwordFocusNode,
              confirmPasswordFocusNode: confirmPasswordFocusNode,
              onTextChanged: onTextChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class AuthForm extends StatefulWidget {
  final bool isLoginView;
  final FocusNode usernameFocusNode;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final FocusNode confirmPasswordFocusNode;
  final Function(GlobalKey) onTextChanged;

  const AuthForm({
    super.key,
    required this.isLoginView,
    required this.usernameFocusNode,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.confirmPasswordFocusNode,
    required this.onTextChanged,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  final GlobalKey _usernameFieldKey = GlobalKey();
  final GlobalKey _emailFieldKey = GlobalKey();
  final GlobalKey _passwordFieldKey = GlobalKey();
  final GlobalKey _confirmPasswordFieldKey = GlobalKey();

  // Password visibility toggles
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _usernameController
        .addListener(() => widget.onTextChanged(_usernameFieldKey));
    _emailController.addListener(() => widget.onTextChanged(_emailFieldKey));
    _passwordController
        .addListener(() => widget.onTextChanged(_passwordFieldKey));
    _confirmPasswordController
        .addListener(() => widget.onTextChanged(_confirmPasswordFieldKey));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please enter your email address"),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Password reset email sent to $email"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ));
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = "Failed to send reset email";
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'user-not-found':
              errorMessage = "No account found with this email";
              break;
            case 'invalid-email':
              errorMessage = "Invalid email address";
              break;
            default:
              errorMessage = e.message ?? errorMessage;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please enter both email and password"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (!widget.isLoginView) {
      final username = _usernameController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      if (username.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please enter a username"),
          backgroundColor: Colors.red,
        ));
        return;
      }

      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
        ));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Creating account..."),
          duration: Duration(seconds: 1)));

      final error =
      await _authService.signUpWithEmailAndPassword(email, password);

      if (error == null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updateDisplayName(username);
          await user.reload();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Account created! Verification email sent to $email"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Sign up failed: $error"),
            backgroundColor: Colors.red,
          ));
        }
      }
    } else {
      try {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Logging in..."), duration: Duration(seconds: 1)));

        final user =
        await _authService.signInWithEmailAndPassword(email, password);

        if (user != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("LOGIN SUCCESSFUL! Welcome back."),
              backgroundColor: Colors.green,
            ));

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Login Failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!widget.isLoginView) ...[
              TextField(
                key: _usernameFieldKey,
                controller: _usernameController,
                focusNode: widget.usernameFocusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Username",
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.7)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide:
                    BorderSide(color: _kAccentGlow.withOpacity(0.3)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kAccentGlow, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 25),
            ],
            TextField(
              key: _emailFieldKey,
              controller: _emailController,
              focusNode: widget.emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.7)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _kAccentGlow.withOpacity(0.3)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _kAccentGlow, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 25),
            TextField(
              key: _passwordFieldKey,
              controller: _passwordController,
              focusNode: widget.passwordFocusNode,
              obscureText: !_isPasswordVisible,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.7)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _kAccentGlow.withOpacity(0.3)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _kAccentGlow, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            if (!widget.isLoginView) ...[
              const SizedBox(height: 25),
              TextField(
                key: _confirmPasswordFieldKey,
                controller: _confirmPasswordController,
                focusNode: widget.confirmPasswordFocusNode,
                obscureText: !_isConfirmPasswordVisible,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.7)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide:
                    BorderSide(color: _kAccentGlow.withOpacity(0.3)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _kAccentGlow, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (widget.isLoginView)
              GestureDetector(
                onTap: _handleForgotPassword,
                child: Text(
                  "Forgot your password?",
                  style: TextStyle(
                    color: _kSecondaryGlow.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: _kSecondaryGlow.withOpacity(0.8),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                fixedSize: const Size(double.maxFinite, 54),
                padding: EdgeInsets.zero,
              ),
              onPressed: _handleAuth,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kAccentGlow, _kSecondaryGlow],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _kAccentGlow.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    widget.isLoginView ? 'Log In' : 'Sign Up',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class TopBox extends StatelessWidget {
  final GlobalKey logoKey;
  final Animation<double> blueBoxHeightAnimation;
  final Animation<double> commonFadeSlideAnimation;
  final Animation<double> logoOpacityAnimation;
  final Animation<double> logoSizeAnimation;
  final bool isLoginView;
  final VoidCallback onLoginTap;
  final VoidCallback onSignupTap;

  const TopBox({
    super.key,
    required this.logoKey,
    required this.blueBoxHeightAnimation,
    required this.commonFadeSlideAnimation,
    required this.logoOpacityAnimation,
    required this.logoSizeAnimation,
    required this.isLoginView,
    required this.onLoginTap,
    required this.onSignupTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * blueBoxHeightAnimation.value,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.3),
          radius: 1.5,
          colors: [
            _kDarkAccent,
            _kDarkBackground,
            const Color(0xFF05070F),
          ],
        ),
      ),
      alignment: Alignment.bottomCenter,
      child: Column(
        children: [
          const Spacer(),
          Logo(
              logoKey: logoKey,
              logoOpacityAnimation: logoOpacityAnimation,
              logoSizeAnimation: logoSizeAnimation),
          const Spacer(),
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideFadeWidget(
              commonFadeSlideAnimation: commonFadeSlideAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onLoginTap,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "LOG IN",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isLoginView ? Colors.white : Colors.white60,
                            fontSize: isLoginView ? 27 : 15,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (isLoginView)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            height: 3,
                            width: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_kAccentGlow, _kSecondaryGlow],
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: _kAccentGlow.withOpacity(0.6),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // This was the missing block
                  GestureDetector(
                    onTap: onSignupTap,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "SIGN UP",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !isLoginView ? Colors.white : Colors.white60,
                            fontSize: !isLoginView ? 27 : 15,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (!isLoginView)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            height: 3,
                            width: 70,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_kAccentGlow, _kSecondaryGlow],
                              ),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: _kAccentGlow.withOpacity(0.6),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Logo extends StatelessWidget {
  final GlobalKey logoKey;
  final Animation<double> logoOpacityAnimation;
  final Animation<double> logoSizeAnimation;

  const Logo(
      {super.key,
        required this.logoKey,
        required this.logoOpacityAnimation,
        required this.logoSizeAnimation});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "flowgenix_logo_hero",
      child: Opacity(
        opacity: logoOpacityAnimation.value,
        child: Transform.scale(
          scale: logoSizeAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _kAccentGlow.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: _kSecondaryGlow.withOpacity(0.2),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Image.asset(
              key: logoKey,
              'assets/images/FlowGenix_logo.png',
              height: 150,
            ),
          ),
        ),
      ),
    );
  }
}

class SlideFadeWidget extends StatelessWidget {
  final Animation<double> commonFadeSlideAnimation;
  final Widget child;

  const SlideFadeWidget(
      {super.key,
        required this.commonFadeSlideAnimation,
        required this.child});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, 100 * (1 - commonFadeSlideAnimation.value)),
      child: Opacity(opacity: commonFadeSlideAnimation.value, child: child),
    );
  }
}