import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/lab/lab_grow_model.dart';
import '../../providers/lab_provider.dart';
import '../../theme/theme.dart';

/// Formular pro vytvoreni noveho growu
class LabCreateGrowScreen extends ConsumerStatefulWidget {
  const LabCreateGrowScreen({super.key});

  @override
  ConsumerState<LabCreateGrowScreen> createState() => _LabCreateGrowScreenState();
}

class _LabCreateGrowScreenState extends ConsumerState<LabCreateGrowScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _strainController = TextEditingController();
  final _notesController = TextEditingController();

  GrowPhase _selectedPhase = GrowPhase.germination;
  GrowEnvironment? _selectedEnvironment;
  GrowMedium? _selectedMedium;
  DateTime _startDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _strainController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(labGrowNotifierProvider.notifier).createGrow(
      name: _nameController.text.trim(),
      strainName: _strainController.text.trim().isNotEmpty
          ? _strainController.text.trim()
          : null,
      phase: _selectedPhase,
      startDate: _startDate,
      environment: _selectedEnvironment,
      medium: _selectedMedium,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (result != null && mounted) {
      context.pop();
      context.push('/lab/chronos/${result.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final growState = ref.watch(labGrowNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        title: const Text('Novy Grow'),
        backgroundColor: AppColors.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nazev
            _buildLabel('Nazev growu *'),
            TextFormField(
              controller: _nameController,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration('napr. Indoor Run #1'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Zadej nazev' : null,
            ),
            const SizedBox(height: 20),

            // Odruida
            _buildLabel('Odruda (volitelne)'),
            TextFormField(
              controller: _strainController,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration('napr. Northern Lights'),
            ),
            const SizedBox(height: 20),

            // Faze
            _buildLabel('Pocatecni faze'),
            _buildPhaseSelector(),
            const SizedBox(height: 20),

            // Prostredi
            _buildLabel('Prostredi'),
            _buildEnvironmentSelector(),
            const SizedBox(height: 20),

            // Medium
            _buildLabel('Medium'),
            _buildMediumSelector(),
            const SizedBox(height: 20),

            // Datum zacatku
            _buildLabel('Datum zacatku'),
            _buildDatePicker(),
            const SizedBox(height: 20),

            // Poznamky
            _buildLabel('Poznamky (volitelne)'),
            TextFormField(
              controller: _notesController,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: _inputDecoration('Poznamky k growu...'),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Error
            if (growState.hasError) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  growState.errorMessage!,
                  style: TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: growState.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: growState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'ZALOZIT GROW',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.functionalMuted),
      filled: true,
      fillColor: AppColors.functionalSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.functionalBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.functionalBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.accent),
      ),
    );
  }

  Widget _buildPhaseSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: GrowPhase.values.where((p) => p != GrowPhase.completed).map((phase) {
        final isSelected = _selectedPhase == phase;
        return GestureDetector(
          onTap: () => setState(() => _selectedPhase = phase),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accent.withAlpha(30)
                  : AppColors.functionalSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.functionalBorder,
                width: 1,
              ),
            ),
            child: Text(
              '${phase.icon} ${phase.label}',
              style: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEnvironmentSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: GrowEnvironment.values.map((env) {
        final isSelected = _selectedEnvironment == env;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedEnvironment = isSelected ? null : env;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accent.withAlpha(30)
                  : AppColors.functionalSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.functionalBorder,
                width: 1,
              ),
            ),
            child: Text(
              env.label,
              style: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMediumSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: GrowMedium.values.map((med) {
        final isSelected = _selectedMedium == med;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedMedium = isSelected ? null : med;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accent.withAlpha(30)
                  : AppColors.functionalSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.functionalBorder,
                width: 1,
              ),
            ),
            child: Text(
              med.label,
              style: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _startDate,
          firstDate: DateTime(2024),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _startDate = date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.functionalSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.functionalBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.accent, size: 18),
            const SizedBox(width: 10),
            Text(
              '${_startDate.day}.${_startDate.month}.${_startDate.year}',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
