import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../theme/theme.dart';

class PassTimerGame extends StatefulWidget {
  const PassTimerGame({super.key});

  @override
  State<PassTimerGame> createState() => _PassTimerGameState();
}

class _PassTimerGameState extends State<PassTimerGame> with TickerProviderStateMixin {
  // Settings
  int _selectedTime = 45; // default 45s
  final List<int> _timeOptions = [30, 45, 60, 90];
  
  // State
  bool _isRunning = false;
  bool _isPaused = false;
  int _timeLeft = 45;
  int _roundCount = 0;
  int _totalPasses = 0;
  
  // Timer
  Timer? _timer;
  late AnimationController _pulseController;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _timeLeft = _selectedTime;
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: Duration(seconds: _selectedTime),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _timeLeft = _selectedTime;
    });

    _progressController.duration = Duration(seconds: _selectedTime);
    _progressController.forward(from: 0);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
        
        // Vibrace v posledních 5 sekundách
        if (_timeLeft <= 5 && _timeLeft > 0) {
          HapticFeedback.mediumImpact();
          _pulseController.forward().then((_) => _pulseController.reverse());
        }
        
        if (_timeLeft <= 0) {
          _onTimeUp();
        }
      });
    });
  }

  void _onTimeUp() {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    
    // Vibrace pattern
    Future.delayed(const Duration(milliseconds: 200), () => HapticFeedback.heavyImpact());
    Future.delayed(const Duration(milliseconds: 400), () => HapticFeedback.heavyImpact());

    setState(() {
      _totalPasses++;
    });

    _showPassDialog();
  }

  void _showPassDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.functionalSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Text('🔄', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            const Text(
              'PASS!',
              style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Čas vypršel - předej dál!',
          style: TextStyle(color: AppColors.functionalMuted, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _startTimer(); // Automaticky spustí pro dalšího
              },
              icon: const Text('👉', style: TextStyle(fontSize: 20)),
              label: const Text(
                'Další v kruhu',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isRunning = false;
                  _roundCount++;
                  _timeLeft = _selectedTime;
                });
                _progressController.reset();
              },
              child: Text(
                'Konec kola (celkem $_totalPasses předání)',
                style: TextStyle(color: AppColors.functionalMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pauseTimer() {
    _timer?.cancel();
    _progressController.stop();
    setState(() => _isPaused = true);
  }

  void _resumeTimer() {
    setState(() => _isPaused = false);
    _progressController.forward();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 5 && _timeLeft > 0) {
          HapticFeedback.mediumImpact();
          _pulseController.forward().then((_) => _pulseController.reverse());
        }
        if (_timeLeft <= 0) {
          _onTimeUp();
        }
      });
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _progressController.reset();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _timeLeft = _selectedTime;
    });
  }

  void _setTime(int seconds) {
    if (_isRunning) return;
    setState(() {
      _selectedTime = seconds;
      _timeLeft = seconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        backgroundColor: AppColors.functionalBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            _timer?.cancel();
            context.pop();
          },
        ),
        title: const Text('Pass Timer', style: TextStyle(color: Colors.white)),
        actions: [
          if (_totalPasses > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Text('🔄', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '$_totalPasses',
                    style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Time selection (only when not running)
              if (!_isRunning) ...[
                Text(
                  'Čas na osobu',
                  style: TextStyle(color: AppColors.functionalMuted, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _timeOptions.map((time) {
                    final isSelected = _selectedTime == time;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: GestureDetector(
                        onTap: () => _setTime(time),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.orangeAccent : AppColors.functionalSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.orangeAccent : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            '${time}s',
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
              ],

              const Spacer(),

              // Timer circle
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.1);
                  return Transform.scale(
                    scale: _timeLeft <= 5 ? scale : 1.0,
                    child: child,
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 12,
                        backgroundColor: AppColors.functionalSurface,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.functionalSurface),
                      ),
                    ),
                    // Progress circle
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, _) {
                          return CircularProgressIndicator(
                            value: _isRunning ? (1 - _progressController.value) : 1.0,
                            strokeWidth: 12,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _timeLeft <= 5 ? Colors.red : Colors.orangeAccent,
                            ),
                          );
                        },
                      ),
                    ),
                    // Time display
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _timeLeft <= 5 && _isRunning ? '🔥' : '🌿',
                          style: const TextStyle(fontSize: 40),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_timeLeft',
                          style: TextStyle(
                            color: _timeLeft <= 5 ? Colors.red : Colors.white,
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'sekund',
                          style: TextStyle(
                            color: AppColors.functionalMuted,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Controls
              if (!_isRunning) ...[
                // Start button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startTimer,
                    icon: const Icon(Icons.play_arrow, color: Colors.black),
                    label: const Text(
                      'START',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ] else ...[
                // Pause/Resume and Reset
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isPaused ? _resumeTimer : _pauseTimer,
                        icon: Icon(
                          _isPaused ? Icons.play_arrow : Icons.pause,
                          color: Colors.black,
                        ),
                        label: Text(
                          _isPaused ? 'Pokračovat' : 'Pauza',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetTimer,
                        icon: const Icon(Icons.refresh, color: Colors.orangeAccent),
                        label: const Text(
                          'Reset',
                          style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orangeAccent),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Quick pass
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      _timer?.cancel();
                      setState(() => _totalPasses++);
                      _startTimer();
                    },
                    icon: const Text('👉', style: TextStyle(fontSize: 18)),
                    label: Text(
                      'Předat teď',
                      style: TextStyle(color: AppColors.functionalMuted),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Stats
              if (_roundCount > 0 || _totalPasses > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.functionalSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('🔄', 'Předání', _totalPasses),
                      _buildStat('⭕', 'Kola', _roundCount),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String emoji, String label, int value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: AppColors.functionalMuted, fontSize: 12)),
      ],
    );
  }
}