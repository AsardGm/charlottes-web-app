import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tolerance_break_model.dart';
import '../../services/tbreak_service.dart';
import '../../providers/auth_provider.dart';

class TBreakDashboard extends ConsumerStatefulWidget {
  const TBreakDashboard({super.key});

  @override
  ConsumerState<TBreakDashboard> createState() => _TBreakDashboardState();
}

class _TBreakDashboardState extends ConsumerState<TBreakDashboard> {
  bool _isLoading = true;
  ToleranceBreak? _activeBreak;
  Map<String, dynamic>? _statistics;
  List<TBreakCheckIn> _checkIns = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) return;

      final service = TBreakService();
      final activeBreak = await service.getActiveToleranceBreak(user.id);
      final statistics = await service.getStatistics(user.id);

      List<TBreakCheckIn> checkIns = [];
      if (activeBreak != null) {
        checkIns = await service.getCheckIns(activeBreak.id);
      }

      setState(() {
        _activeBreak = activeBreak;
        _statistics = statistics;
        _checkIns = checkIns;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading T-break data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tolerance Break')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tolerance Break Tracker'),
        actions: [
          if (_activeBreak != null)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                // Navigate to history screen (to be implemented)
              },
            ),
        ],
      ),
      body: _activeBreak == null ? _buildNoActiveBreak() : _buildActiveBreak(),
      floatingActionButton: _activeBreak == null
          ? FloatingActionButton.extended(
              onPressed: _showStartBreakDialog,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Začít T-Break'),
            )
          : null,
    );
  }

  Widget _buildNoActiveBreak() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Statistics Card
          if (_statistics != null && _statistics!['total_breaks'] > 0)
            _buildStatisticsCard(),

          const SizedBox(height: 24),

          // What is T-Break Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.spa, color: Colors.green, size: 32),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Co je Tolerance Break?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tolerance break (T-break) je plánovaná přestávka v konzumaci konopí, která pomáhá:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  ...[
                    '🧠 Snížit toleranci a obnovit účinnost',
                    '💰 Ušetřit peníze',
                    '🌱 Resetovat endokannabinoidní systém',
                    '💪 Prokázat sobě ovládnutí',
                    '🏥 Podpořit zdraví a pohodu',
                  ].map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(item, style: const TextStyle(fontSize: 14)),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                  const Text(
                    'Typická délka: 2-4 týdny\nPrvní 3-5 dní jsou nejtěžší, pak se příznaky zlepšují.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Benefits Card
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✨ Očekávané výhody',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...[
                    'Silnější efekt po návratu',
                    'Lepší spánek (po prvních dnech)',
                    'Jasnější myšlení',
                    'Více energie během dne',
                    'Úspora 50-80% nákladů',
                  ].map((benefit) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(benefit)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBreak() {
    if (_activeBreak == null) return const SizedBox.shrink();

    final progressPercent = _activeBreak!.progressPercentage;
    final daysRemaining = _activeBreak!.daysRemaining;
    final encouragement = _activeBreak!.getEncouragementMessage();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress Card
          Card(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Den',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            '${_activeBreak!.daysCompleted}/${_activeBreak!.targetDays}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Zbývá',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            '$daysRemaining ${daysRemaining == 1 ? 'den' : 'dní'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressPercent / 100,
                      minHeight: 12,
                      backgroundColor: Colors.white30,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${progressPercent.toStringAsFixed(0)}% dokončeno',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Encouragement Card
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      encouragement,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Today's Check-in Button
          ElevatedButton.icon(
            onPressed: () => _showCheckInDialog(),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Dnešní check-in'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          // End Break Button
          OutlinedButton.icon(
            onPressed: () => _showEndBreakDialog(),
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Ukončit T-Break'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              foregroundColor: Colors.red,
            ),
          ),

          const SizedBox(height: 24),

          // Recent Check-ins
          if (_checkIns.isNotEmpty) ...[
            const Text(
              'Poslední check-iny',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._checkIns.take(5).map((checkIn) => _buildCheckInCard(checkIn)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    if (_statistics == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Tvoje statistiky',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Celkem',
                  _statistics!['total_breaks'].toString(),
                  Icons.event,
                ),
                _buildStatItem(
                  'Dokončeno',
                  _statistics!['completed_breaks'].toString(),
                  Icons.check_circle,
                ),
                _buildStatItem(
                  'Úspěšnost',
                  '${_statistics!['success_rate'].toStringAsFixed(0)}%',
                  Icons.trending_up,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Nejdelší streak',
                  '${_statistics!['longest_streak']} dní',
                  Icons.whatshot,
                ),
                _buildStatItem(
                  'Celkem dní clean',
                  _statistics!['total_days_clean'].toString(),
                  Icons.spa,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCheckInCard(TBreakCheckIn checkIn) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMoodColor(checkIn.moodScore),
          child: Text(
            checkIn.dayNumber.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text('Den ${checkIn.dayNumber} • ${_formatDate(checkIn.date)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nálada: ${checkIn.moodScore}/10 • Spánek: ${checkIn.sleepQuality}/10'),
            if (checkIn.hadCravings)
              const Text('🔥 Měl/a chuť', style: TextStyle(color: Colors.orange)),
          ],
        ),
        trailing: checkIn.symptoms.isNotEmpty
            ? Chip(
                label: Text('${checkIn.symptoms.length} symptomů'),
                backgroundColor: Colors.orange.shade100,
              )
            : null,
      ),
    );
  }

  Color _getMoodColor(int mood) {
    if (mood >= 8) return Colors.green;
    if (mood >= 5) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Dnes';
    if (diff == 1) return 'Včera';
    return '${date.day}.${date.month}.';
  }

  void _showStartBreakDialog() {
    showDialog(
      context: context,
      builder: (context) => _StartBreakDialog(onBreakStarted: _loadData),
    );
  }

  void _showCheckInDialog() {
    if (_activeBreak == null) return;

    showDialog(
      context: context,
      builder: (context) => _CheckInDialog(
        tbreakId: _activeBreak!.id,
        dayNumber: _activeBreak!.daysCompleted + 1,
        onCheckInAdded: _loadData,
      ),
    );
  }

  void _showEndBreakDialog() {
    if (_activeBreak == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ukončit T-Break?'),
        content: const Text(
          'Opravdu chceš ukončit svůj T-Break? Tato akce nejde vrátit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zrušit'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await TBreakService().markAsFailed(_activeBreak!.id);
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('T-Break ukončen. Neboj, příště to zvládneš!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Chyba: $e')),
                  );
                }
              }
            },
            child: const Text('Ukončit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Start Break Dialog
class _StartBreakDialog extends ConsumerStatefulWidget {
  final VoidCallback onBreakStarted;

  const _StartBreakDialog({required this.onBreakStarted});

  @override
  ConsumerState<_StartBreakDialog> createState() => _StartBreakDialogState();
}

class _StartBreakDialogState extends ConsumerState<_StartBreakDialog> {
  int _targetDays = 14;
  TBreakMotivation _motivation = TBreakMotivation.lowerTolerance;
  final _customMotivationController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Začít nový T-Break'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Jak dlouhý T-Break plánuješ?'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [7, 14, 21, 28].map((days) {
                return ChoiceChip(
                  label: Text('$days dní'),
                  selected: _targetDays == days,
                  onSelected: (selected) {
                    if (selected) setState(() => _targetDays = days);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Tvoje motivace?'),
            const SizedBox(height: 8),
            DropdownButtonFormField<TBreakMotivation>(
              initialValue: _motivation,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: TBreakMotivation.values.map((m) {
                return DropdownMenuItem(
                  value: m,
                  child: Text(m.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _motivation = value);
              },
            ),
            if (_motivation == TBreakMotivation.other) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customMotivationController,
                decoration: const InputDecoration(
                  labelText: 'Vlastní důvod',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Zrušit'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _startBreak,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Začít'),
        ),
      ],
    );
  }

  Future<void> _startBreak() async {
    setState(() => _isLoading = true);

    try {
      final user = await ref.read(currentUserProvider.future);
      if (user == null) throw Exception('Nejsi přihlášen/a');

      await TBreakService().startToleranceBreak(
        userId: user.id,
        targetDays: _targetDays,
        motivation: _motivation,
        customMotivation: _motivation == TBreakMotivation.other
            ? _customMotivationController.text
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onBreakStarted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('T-Break zahájen! Držíme ti palce! 💪')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _customMotivationController.dispose();
    super.dispose();
  }
}

// Check-in Dialog
class _CheckInDialog extends StatefulWidget {
  final String tbreakId;
  final int dayNumber;
  final VoidCallback onCheckInAdded;

  const _CheckInDialog({
    required this.tbreakId,
    required this.dayNumber,
    required this.onCheckInAdded,
  });

  @override
  State<_CheckInDialog> createState() => _CheckInDialogState();
}

class _CheckInDialogState extends State<_CheckInDialog> {
  int _moodScore = 5;
  bool _hadCravings = false;
  int _sleepQuality = 5;
  int _anxietyLevel = 5;
  final List<String> _selectedSymptoms = [];
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Check-in • Den ${widget.dayNumber}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSlider('Nálada', _moodScore, (value) => setState(() => _moodScore = value)),
            _buildSlider('Kvalita spánku', _sleepQuality, (value) => setState(() => _sleepQuality = value)),
            _buildSlider('Úroveň úzkosti', _anxietyLevel, (value) => setState(() => _anxietyLevel = value)),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Měl/a jsem chuť'),
              value: _hadCravings,
              onChanged: (value) => setState(() => _hadCravings = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            const Text('Příznaky (volitelné)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TBreakSymptoms.common.map((symptom) {
                final isSelected = _selectedSymptoms.contains(symptom);
                return FilterChip(
                  label: Text(symptom),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedSymptoms.add(symptom);
                      } else {
                        _selectedSymptoms.remove(symptom);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Poznámky (volitelné)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Zrušit'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitCheckIn,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Uložit'),
        ),
      ],
    );
  }

  Widget _buildSlider(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('$value/10', style: const TextStyle(color: Colors.grey)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          onChanged: (v) => onChanged(v.toInt()),
        ),
      ],
    );
  }

  Future<void> _submitCheckIn() async {
    setState(() => _isLoading = true);

    try {
      await TBreakService().addCheckIn(
        tbreakId: widget.tbreakId,
        dayNumber: widget.dayNumber,
        moodScore: _moodScore,
        hadCravings: _hadCravings,
        sleepQuality: _sleepQuality,
        anxietyLevel: _anxietyLevel,
        symptoms: _selectedSymptoms.isEmpty ? null : _selectedSymptoms,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onCheckInAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-in uložen! Dobrá práce! 💪')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
