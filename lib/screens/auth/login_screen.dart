import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/error_snackbar.dart';

/// Cyberpunk themed login screen
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _glowController;
  late AnimationController _fadeController;
  late Animation<double> _glowAnimation;
  late Animation<double> _fadeAnimation;

  // Cyberpunk colors
  static const Color _cyanPrimary = Color(0xFF00FFFF);
  static const Color _greenAccent = Color(0xFF39FF14);
  static const Color _darkBg = Color(0xFF010A14);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _emailFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _glowController.dispose();
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).signIn(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (mounted) {
        HapticFeedback.heavyImpact();
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.vibrate();
        ErrorSnackbar.show(context, e, action: 'login');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: Stack(
        children: [
          // Blur overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                color: Colors.black.withAlpha(77),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

                        // Logo with glow
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: _cyanPrimary
                                        .withAlpha((200 * _glowAnimation.value).toInt()),
                                    blurRadius: 30 * _glowAnimation.value,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.asset(
                                  'assets/images/icon.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: _cyanPrimary,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.person_outline,
                                        size: 50,
                                        color: _cyanPrimary,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Title with glow
                        Text(
                          "Buds and Buddies",
                          style: TextStyle(
                            fontFamily: 'MightySpidey',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: _cyanPrimary.withAlpha(128),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 48),

                        // Email input
                        _CyberTextField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          hintText: 'E-MAIL',
                          icon: Icons.person_outline,
                          keyboardType: TextInputType.emailAddress,
                          glowAnimation: _glowAnimation,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Zadejte e-mail';
                            }
                            if (!value.contains('@')) {
                              return 'Zadejte platny e-mail';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Password input
                        _CyberTextField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          hintText: 'HESLO',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          glowAnimation: _glowAnimation,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _cyanPrimary.withAlpha(128),
                              size: 20,
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(
                                  () => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Zadejte heslo';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // Forgot password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              context.push('/forgot-password');
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Zapomenute heslo?',
                              style: TextStyle(
                                color: _cyanPrimary,
                                fontSize: 13,
                                fontFamily: 'monospace',
                                decoration: TextDecoration.underline,
                                decorationColor: _cyanPrimary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Login button
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return Container(
                              width: double.infinity,
                              height: 60,
                              decoration: BoxDecoration(
                                color: _greenAccent,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: _greenAccent
                                        .withAlpha((150 * _glowAnimation.value).toInt()),
                                    blurRadius: 20 * _glowAnimation.value,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isLoading ? null : _handleLogin,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              color: Colors.black,
                                            ),
                                          )
                                        : const Text(
                                            'PRIHLASIT',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              fontFamily: 'monospace',
                                              letterSpacing: 3,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Register link
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            context.go('/register');
                          },
                          child: Text(
                            'Novy uzivatel? Registrovat se.',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cyber-styled text field with glow effect
class _CyberTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final Animation<double> glowAnimation;

  const _CyberTextField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.icon,
    required this.glowAnimation,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  static const Color _cyanPrimary = Color(0xFF00FFFF);
  static const Color _darkBg = Color(0xFF010A14);

  @override
  Widget build(BuildContext context) {
    final isFocused = focusNode.hasFocus;

    return AnimatedBuilder(
      animation: glowAnimation,
      builder: (context, child) {
        return Container(
          height: 55,
          decoration: BoxDecoration(
            color: _darkBg.withAlpha(179),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _cyanPrimary,
              width: 2,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color:
                          _cyanPrimary.withAlpha((100 * glowAnimation.value).toInt()),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color:
                          _cyanPrimary.withAlpha((50 * glowAnimation.value).toInt()),
                      blurRadius: 8,
                    ),
                  ],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: _cyanPrimary,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: _cyanPrimary.withAlpha(128),
                fontFamily: 'monospace',
                fontSize: 14,
                letterSpacing: 2,
              ),
              prefixIcon: Icon(
                icon,
                color: _cyanPrimary.withAlpha(isFocused ? 255 : 128),
                size: 22,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              errorStyle: const TextStyle(
                color: Color(0xFFFF0040),
                fontSize: 11,
              ),
            ),
            validator: validator,
          ),
        );
      },
    );
  }
}

/// Animated cyber grid background
class _CyberGridBackground extends StatefulWidget {
  const _CyberGridBackground();

  @override
  State<_CyberGridBackground> createState() => _CyberGridBackgroundState();
}

class _CyberGridBackgroundState extends State<_CyberGridBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
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
          painter: _GridPainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  final double animationValue;

  _GridPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FFFF).withAlpha(25)
      ..strokeWidth = 1;

    const spacing = 40.0;
    final offset = animationValue * spacing;

    // Horizontal lines
    for (double y = -spacing + offset; y < size.height + spacing; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Random glowing dots
    final random = Random(42);
    final dotPaint = Paint()..color = const Color(0xFF00FFFF).withAlpha(100);

    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 2.0 + sin(animationValue * 2 * pi + i) * 1.5;
      canvas.drawCircle(Offset(x, y), radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
