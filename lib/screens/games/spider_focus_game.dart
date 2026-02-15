import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math';
import '../../theme/theme.dart';

class SpiderFocusGame extends StatefulWidget {
  const SpiderFocusGame({super.key});

  @override
  State<SpiderFocusGame> createState() => _SpiderFocusGameState();
}

class _SpiderFocusGameState extends State<SpiderFocusGame> with TickerProviderStateMixin {
  // Game state
  bool _isPlaying = false;
  bool _isBreathingIn = true;
  bool _gameCompleted = false;
  
  // Level & scoring
  int _currentLevel = 1;
  int _score = 0;
  int _totalXP = 0;
  int _targetHits = 0;
  int _targetMisses = 0;
  
  // Timing
  int _timeLeft = 45;
  int _targetPosition = -1;
  
  // Timers
  Timer? _gameTimer;
  Timer? _breathTimer;
  Timer? _targetTimer;
  
  // Animation
  late AnimationController _breathController;
  late AnimationController _pulseController;
  final Random _random = Random();

  // Level settings
  int get _targetSpeed => (1800 - (_currentLevel * 200)).clamp(600, 1800);
  int get _levelTime => (50 - (_currentLevel * 5)).clamp(30, 50);
  int get _hitsNeeded => 5 + _currentLevel * 2;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _breathTimer?.cancel();
    _targetTimer?.cancel();
    _breathController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startLevel() {
    setState(() {
      _isPlaying = true;
      _timeLeft = _levelTime;
      _targetHits = 0;
      _targetMisses = 0;
      _targetPosition = _random.nextInt(9);
    });

    _breathController.repeat(reverse: true);

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _endLevel(success: false);
        }
      });
    });

    _breathTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      setState(() => _isBreathingIn = !_isBreathingIn);
    });

    _spawnTarget();
  }

  void _spawnTarget() {
    _targetTimer?.cancel();
    _targetTimer = Timer.periodic(Duration(milliseconds: _targetSpeed), (timer) {
      if (!_isPlaying) return;
      setState(() {
        // Penalizace za zmeškaný target
        if (_targetPosition >= 0) {
          _targetMisses++;
        }
        _targetPosition = _random.nextInt(9);
      });
    });
  }

  void _onTap(int position) {
    if (!_isPlaying || _targetPosition < 0) return;

    if (position == _targetPosition) {
      // Správný hit
      _pulseController.forward().then((_) => _pulseController.reverse());
      
      setState(() {
        _score += 10 * _currentLevel;
        _targetHits++;
        _targetPosition = -1; // Skryj target
      });

      // Spawn nový target rychleji jako odměna
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_isPlaying && mounted) {
          setState(() => _targetPosition = _random.nextInt(9));
        }
      });

      // Check level complete
      if (_targetHits >= _hitsNeeded) {
        _endLevel(success: true);
      }
    } else {
      // Špatný tap
      setState(() {
        _score = max(0, _score - 5);
        _targetMisses++;
      });
    }
  }

  void _endLevel({required bool success}) {
    _gameTimer?.cancel();
    _breathTimer?.cancel();
    _targetTimer?.cancel();
    _breathController.stop();
    _targetPosition = -1;

    setState(() => _isPlaying = false);

    if (success) {
      final xpEarned = 30 * _currentLevel;
      _totalXP += xpEarned;

      if (_currentLevel >= 5) {
        setState(() => _gameCompleted = true);
        return;
      }

      _showLevelCompleteDialog(xpEarned);
    } else {
      _showLevelFailedDialog();
    }
  }

  void _showLevelCompleteDialog(int xpEarned) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.functionalSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Text('🕸️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              'Level $_currentLevel dokončen!',
              style: const TextStyle(color: Colors.white, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lezeš výš po pavučině!',
              style: TextStyle(color: AppColors.functionalMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildStatRow('Zásahy', '$_targetHits / $_hitsNeeded'),
            _buildStatRow('Přesnost', '${((_targetHits / max(1, _targetHits + _targetMisses)) * 100).toInt()}%'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.tealAccent.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    '+$xpEarned XP',
                    style: const TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _currentLevel++);
                _startLevel();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Level ${_currentLevel + 1} - Výš! 🕷️',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLevelFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.functionalSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Text('😮‍💨', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            const Text(
              'Čas vypršel',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Zhluboka se nadechni a zkus to znovu.',
              style: TextStyle(color: AppColors.functionalMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildStatRow('Zásahy', '$_targetHits / $_hitsNeeded'),
            _buildStatRow('Chybí', '${_hitsNeeded - _targetHits}'),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.pop();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.tealAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Zavřít', style: TextStyle(color: Colors.tealAccent)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _startLevel();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Znovu', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.functionalMuted)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_gameCompleted) return _buildGameCompleteScreen();
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            _gameTimer?.cancel();
            _breathTimer?.cancel();
            _targetTimer?.cancel();
            context.pop();
          },
        ),
        title: _isPlaying 
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Level $_currentLevel', style: const TextStyle(color: Colors.white, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _timeLeft <= 10 ? Colors.red.withAlpha(50) : Colors.tealAccent.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '⏱️ $_timeLeft s',
                      style: TextStyle(
                        color: _timeLeft <= 10 ? Colors.red : Colors.tealAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🕷️ $_score',
                      style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              )
            : const Text('Spider Focus', style: TextStyle(color: Colors.white)),
      ),
      body: _isPlaying ? _buildGame() : _buildStart(),
    );
  }

  Widget _buildStart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Spider web icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.tealAccent.withAlpha(100), width: 2),
              ),
              child: const Center(
                child: Text('🕷️', style: TextStyle(fontSize: 60)),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Spider Focus',
              style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Dechová hra pro zklidnění',
              style: TextStyle(fontSize: 16, color: AppColors.functionalMuted),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.functionalSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildInfoRow('🎯', 'Klikej na zelené cíle'),
                  const SizedBox(height: 12),
                  _buildInfoRow('🌬️', 'Dýchej s kruhem'),
                  const SizedBox(height: 12),
                  _buildInfoRow('🕸️', 'Lezeš výš po každém levelu'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ideální když:\n• se ti dělá divně\n• máš overthink\n• čekáš na efekt',
              style: TextStyle(color: AppColors.functionalMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startLevel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'START',
                  style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildGame() {
    return Column(
      children: [
        const SizedBox(height: 10),
        
        // Web progress
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pavučina', style: TextStyle(color: AppColors.functionalMuted, fontSize: 12)),
                  Text('$_targetHits / $_hitsNeeded', style: const TextStyle(color: Colors.tealAccent, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _targetHits / _hitsNeeded,
                  backgroundColor: AppColors.functionalSurface,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.tealAccent),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Breathing indicator
        Text(
          _isBreathingIn ? '🌬️ NADECH...' : '💨 VÝDECH...',
          style: TextStyle(
            fontSize: 22,
            color: _isBreathingIn ? Colors.tealAccent : Colors.orangeAccent,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Breathing circle
        AnimatedBuilder(
          animation: _breathController,
          builder: (context, child) {
            return Container(
              width: 80 + (_breathController.value * 40),
              height: 80 + (_breathController.value * 40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.tealAccent.withAlpha(50),
                border: Border.all(color: Colors.tealAccent, width: 3),
              ),
              child: const Center(
                child: Text('🕷️', style: TextStyle(fontSize: 30)),
              ),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // Target grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final isTarget = index == _targetPosition;
                return GestureDetector(
                  onTap: () => _onTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isTarget ? Colors.tealAccent : AppColors.functionalSurface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isTarget ? [
                        BoxShadow(
                          color: Colors.tealAccent.withAlpha(100),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ] : null,
                    ),
                    child: isTarget
                        ? const Center(
                            child: Icon(Icons.touch_app, color: Colors.black, size: 40),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameCompleteScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🕸️', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 8),
                const Text('🕷️', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 24),
                const Text(
                  'Na vrcholu!',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dokončil jsi všechny levely!',
                  style: TextStyle(color: AppColors.functionalMuted, fontSize: 16),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.functionalSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text('Celkové skóre', style: TextStyle(color: AppColors.functionalMuted)),
                      const SizedBox(height: 8),
                      Text(
                        '$_score bodů',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.tealAccent.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Text(
                              '+$_totalXP XP',
                              style: const TextStyle(
                                color: Colors.tealAccent,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.tealAccent),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Zavřít', style: TextStyle(color: Colors.tealAccent)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentLevel = 1;
                            _score = 0;
                            _totalXP = 0;
                            _gameCompleted = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Hrát znovu',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}