import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme/theme.dart';

/// Obrazovka pro reset hesla
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

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
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _glowController.dispose();
    _fadeController.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService();
      await authService.resetPassword(_emailController.text.trim());

      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.vibrate();
        setState(() {
          _errorMessage = _parseError(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  String _parseError(String error) {
    if (error.contains('rate limit')) {
      return 'Prilis mnoho pokusu. Zkuste to pozdeji.';
    }
    if (error.contains('invalid')) {
      return 'Neplatna emailova adresa.';
    }
    return 'Nastala chyba. Zkuste to znovu.';
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
                  child: _emailSent ? _buildSuccessContent() : _buildFormContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Success icon
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _greenAccent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _greenAccent.withAlpha((150 * _glowAnimation.value).toInt()),
                    blurRadius: 20 * _glowAnimation.value,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 48,
                color: _greenAccent,
              ),
            );
          },
        ),

        const SizedBox(height: 32),

        // Success title
        Text(
          'EMAIL ODESLAN',
          style: TextStyle(
            fontFamily: 'MightySpidey',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: _greenAccent.withAlpha(128),
                blurRadius: 10,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Success message
        Text(
          'Na adresu ${_emailController.text} jsme odeslali odkaz pro reset hesla. Zkontrolujte svou emailovou schranku.',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
            fontFamily: 'monospace',
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          'Odkaz je platny 1 hodinu.',
          style: TextStyle(
            color: _cyanPrimary.withAlpha(150),
            fontSize: 12,
            fontFamily: 'monospace',
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 40),

        // Back to login button
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: _cyanPrimary,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: _cyanPrimary.withAlpha((100 * _glowAnimation.value).toInt()),
                    blurRadius: 15 * _glowAnimation.value,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.go('/login');
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: const Center(
                    child: Text(
                      'ZPET NA PRIHLASENI',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Resend link
        TextButton(
          onPressed: () {
            setState(() => _emailSent = false);
          },
          child: Text(
            'Neprisel email? Zkusit znovu',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.go('/login');
              },
              icon: const Icon(
                Icons.arrow_back,
                color: _cyanPrimary,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Icon
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _cyanPrimary,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _cyanPrimary.withAlpha((100 * _glowAnimation.value).toInt()),
                      blurRadius: 20 * _glowAnimation.value,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_reset_outlined,
                  size: 48,
                  color: _cyanPrimary,
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            'RESET HESLA',
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

          const SizedBox(height: 16),

          // Subtitle
          Text(
            'Zadejte svuj email a my vam posleme odkaz pro nastaveni noveho hesla.',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              fontFamily: 'monospace',
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Error message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.error.withAlpha(100),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),

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
              if (!value.contains('@') || !value.contains('.')) {
                return 'Zadejte platny e-mail';
              }
              return null;
            },
          ),

          const SizedBox(height: 40),

          // Submit button
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
                      color: _greenAccent.withAlpha((150 * _glowAnimation.value).toInt()),
                      blurRadius: 20 * _glowAnimation.value,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _handleResetPassword,
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
                              'ODESLAT ODKAZ',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                letterSpacing: 2,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Back to login link
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              context.go('/login');
            },
            child: Text(
              'Zpet na prihlaseni',
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
    );
  }
}

/// Cyber-styled text field with glow effect
class _CyberTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Animation<double> glowAnimation;

  const _CyberTextField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.icon,
    required this.glowAnimation,
    this.keyboardType,
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
                      color: _cyanPrimary.withAlpha((100 * glowAnimation.value).toInt()),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: _cyanPrimary.withAlpha((50 * glowAnimation.value).toInt()),
                      blurRadius: 8,
                    ),
                  ],
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
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
