import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Cyberpunk/Hacker themed splash screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Animace pro ikonu (pulse glow)
  late AnimationController _iconController;
  late Animation<double> _iconScale;
  late Animation<double> _iconOpacity;
  late Animation<double> _glowRadius;

  // Animace pro text (fade in slide up)
  late AnimationController _textController;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  // Animace pro progress bar
  late AnimationController _progressController;

  // Glitch efekt
  late Timer _glitchTimer;
  bool _isGlitching = false;
  double _glitchOffsetX = 0;
  double _glitchOffsetY = 0;

  // Data stream text
  final List<String> _dataStreamLines = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();

    // Skryj status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _initAnimations();
    _startGlitchEffect();
    _startDataStream();

    // Auto dismiss po 3 sekundách
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        context.go('/onboarding');
      }
    });
  }

  void _initAnimations() {
    // Icon pulse glow animation (2s loop)
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _iconScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );

    _iconOpacity = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );

    _glowRadius = Tween<double>(begin: 10, end: 30).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );

    // Text fade in slide up (delay 500ms, duration 800ms)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _textController.forward();
    });

    // Progress bar (2.5s)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();
  }

  void _startGlitchEffect() {
    _glitchTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;

      // Náhodně spustit glitch
      if (_random.nextDouble() < 0.15) {
        setState(() {
          _isGlitching = true;
          _glitchOffsetX = (_random.nextDouble() - 0.5) * 10;
          _glitchOffsetY = (_random.nextDouble() - 0.5) * 4;
        });

        // Vypnout glitch po krátké době
        Future.delayed(Duration(milliseconds: 50 + _random.nextInt(100)), () {
          if (mounted) {
            setState(() {
              _isGlitching = false;
              _glitchOffsetX = 0;
              _glitchOffsetY = 0;
            });
          }
        });
      }
    });
  }

  void _startDataStream() {
    Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        // Přidej nový řádek
        _dataStreamLines.add(_generateDataLine());

        // Odeber staré řádky
        if (_dataStreamLines.length > 8) {
          _dataStreamLines.removeAt(0);
        }
      });
    });
  }

  String _generateDataLine() {
    final types = [
      '> LOADING MODULE_${_random.nextInt(999).toString().padLeft(3, '0')}',
      '> DECRYPT: ${_generateHex(8)}',
      '> SYNC: ${_random.nextInt(100)}%',
      '> INIT: system_core_v${_random.nextInt(9)}.${_random.nextInt(9)}',
      '> CONNECT: node_${_random.nextInt(255)}',
      '> AUTH: ****${_generateHex(4)}',
      '> SCAN: port_${_random.nextInt(65535)}',
      '> HACK: ${['SUCCESS', 'PENDING', 'ACTIVE'][_random.nextInt(3)]}',
    ];
    return types[_random.nextInt(types.length)];
  }

  String _generateHex(int length) {
    const chars = '0123456789ABCDEF';
    return List.generate(length, (_) => chars[_random.nextInt(chars.length)])
        .join();
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _glitchTimer.cancel();
    // Obnov status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      body: Stack(
        children: [
          // Dark overlay
          Container(
            color: Colors.black.withAlpha(50),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Hero icon s glow efektem
                SizedBox(height: size.height * 0.15),
                _buildHeroIcon(size),

                const SizedBox(height: 30),

                // Logotype text
                _buildLogotype(),

                const Spacer(),

                // Data stream text
                _buildDataStream(),

                const SizedBox(height: 16),

                // Progress bar s glitch efektem
                _buildGlitchProgressBar(size),

                SizedBox(height: size.height * 0.1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroIcon(Size size) {
    return AnimatedBuilder(
      animation: _iconController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_glitchOffsetX, _glitchOffsetY),
          child: Transform.scale(
            scale: _iconScale.value,
            child: Opacity(
              opacity: _iconOpacity.value,
              child: Container(
                width: size.width * 0.35,
                height: size.width * 0.35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FFFF).withAlpha(150),
                      blurRadius: _glowRadius.value,
                      spreadRadius: _glowRadius.value / 3,
                    ),
                    if (_isGlitching)
                      BoxShadow(
                        color: const Color(0xFFFF0040).withAlpha(100),
                        blurRadius: 20,
                        offset: Offset(_glitchOffsetX * 2, 0),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(size.width * 0.175),
                  child: Image.asset(
                    'assets/images/icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback ikona pokud logo není dostupné
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF00FFFF),
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.bug_report,
                          size: 60,
                          color: Color(0xFF00FFFF),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogotype() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Opacity(
          opacity: _textOpacity.value,
          child: SlideTransition(
            position: _textSlide,
            child: Center(
              child: Transform.translate(
                offset: Offset(_isGlitching ? _glitchOffsetX : 0, 0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glitch layers
                    if (_isGlitching) ...[
                      Transform.translate(
                        offset: const Offset(-2, 0),
                        child: Text(
                          "Buds and Buddies",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'MightySpidey',
                            fontSize: 32,
                            color: const Color(0xFFFF0040).withAlpha(150),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(2, 0),
                        child: Text(
                          "Buds and Buddies",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'MightySpidey',
                            fontSize: 32,
                            color: const Color(0xFF00FFFF).withAlpha(150),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                    // Main text
                    Text(
                      "Buds and Buddies",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'MightySpidey',
                        fontSize: 32,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: const Color(0xFF00FFFF).withAlpha(128),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataStream() {
    return SizedBox(
      height: 120,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: _dataStreamLines.asMap().entries.map((entry) {
            final index = entry.key;
            final line = entry.value;
            final opacity = (index + 1) / _dataStreamLines.length;

            return Opacity(
              opacity: opacity * 0.8,
              child: Text(
                line,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Color(0xFF39FF14),
                  height: 1.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGlitchProgressBar(Size size) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          return Column(
            children: [
              // Progress bar
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1a1a),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Stack(
                  children: [
                    // Fill
                    FractionallySizedBox(
                      widthFactor: _progressController.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF39FF14),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF39FF14).withAlpha(150),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Glitch overlay
                    if (_isGlitching)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFFFF0040).withAlpha(100),
                                Colors.transparent,
                              ],
                              stops: [
                                _progressController.value - 0.1,
                                _progressController.value,
                                _progressController.value + 0.1,
                              ].map((v) => v.clamp(0.0, 1.0)).toList(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Progress text
              Text(
                '${(_progressController.value * 100).toInt()}%',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: const Color(0xFF39FF14).withAlpha(200),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
