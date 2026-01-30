import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class CalmModeScreen extends StatefulWidget {
  const CalmModeScreen({super.key});

  @override
  State<CalmModeScreen> createState() => _CalmModeScreenState();
}

class _CalmModeScreenState extends State<CalmModeScreen>
    with TickerProviderStateMixin {
  int _currentPhase = 0;
  
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;
  String _breathText = 'NADECHNI SE';
  bool _isInhale = true;
  Timer? _breathTimer;
  int _breathCount = 0;
  
  int _groundingStep = 0;
  final List<Map<String, dynamic>> _groundingSteps = [
    {'emoji': '👀', 'text': 'Najdi 5 věcí, které VIDÍŠ', 'color': Colors.blue},
    {'emoji': '✋', 'text': 'Najdi 4 věci, které můžeš CÍTIT dotykem', 'color': Colors.green},
    {'emoji': '👂', 'text': 'Najdi 3 věci, které SLYŠÍŠ', 'color': Colors.orange},
    {'emoji': '👃', 'text': 'Najdi 2 věci, které CÍTÍŠ (vůně)', 'color': Colors.purple},
    {'emoji': '👅', 'text': 'Najdi 1 věc, kterou CHUTNÁŠ', 'color': Colors.red},
  ];

  final List<String> _affirmations = [
    'Tohle je dočasný stav.\nJsi v bezpečí.',
    'Tvoje tělo to zvládá.\nDýchej.',
    'Nic ti nehrozí.\nJsi v pořádku.',
    'Tohle přejde.\nVšechno je OK.',
    'Jsi silnější než tento moment.',
  ];
  int _currentAffirmation = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _breathController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _breathAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _currentPhase = 1);
      _startBreathing();
    });
  }

  void _startBreathing() {
    _breathController.forward();
    _breathTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _isInhale = !_isInhale;
        _breathText = _isInhale ? 'NADECHNI SE' : 'VYDECHNI';
        if (!_isInhale) _breathCount++;
      });
      
      if (_isInhale) {
        _breathController.forward(from: 0);
      } else {
        _breathController.reverse(from: 1);
      }
      
      if (_breathCount >= 6 && _currentPhase == 1) {
        timer.cancel();
        setState(() => _currentPhase = 2);
      }
    });
  }

  void _nextGroundingStep() {
    HapticFeedback.lightImpact();
    if (_groundingStep < _groundingSteps.length - 1) {
      setState(() => _groundingStep++);
    } else {
      setState(() => _currentPhase = 3);
    }
  }

  void _nextAffirmation() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentAffirmation = (_currentAffirmation + 1) % _affirmations.length;
    });
  }

  void _exitCalmMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _breathTimer?.cancel();
    _breathController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            if (_currentPhase == 2) _nextGroundingStep();
            if (_currentPhase == 3) _nextAffirmation();
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(32),
            child: _buildCurrentPhase(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPhase() {
    switch (_currentPhase) {
      case 0:
        return _buildIntro();
      case 1:
        return _buildBreathing();
      case 2:
        return _buildGrounding();
      case 3:
        return _buildAffirmation();
      default:
        return _buildIntro();
    }
  }

  Widget _buildIntro() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🌙', style: TextStyle(fontSize: 80)),
        const SizedBox(height: 32),
        const Text(
          'Jsi v bezpečí',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Pojď se nadechnout...',
          style: TextStyle(
            color: Colors.white.withAlpha(150),
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBreathing() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _breathAnimation,
          builder: (context, child) {
            return Container(
              width: 200 * _breathAnimation.value,
              height: 200 * _breathAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1B3A4B).withAlpha(200),
                border: Border.all(color: const Color(0xFF3D5A6C), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3D5A6C).withAlpha(100),
                    blurRadius: 30 * _breathAnimation.value,
                    spreadRadius: 10 * _breathAnimation.value,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _breathText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 60),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < _breathCount
                    ? const Color(0xFF3D5A6C)
                    : const Color(0xFF1B3A4B),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        Text(
          'Dech ${_breathCount + 1} z 6',
          style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildGrounding() {
    final step = _groundingSteps[_groundingStep];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(step['emoji'], style: const TextStyle(fontSize: 80)),
        const SizedBox(height: 40),
        Text(
          step['text'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w300,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 60),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_groundingSteps.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: index == _groundingStep ? 24 : 12,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: index <= _groundingStep
                    ? step['color']
                    : const Color(0xFF1B3A4B),
              ),
            );
          }),
        ),
        const SizedBox(height: 60),
        Text(
          'Klepni až budeš mít',
          style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildAffirmation() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('💚', style: TextStyle(fontSize: 60)),
        const SizedBox(height: 40),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Text(
            _affirmations[_currentAffirmation],
            key: ValueKey(_currentAffirmation),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w300,
              height: 1.5,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 60),
        Text(
          'Klepni pro další',
          style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 14),
        ),
        const SizedBox(height: 80),
        GestureDetector(
          onTap: _exitCalmMode,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B3A4B),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFF3D5A6C), width: 1),
            ),
            child: const Text(
              'Je mi líp',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}