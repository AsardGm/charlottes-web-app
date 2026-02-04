import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/theme.dart';
import '../../services/strain_journal_service.dart';
import '../../models/strain_journal_model.dart';

/// Create new strain journal entry
class CreateStrainJournalScreen extends ConsumerStatefulWidget {
  final String? strainId;

  const CreateStrainJournalScreen({super.key, this.strainId});

  @override
  ConsumerState<CreateStrainJournalScreen> createState() =>
      _CreateStrainJournalScreenState();
}

class _CreateStrainJournalScreenState
    extends ConsumerState<CreateStrainJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _journalService = StrainJournalService();

  bool _isLoading = false;
  List<Map<String, dynamic>> _availableStrains = [];
  String? _selectedStrainId;
  String? _selectedStrainName;

  // Basic info
  final _titleController = TextEditingController();
  DateTime _consumedAt = DateTime.now();
  String? _method;
  double _amount = 1.0;
  String _amountUnit = 'g';

  // Context
  final List<String> _selectedSettings = [];
  final List<String> _selectedActivities = [];
  int _moodBefore = 5;
  final _intentionController = TextEditingController();

  // Effects (0-10 scale)
  final Map<String, int> _physicalEffects = {};
  final Map<String, int> _mentalEffects = {};
  final Map<String, int> _emotionalEffects = {};

  // Duration (minutes)
  int _onsetTime = 5;
  int _peakTime = 30;
  int _totalDuration = 120;

  // Overall
  double _overallRating = 5.0;
  bool _wouldUseAgain = true;

  // Notes
  final _notesController = TextEditingController();
  final List<String> _highlights = [];
  final List<String> _drawbacks = [];

  // Metadata
  bool _isFavorite = false;
  bool _isPrivate = false;

  final List<String> _methods = [
    'Joint',
    'Bong',
    'Pipe',
    'Vaporizer',
    'Edible',
    'Oil',
    'Concentrate',
    'Other'
  ];

  final List<String> _settingOptions = [
    'Home',
    'Party',
    'Outdoors',
    'Concert',
    'Work',
    'Social',
    'Alone',
    'With Friends'
  ];

  final List<String> _activityOptions = [
    'Relaxing',
    'Gaming',
    'Music',
    'Movies',
    'Exercise',
    'Creative Work',
    'Socializing',
    'Eating',
    'Sleeping',
    'Working'
  ];

  @override
  void initState() {
    super.initState();
    _selectedStrainId = widget.strainId;
    _loadStrains();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _intentionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadStrains() async {
    try {
      final response = await Supabase.instance.client
          .from('strains')
          .select('id, name')
          .order('name');

      setState(() {
        _availableStrains = List<Map<String, dynamic>>.from(response);
        if (_selectedStrainId != null) {
          final strain = _availableStrains.firstWhere(
            (s) => s['id'] == _selectedStrainId,
            orElse: () => {},
          );
          _selectedStrainName = strain['name'];
        }
      });
    } catch (e) {
      debugPrint('Error loading strains: $e');
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStrainId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a strain')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Create effects objects
      final physicalEffects = PhysicalEffects(
        bodyHigh: _physicalEffects['body_high'],
        energyLevel: _physicalEffects['energy_level'],
        appetite: _physicalEffects['appetite'],
        dryMouth: _physicalEffects['dry_mouth'],
        redEyes: _physicalEffects['red_eyes'],
        physicalRelaxation: _physicalEffects['physical_relaxation'],
        painRelief: _physicalEffects['pain_relief'],
        sleepiness: _physicalEffects['sleepiness'],
      );

      final mentalEffects = MentalEffects(
        headHigh: _mentalEffects['head_high'],
        focus: _mentalEffects['focus'],
        creativity: _mentalEffects['creativity'],
        euphoria: _mentalEffects['euphoria'],
        mentalClarity: _mentalEffects['mental_clarity'],
        memoryImpact: _mentalEffects['memory_impact'],
        paranoia: _mentalEffects['paranoia'],
      );

      final emotionalEffects = EmotionalEffects(
        happiness: _emotionalEffects['happiness'],
        anxietyRelief: _emotionalEffects['anxiety_relief'],
        stressRelief: _emotionalEffects['stress_relief'],
        sociability: _emotionalEffects['sociability'],
        introspection: _emotionalEffects['introspection'],
      );

      await _journalService.createJournalEntry(
        userId: userId,
        strainId: _selectedStrainId!,
        consumedAt: _consumedAt,
        method: _method,
        amount: _amount,
        amountUnit: _amountUnit,
        setting: _selectedSettings.isEmpty ? null : _selectedSettings,
        activities: _selectedActivities.isEmpty ? null : _selectedActivities,
        moodBefore: _moodBefore,
        intention: _intentionController.text.isNotEmpty
            ? _intentionController.text
            : null,
        physicalEffects: physicalEffects,
        mentalEffects: mentalEffects,
        emotionalEffects: emotionalEffects,
        onsetTime: _onsetTime,
        peakTime: _peakTime,
        totalDuration: _totalDuration,
        overallRating: _overallRating,
        wouldUseAgain: _wouldUseAgain,
        title:
            _titleController.text.isNotEmpty ? _titleController.text : null,
        notes:
            _notesController.text.isNotEmpty ? _notesController.text : null,
        highlights: _highlights.isEmpty ? null : _highlights,
        drawbacks: _drawbacks.isEmpty ? null : _drawbacks,
        isFavorite: _isFavorite,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry saved successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Journal Entry'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? AppColors.accent : null,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          IconButton(
            icon: Icon(
              _isPrivate ? Icons.lock : Icons.lock_open,
              color: _isPrivate ? AppColors.accent : null,
            ),
            onPressed: () => setState(() => _isPrivate = !_isPrivate),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 16),
            _buildContextSection(),
            const SizedBox(height: 16),
            _buildPhysicalEffectsSection(),
            const SizedBox(height: 16),
            _buildMentalEffectsSection(),
            const SizedBox(height: 16),
            _buildEmotionalEffectsSection(),
            const SizedBox(height: 16),
            _buildDurationSection(),
            const SizedBox(height: 16),
            _buildOverallSection(),
            const SizedBox(height: 16),
            _buildNotesSection(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Save Entry',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Basic Information',
      icon: Icons.info_outline,
      children: [
        // Strain selector
        InkWell(
          onTap: () => _showStrainPicker(),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Strain',
              labelStyle: TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            child: Text(
              _selectedStrainName ?? 'Select a strain',
              style: TextStyle(
                color: _selectedStrainName != null
                    ? Colors.white
                    : AppColors.textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Title
        TextFormField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Title (optional)'),
        ),
        const SizedBox(height: 12),

        // Date & Time
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _consumedAt,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_consumedAt),
              );
              if (time != null) {
                setState(() {
                  _consumedAt = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                });
              }
            }
          },
          child: InputDecorator(
            decoration: _inputDecoration('Consumed At'),
            child: Text(
              '${_consumedAt.day}/${_consumedAt.month}/${_consumedAt.year} ${_consumedAt.hour}:${_consumedAt.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Method
        DropdownButtonFormField<String>(
          initialValue: _method,
          decoration: _inputDecoration('Method'),
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: Colors.white),
          items: _methods.map((method) {
            return DropdownMenuItem(value: method, child: Text(method));
          }).toList(),
          onChanged: (value) => setState(() => _method = value),
        ),
        const SizedBox(height: 12),

        // Amount
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: _amount.toString(),
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Amount'),
                onChanged: (value) {
                  final parsed = double.tryParse(value);
                  if (parsed != null) setState(() => _amount = parsed);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _amountUnit,
                decoration: _inputDecoration('Unit'),
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white),
                items: ['g', 'mg', 'ml', 'puffs']
                    .map((unit) =>
                        DropdownMenuItem(value: unit, child: Text(unit)))
                    .toList(),
                onChanged: (value) => setState(() => _amountUnit = value!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContextSection() {
    return _buildSection(
      title: 'Context & Setting',
      icon: Icons.location_on,
      children: [
        // Setting chips
        const Text('Setting:', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _settingOptions.map((setting) {
            final isSelected = _selectedSettings.contains(setting);
            return FilterChip(
              label: Text(setting),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSettings.add(setting);
                  } else {
                    _selectedSettings.remove(setting);
                  }
                });
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.accent.withOpacity(0.3),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.accent : Colors.white70,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Activities
        const Text('Activities:', style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _activityOptions.map((activity) {
            final isSelected = _selectedActivities.contains(activity);
            return FilterChip(
              label: Text(activity),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedActivities.add(activity);
                  } else {
                    _selectedActivities.remove(activity);
                  }
                });
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.accent.withOpacity(0.3),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.accent : Colors.white70,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Mood before
        Text('Mood Before (1-10): $_moodBefore',
            style: const TextStyle(color: Colors.white70)),
        Slider(
          value: _moodBefore.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: AppColors.accent,
          onChanged: (value) => setState(() => _moodBefore = value.toInt()),
        ),
        const SizedBox(height: 8),

        // Intention
        TextFormField(
          controller: _intentionController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Intention (optional)'),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildPhysicalEffectsSection() {
    return _buildSection(
      title: 'Physical Effects',
      icon: Icons.fitness_center,
      children: [
        _buildEffectSlider('Body High', 'body_high', _physicalEffects),
        _buildEffectSlider('Energy Level', 'energy_level', _physicalEffects),
        _buildEffectSlider('Appetite', 'appetite', _physicalEffects),
        _buildEffectSlider(
            'Physical Relaxation', 'physical_relaxation', _physicalEffects),
        _buildEffectSlider('Pain Relief', 'pain_relief', _physicalEffects),
        _buildEffectSlider('Sleepiness', 'sleepiness', _physicalEffects),
        _buildEffectSlider('Dry Mouth', 'dry_mouth', _physicalEffects),
        _buildEffectSlider('Red Eyes', 'red_eyes', _physicalEffects),
      ],
    );
  }

  Widget _buildMentalEffectsSection() {
    return _buildSection(
      title: 'Mental Effects',
      icon: Icons.psychology,
      children: [
        _buildEffectSlider('Head High', 'head_high', _mentalEffects),
        _buildEffectSlider('Focus', 'focus', _mentalEffects),
        _buildEffectSlider('Creativity', 'creativity', _mentalEffects),
        _buildEffectSlider('Euphoria', 'euphoria', _mentalEffects),
        _buildEffectSlider('Mental Clarity', 'mental_clarity', _mentalEffects),
        _buildEffectSlider('Memory Impact', 'memory_impact', _mentalEffects),
        _buildEffectSlider('Paranoia', 'paranoia', _mentalEffects),
      ],
    );
  }

  Widget _buildEmotionalEffectsSection() {
    return _buildSection(
      title: 'Emotional Effects',
      icon: Icons.mood,
      children: [
        _buildEffectSlider('Happiness', 'happiness', _emotionalEffects),
        _buildEffectSlider(
            'Anxiety Relief', 'anxiety_relief', _emotionalEffects),
        _buildEffectSlider('Stress Relief', 'stress_relief', _emotionalEffects),
        _buildEffectSlider('Sociability', 'sociability', _emotionalEffects),
        _buildEffectSlider('Introspection', 'introspection', _emotionalEffects),
      ],
    );
  }

  Widget _buildDurationSection() {
    return _buildSection(
      title: 'Duration',
      icon: Icons.timer,
      children: [
        Text('Onset Time: $_onsetTime min',
            style: const TextStyle(color: Colors.white70)),
        Slider(
          value: _onsetTime.toDouble(),
          min: 1,
          max: 60,
          divisions: 59,
          activeColor: AppColors.accent,
          onChanged: (value) => setState(() => _onsetTime = value.toInt()),
        ),
        const SizedBox(height: 8),
        Text('Peak Time: $_peakTime min',
            style: const TextStyle(color: Colors.white70)),
        Slider(
          value: _peakTime.toDouble(),
          min: 10,
          max: 180,
          divisions: 34,
          activeColor: AppColors.accent,
          onChanged: (value) => setState(() => _peakTime = value.toInt()),
        ),
        const SizedBox(height: 8),
        Text('Total Duration: $_totalDuration min',
            style: const TextStyle(color: Colors.white70)),
        Slider(
          value: _totalDuration.toDouble(),
          min: 30,
          max: 480,
          divisions: 45,
          activeColor: AppColors.accent,
          onChanged: (value) => setState(() => _totalDuration = value.toInt()),
        ),
      ],
    );
  }

  Widget _buildOverallSection() {
    return _buildSection(
      title: 'Overall Rating',
      icon: Icons.star,
      children: [
        Text('Overall Rating: ${_overallRating.toStringAsFixed(1)} / 10',
            style: const TextStyle(color: Colors.white70, fontSize: 16)),
        Slider(
          value: _overallRating,
          min: 0,
          max: 10,
          divisions: 20,
          activeColor: AppColors.accent,
          onChanged: (value) => setState(() => _overallRating = value),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Would Use Again',
              style: TextStyle(color: Colors.white)),
          value: _wouldUseAgain,
          activeColor: AppColors.accent,
          onChanged: (value) => setState(() => _wouldUseAgain = value),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return _buildSection(
      title: 'Notes & Observations',
      icon: Icons.notes,
      children: [
        TextFormField(
          controller: _notesController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Notes (optional)'),
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEffectSlider(
      String label, String key, Map<String, int> effectsMap) {
    final value = effectsMap[key];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${value ?? 'N/A'}',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Slider(
          value: value?.toDouble() ?? 0,
          min: 0,
          max: 10,
          divisions: 10,
          activeColor: AppColors.accent,
          onChanged: (val) {
            setState(() {
              if (val == 0) {
                effectsMap.remove(key);
              } else {
                effectsMap[key] = val.toInt();
              }
            });
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _showStrainPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Strain',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _availableStrains.length,
                itemBuilder: (context, index) {
                  final strain = _availableStrains[index];
                  return ListTile(
                    title: Text(
                      strain['name'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    selected: _selectedStrainId == strain['id'],
                    selectedTileColor: AppColors.accent.withOpacity(0.1),
                    onTap: () {
                      setState(() {
                        _selectedStrainId = strain['id'];
                        _selectedStrainName = strain['name'];
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
