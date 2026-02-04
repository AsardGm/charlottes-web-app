import 'package:flutter/material.dart';

class TerpeneMatchGame extends StatefulWidget {
  const TerpeneMatchGame({super.key});

  @override
  State<TerpeneMatchGame> createState() => _TerpeneMatchGameState();
}

class _TerpeneMatchGameState extends State<TerpeneMatchGame> {
  final List<Map<String, String>> _terpenes = [
    {'name': 'Myrcene', 'effect': 'Relaxace'},
    {'name': 'Limonene', 'effect': 'Energie'},
    {'name': 'Pinene', 'effect': 'Fokus'},
    {'name': 'Linalool', 'effect': 'Spanek'},
  ];

  int _score = 0;
  String? _selectedTerpene;
  String? _feedback;

  void _checkAnswer(String terpene, String effect) {
    final correct = _terpenes.firstWhere((t) => t['name'] == terpene)['effect'] == effect;
    setState(() {
      if (correct) {
        _score += 10;
        _feedback = 'Spravne!';
      } else {
        _feedback = 'Zkus znovu';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Terpene Match - Skore: $_score')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Vyber terpen a pak jeho efekt', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _terpenes.map((t) => ChoiceChip(
                label: Text(t['name']!),
                selected: _selectedTerpene == t['name'],
                onSelected: (_) => setState(() => _selectedTerpene = t['name']),
              )).toList(),
            ),
            const SizedBox(height: 24),
            if (_selectedTerpene != null) ...[
              const Text('Jaky ma efekt?'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _terpenes.map((t) => ElevatedButton(
                  onPressed: () => _checkAnswer(_selectedTerpene!, t['effect']!),
                  child: Text(t['effect']!),
                )).toList(),
              ),
            ],
            if (_feedback != null) ...[
              const SizedBox(height: 24),
              Text(_feedback!, style: const TextStyle(fontSize: 24)),
            ],
          ],
        ),
      ),
    );
  }
}