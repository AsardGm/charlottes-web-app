import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/theme.dart';

class TerpeneMatchGame extends StatefulWidget {
  const TerpeneMatchGame({super.key});

  @override
  State<TerpeneMatchGame> createState() => _TerpeneMatchGameState();
}

class _TerpeneMatchGameState extends State<TerpeneMatchGame> {
  // Všechny terpeny s efekty a popisy
  final List<Map<String, String>> _allTerpenes = [
    {'name': 'Myrcene', 'effect': 'Relaxace', 'emoji': '😌', 'desc': 'Uklidňuje tělo i mysl'},
    {'name': 'Limonene', 'effect': 'Energie', 'emoji': '⚡', 'desc': 'Povzbuzuje a zlepšuje náladu'},
    {'name': 'Pinene', 'effect': 'Fokus', 'emoji': '🎯', 'desc': 'Zvyšuje koncentraci a paměť'},
    {'name': 'Linalool', 'effect': 'Spánek', 'emoji': '😴', 'desc': 'Pomáhá s usínáním'},
    {'name': 'Caryophyllene', 'effect': 'Úleva', 'emoji': '💆', 'desc': 'Tlumí bolest a zánět'},
    {'name': 'Humulene', 'effect': 'Apetit', 'emoji': '🍽️', 'desc': 'Potlačuje hlad'},
    {'name': 'Terpinolene', 'effect': 'Kreativita', 'emoji': '🎨', 'desc': 'Stimuluje kreativní myšlení'},
    {'name': 'Ocimene', 'effect': 'Ochrana', 'emoji': '🛡️', 'desc': 'Antibakteriální účinky'},
  ];

  int _currentLevel = 1;
  int _score = 0;
  int _totalXP = 0;
  String? _selectedTerpene;
  String? _feedback;
  bool _isAnswered = false;
  bool _showingResult = false;
  bool _gameCompleted = false;
  
  List<Map<String, String>> _currentTerpenes = [];
  final Set<String> _matchedTerpenes = {};

  @override
  void initState() {
    super.initState();
    _setupLevel();
  }

  void _setupLevel() {
    setState(() {
      // Každý level přidá více terpenů
      final count = (_currentLevel + 2).clamp(3, _allTerpenes.length);
      _currentTerpenes = _allTerpenes.sublist(0, count);
      _matchedTerpenes.clear();
      _selectedTerpene = null;
      _feedback = null;
      _isAnswered = false;
    });
  }

  void _checkAnswer(String terpene, String effect) {
    if (_isAnswered || _matchedTerpenes.contains(terpene)) return;

    final correct = _currentTerpenes.firstWhere((t) => t['name'] == terpene)['effect'] == effect;
    
    setState(() {
      _isAnswered = true;
      if (correct) {
        _score += 10 * _currentLevel;
        _matchedTerpenes.add(terpene);
        _feedback = 'Správně! +${10 * _currentLevel} bodů';
        
        // Zkontroluj jestli jsou všechny spárované
        if (_matchedTerpenes.length >= _currentTerpenes.length) {
          _showLevelComplete();
        }
      } else {
        _feedback = 'Špatně! Zkus to znovu';
      }
    });

    // Reset pro další odpověď
    if (correct) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !_showingResult) {
          setState(() {
            _selectedTerpene = null;
            _isAnswered = false;
            _feedback = null;
          });
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _isAnswered = false;
            _feedback = null;
          });
        }
      });
    }
  }

  void _showLevelComplete() {
    _showingResult = true;
    final xpEarned = 50 * _currentLevel;
    _totalXP += xpEarned;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      // Pokud je poslední level
      if (_currentLevel >= 5) {
        setState(() => _gameCompleted = true);
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.functionalSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              const Text('🌿', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(
                'Level $_currentLevel dokončen!',
                style: const TextStyle(color: Colors.white, fontSize: 22),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Postupuješ hlouběji do světa terpenů!',
                style: TextStyle(color: AppColors.functionalMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      '+$xpEarned XP',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Celkem: $_totalXP XP',
                style: TextStyle(color: AppColors.functionalMuted),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentLevel++;
                    _showingResult = false;
                  });
                  _setupLevel();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Level ${_currentLevel + 1} →',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_gameCompleted) {
      return _buildGameCompleteScreen();
    }

    final progress = _matchedTerpenes.length / _currentTerpenes.length;

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        backgroundColor: AppColors.functionalBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Text(
              'Level $_currentLevel',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '$_score',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hloubka poznání',
                        style: TextStyle(color: AppColors.functionalMuted, fontSize: 12),
                      ),
                      Text(
                        '${_matchedTerpenes.length}/${_currentTerpenes.length}',
                        style: TextStyle(color: AppColors.accent, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.functionalSurface,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Instrukce
              Text(
                _selectedTerpene == null 
                    ? '1. Vyber terpen' 
                    : '2. Jaký má $_selectedTerpene efekt?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 20),

              // Terpeny
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _currentTerpenes.map((t) {
                  final isMatched = _matchedTerpenes.contains(t['name']);
                  final isSelected = _selectedTerpene == t['name'];
                  
                  return GestureDetector(
                    onTap: isMatched ? null : () => setState(() => _selectedTerpene = t['name']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isMatched 
                            ? AppColors.accent.withAlpha(40)
                            : isSelected 
                                ? AppColors.accent 
                                : AppColors.functionalSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isMatched 
                              ? AppColors.accent 
                              : isSelected 
                                  ? AppColors.accent 
                                  : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isMatched) ...[
                            const Icon(Icons.check_circle, color: Colors.green, size: 18),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            t['name']!,
                            style: TextStyle(
                              color: isMatched 
                                  ? AppColors.accent 
                                  : isSelected 
                                      ? Colors.black 
                                      : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),

              // Efekty (zobrazí se po výběru terpenu)
              if (_selectedTerpene != null && !_matchedTerpenes.contains(_selectedTerpene)) ...[
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _currentTerpenes.map((t) {
                    return ElevatedButton.icon(
                      onPressed: _isAnswered ? null : () => _checkAnswer(_selectedTerpene!, t['effect']!),
                      icon: Text(t['emoji']!, style: const TextStyle(fontSize: 18)),
                      label: Text(t['effect']!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.functionalSurface,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const Spacer(),

              // Feedback
              if (_feedback != null)
                Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: _feedback!.contains('Správně') 
                          ? Colors.green.withAlpha(40) 
                          : Colors.red.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _feedback!,
                      style: TextStyle(
                        color: _feedback!.contains('Správně') ? Colors.green : Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCompleteScreen() {
    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 24),
                const Text(
                  'Gratulace!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Jsi Terpene Master!',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 20,
                  ),
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
                      Text(
                        'Celkové skóre',
                        style: TextStyle(color: AppColors.functionalMuted),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_score bodů',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Text(
                              '+$_totalXP XP získáno!',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 20,
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
                          side: BorderSide(color: AppColors.accent),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Zavřít',
                          style: TextStyle(color: AppColors.accent),
                        ),
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
                          _setupLevel();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Hrát znovu',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
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