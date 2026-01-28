import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/daily_checkin_model.dart';
import '../../services/checkin_service.dart';

class DailyCheckinScreen extends ConsumerStatefulWidget {
  const DailyCheckinScreen({super.key});

  @override
  ConsumerState<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends ConsumerState<DailyCheckinScreen> {
  final CheckinService _checkinService = CheckinService();
  
  int _mood = 3;
  int _energy = 3;
  int _focus = 3;
  BodyState _bodyState = BodyState.ok;
  bool? _plantContact;
  bool _isLoading = false;
  String? _insight;

  Future<void> _submitCheckin() async {
    setState(() => _isLoading = true);
    
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final checkin = DailyCheckin(
      userId: userId,
      mood: _mood,
      energy: _energy,
      focus: _focus,
      bodyState: _bodyState,
      plantContact: _plantContact,
    );

    final insight = _checkinService.generateInsight(checkin);
    final savedCheckin = await _checkinService.saveCheckin(
      checkin.copyWith(insight: insight),
    );

    setState(() {
      _isLoading = false;
      _insight = insight;
    });

    if (savedCheckin != null && mounted) {
      _showInsightDialog(insight);
    }
  }

  void _showInsightDialog(String insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tvuj dnesni insight'),
        content: Text(insight),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Check-in'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Jak se dnes citis?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildSlider('Nalada', _mood, (v) => setState(() => _mood = v)),
            _buildSlider('Energie', _energy, (v) => setState(() => _energy = v)),
            _buildSlider('Fokus', _focus, (v) => setState(() => _focus = v)),
            const SizedBox(height: 24),
            const Text('Stav tela:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: BodyState.values.map((state) {
                return ChoiceChip(
                  label: Text(state.label),
                  selected: _bodyState == state,
                  onSelected: (selected) {
                    if (selected) setState(() => _bodyState = state);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Kontakt s rostlinou dnes?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                ChoiceChip(label: const Text('Ano'), selected: _plantContact == true, onSelected: (s) => setState(() => _plantContact = true)),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Ne'), selected: _plantContact == false, onSelected: (s) => setState(() => _plantContact = false)),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitCheckin,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Ulozit check-in'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, int value, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value/5'),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
