import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/error_snackbar.dart';

/// Cyberpunk themed register screen
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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

    _usernameFocusNode.addListener(_onFocusChange);
    _emailFocusNode.addListener(_onFocusChange);
    _passwordFocusNode.addListener(_onFocusChange);
    _confirmPasswordFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _glowController.dispose();
    _fadeController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).signUp(
            _emailController.text.trim(),
            _passwordController.text,
            _usernameController.text.trim(),
          );
      if (mounted) {
        HapticFeedback.heavyImpact();
        ErrorSnackbar.showSuccess(context, 'Registrace uspesna! Prihlaste se.');
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.vibrate();
        ErrorSnackbar.show(context, e, action: 'register');
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
                        const SizedBox(height: 20),

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
                                    blurRadius: 25 * _glowAnimation.value,
                                    spreadRadius: 4,
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
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      child: const Icon(
                                        Icons.person_add_outlined,
                                        size: 60,
                                        color: _cyanPrimary,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Title with glow
                        Text(
                          "Buds and Buddies",
                          style: TextStyle(
                            fontFamily: 'MightySpidey',
                            fontSize: 24,
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

                        const SizedBox(height: 32),

                        // Username input
                        _CyberTextField(
                          controller: _usernameController,
                          focusNode: _usernameFocusNode,
                          hintText: 'UZIVATELSKE JMENO',
                          icon: Icons.person_outline,
                          glowAnimation: _glowAnimation,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Zadejte uzivatelske jmeno';
                            }
                            if (value.length < 3) {
                              return 'Min 3 znaky';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 15),

                        // Email input
                        _CyberTextField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          hintText: 'E-MAIL',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          glowAnimation: _glowAnimation,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Zadejte e-mail';
                            }
                            if (!value.contains('@')) {
                              return 'Neplatny e-mail';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 15),

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
                            if (value.length < 6) {
                              return 'Min 6 znaku';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 15),

                        // Confirm password input
                        _CyberTextField(
                          controller: _confirmPasswordController,
                          focusNode: _confirmPasswordFocusNode,
                          hintText: 'POTVRDIT HESLO',
                          icon: Icons.lock_outline,
                          obscureText: _obscureConfirmPassword,
                          glowAnimation: _glowAnimation,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _cyanPrimary.withAlpha(128),
                              size: 20,
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(() => _obscureConfirmPassword =
                                  !_obscureConfirmPassword);
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Potvrdte heslo';
                            }
                            if (value != _passwordController.text) {
                              return 'Hesla se neshoduji';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // Register button
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
                                  onTap: _isLoading ? null : _handleRegister,
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
                                            'REGISTROVAT',
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

                        const SizedBox(height: 20),

                        // Login link
                        TextButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            context.go('/login');
                          },
                          child: Text(
                            'Mate ucet? Prihlasit se.',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
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
          height: 50,
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
                fontSize: 13,
                letterSpacing: 1,
              ),
              prefixIcon: Icon(
                icon,
                color: _cyanPrimary.withAlpha(isFocused ? 255 : 128),
                size: 20,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              errorStyle: const TextStyle(
                color: Color(0xFFFF0040),
                fontSize: 10,
              ),
            ),
            validator: validator,
          ),
        );
      },
    );
  }
}
