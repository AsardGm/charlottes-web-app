import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/theme.dart';
import '../../services/app_initializer.dart';

/// Enhanced splash screen with initialization progress
class EnhancedSplashScreen extends StatefulWidget {
  const EnhancedSplashScreen({super.key});

  @override
  State<EnhancedSplashScreen> createState() => _EnhancedSplashScreenState();
}

class _EnhancedSplashScreenState extends State<EnhancedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  String _statusMessage = 'Inicializace...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  Future<void> _initializeApp() async {
    final initializer = AppInitializer();

    try {
      // Initialize app services
      await initializer.initialize();

      // Check authentication
      final user = Supabase.instance.client.auth.currentUser;

      // Small delay for smooth transition
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        if (user != null) {
          context.go('/dashboard');
        } else {
          context.go('/auth');
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Chyba při inicializaci';
      });

      // Show error for a moment, then try to continue
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        final user = Supabase.instance.client.auth.currentUser;
        context.go(user != null ? '/dashboard' : '/auth');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo/icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 3,
                  ),
                ),
                child: Icon(
                  Icons.spa,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              // App name
              const Text(
                "Charlotte's Web",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              // Tagline
              Text(
                'Tvůj osobní průvodce',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 48),

              // Progress indicator
              SizedBox(
                width: 200,
                child: Column(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),

              // Version info
              Text(
                'Verze 1.0.0',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
