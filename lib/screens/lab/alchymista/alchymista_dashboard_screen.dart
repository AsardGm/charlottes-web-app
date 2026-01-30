import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/lab/lab_nutrient_model.dart';
import '../../../providers/lab_provider.dart';
import '../../../theme/theme.dart';

/// Alchymista Dashboard - nutrient logging + mini chart
class AlchymistaDashboardScreen extends ConsumerStatefulWidget {
  final String growId;

  const AlchymistaDashboardScreen({super.key, required this.growId});

  @override
  ConsumerState<AlchymistaDashboardScreen> createState() =>
      _AlchymistaDashboardScreenState();
}

class _AlchymistaDashboardScreenState
    extends ConsumerState<AlchymistaDashboardScreen> {
  final _phController = TextEditingController();
  final _ecController = TextEditingController();
  final _ppmController = TextEditingController();
  final _waterController = TextEditingController();
  final _tempController = TextEditingController();
  final _humidityController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _phController.dispose();
    _ecController.dispose();
    _ppmController.dispose();
    _waterController.dispose();
    _tempController.dispose();
    _humidityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitLog() async {
    final grow = ref.read(labGrowByIdProvider(widget.growId)).value;
    if (grow == null) return;

    await ref.read(labNutrientNotifierProvider.notifier).addLog(
      growId: widget.growId,
      dayNumber: grow.dayCount,
      phValue: double.tryParse(_phController.text),
      ecValue: double.tryParse(_ecController.text),
      ppmValue: double.tryParse(_ppmController.text),
      waterAmountMl: int.tryParse(_waterController.text),
      temperature: double.tryParse(_tempController.text),
      humidity: double.tryParse(_humidityController.text),
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (mounted) {
      _phController.clear();
      _ecController.clear();
      _ppmController.clear();
      _waterController.clear();
      _tempController.clear();
      _humidityController.clear();
      _notesController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Log ulozen'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(labNutrientLogsProvider(widget.growId));
    final nutrientState = ref.watch(labNutrientNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      body: Column(
        children: [
          // Custom header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withAlpha(30),
                  AppColors.functionalBg,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Back button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.functionalSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.functionalBorder,
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        color: AppColors.textPrimary,
                        padding: EdgeInsets.zero,
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    Expanded(
                      child: Text(
                        'ALCHYMISTA',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    // Action buttons
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.functionalSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.accent.withAlpha(60),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.show_chart, size: 20),
                        color: AppColors.accent,
                        padding: EdgeInsets.zero,
                        onPressed: () => context.push('/lab/alchymista/${widget.growId}/charts'),
                        tooltip: 'Grafy',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.functionalSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.warning.withAlpha(60),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.restaurant_menu, size: 20),
                        color: AppColors.warning,
                        padding: EdgeInsets.zero,
                        onPressed: () => context.push('/lab/schedules'),
                        tooltip: 'Recepty',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Quick log form
                _buildLogForm(nutrientState),
                const SizedBox(height: 24),

                // Section header with decorative line
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'POSLEDNI ZAZNAMY',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                logs.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.functionalSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withAlpha(40),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.science_outlined,
                                color: AppColors.accent,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Zadne zaznamy',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: list.take(10).map((log) => _NutrientLogCard(log: log)).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                  error: (e, _) => Text('Chyba: $e',
                      style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogForm(LabGrowState nutrientState) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withAlpha(40),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success.withAlpha(30),
                  AppColors.functionalSurface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOVY LOG',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  width: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success,
                        AppColors.success.withAlpha(0),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // pH, EC, PPM row
                Row(
                  children: [
                    Expanded(child: _buildField('pH', _phController, '6.2', const Color(0xFF42A5F5))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField('EC', _ecController, '1.4', AppColors.success)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField('PPM', _ppmController, '700', AppColors.warning)),
                  ],
                ),
                const SizedBox(height: 12),

                // Water, Temp, Humidity row
                Row(
                  children: [
                    Expanded(child: _buildField('Voda (ml)', _waterController, '500', AppColors.accent)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField('Teplota', _tempController, '24', const Color(0xFFEF5350))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildField('Vlhkost %', _humidityController, '55', const Color(0xFF42A5F5))),
                  ],
                ),
                const SizedBox(height: 12),

                // Notes
                TextFormField(
                  controller: _notesController,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Poznamky...',
                    hintStyle: TextStyle(color: AppColors.functionalMuted),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.functionalBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.functionalBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.functionalBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: nutrientState.isLoading ? null : _submitLog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: nutrientState.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('ZALOGOVAT',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String hint, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.functionalMuted),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            filled: true,
            fillColor: AppColors.functionalBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.functionalBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.functionalBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: labelColor),
            ),
          ),
        ),
      ],
    );
  }
}

/// Karta nutrient logu
class _NutrientLogCard extends StatelessWidget {
  final LabNutrientLogModel log;

  const _NutrientLogCard({required this.log});

  Color _getPhBorderColor() {
    final ph = log.phValue;
    if (ph == null) return AppColors.functionalBorder;
    if (ph < 5.5) return AppColors.primary;
    if (ph > 6.8) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.functionalBorder, width: 1),
      ),
      child: Row(
        children: [
          // Colored pH indicator border
          Container(
            width: 4,
            height: 80,
            decoration: BoxDecoration(
              color: _getPhBorderColor(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Den ${log.dayNumber}',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${log.createdAt.day}.${log.createdAt.month}.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (log.phValue != null)
                        _buildValueContainer('pH', log.phValue!.toStringAsFixed(1), const Color(0xFF42A5F5)),
                      if (log.ecValue != null)
                        _buildValueContainer('EC', log.ecValue!.toStringAsFixed(2), AppColors.success),
                      if (log.ppmValue != null)
                        _buildValueContainer('PPM', log.ppmValue!.toStringAsFixed(0), AppColors.warning),
                      if (log.waterAmountMl != null)
                        _buildValueContainer('H2O', '${log.waterAmountMl}ml', AppColors.accent),
                      if (log.temperature != null)
                        _buildValueContainer('T', '${log.temperature!.toStringAsFixed(1)}°C', const Color(0xFFEF5350)),
                      if (log.humidity != null)
                        _buildValueContainer('RH', '${log.humidity!.toStringAsFixed(0)}%', const Color(0xFF42A5F5)),
                    ],
                  ),
                  if (log.notes != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      log.notes!,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueContainer(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withAlpha(40),
          width: 1,
        ),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: color.withAlpha(200),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
