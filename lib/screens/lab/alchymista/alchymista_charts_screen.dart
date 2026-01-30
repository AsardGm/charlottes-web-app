import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/lab/lab_nutrient_model.dart';
import '../../../providers/lab_provider.dart';
import '../../../theme/theme.dart';

/// Alchymista Charts - grafy pH/EC/PPM v case
class AlchymistaChartsScreen extends ConsumerWidget {
  final String growId;

  const AlchymistaChartsScreen({super.key, required this.growId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(labNutrientLogsProvider(growId));

    return Scaffold(
      backgroundColor: AppColors.functionalBg,
      appBar: AppBar(
        title: const Text('Grafy'),
        backgroundColor: AppColors.surface,
      ),
      body: logs.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart, size: 64, color: AppColors.functionalMuted),
                  const SizedBox(height: 16),
                  Text(
                    'Zadna data pro grafy',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Zaloguj pH/EC hodnoty v Alchymistovi',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          // Otoc poradi (od nejstarsiho)
          final sorted = list.reversed.toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildChartCard('pH', sorted, (l) => l.phValue, AppColors.accent,
                  minY: 4, maxY: 8),
              const SizedBox(height: 16),
              _buildChartCard('EC', sorted, (l) => l.ecValue, AppColors.success,
                  minY: 0, maxY: 3),
              const SizedBox(height: 16),
              _buildChartCard('PPM', sorted, (l) => l.ppmValue, AppColors.warning,
                  minY: 0, maxY: 1500),
              const SizedBox(height: 16),
              _buildChartCard(
                  'Teplota (°C)', sorted, (l) => l.temperature, AppColors.primary,
                  minY: 15, maxY: 35),
              const SizedBox(height: 16),
              _buildChartCard(
                  'Vlhkost (%)', sorted, (l) => l.humidity, AppColors.info,
                  minY: 20, maxY: 80),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => Center(
          child: Text('Chyba: $e', style: TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildChartCard(
    String label,
    List<LabNutrientLogModel> logs,
    double? Function(LabNutrientLogModel) valueGetter,
    Color color, {
    double minY = 0,
    double maxY = 10,
  }) {
    final dataPoints = <_DataPoint>[];
    for (final log in logs) {
      final value = valueGetter(log);
      if (value != null) {
        dataPoints.add(_DataPoint(log.dayNumber.toDouble(), value));
      }
    }

    if (dataPoints.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.functionalSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$label - zadna data',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.functionalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.functionalBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Posledni: ${dataPoints.last.value.toStringAsFixed(1)}',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: Size.infinite,
              painter: _LineChartPainter(
                dataPoints: dataPoints,
                color: color,
                minY: minY,
                maxY: maxY,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataPoint {
  final double x;
  final double value;

  _DataPoint(this.x, this.value);
}

/// CustomPaint line chart
class _LineChartPainter extends CustomPainter {
  final List<_DataPoint> dataPoints;
  final Color color;
  final double minY;
  final double maxY;

  _LineChartPainter({
    required this.dataPoints,
    required this.color,
    required this.minY,
    required this.maxY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withAlpha(60), color.withAlpha(5)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.functionalBorder.withAlpha(80)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Normalize data
    final xMin = dataPoints.first.x;
    final xMax = dataPoints.last.x;
    final xRange = xMax - xMin;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < dataPoints.length; i++) {
      final px = xRange > 0
          ? (dataPoints[i].x - xMin) / xRange * size.width
          : size.width / 2;
      final py = size.height -
          ((dataPoints[i].value - minY) / (maxY - minY) * size.height)
              .clamp(0.0, size.height);

      if (i == 0) {
        path.moveTo(px, py);
        fillPath.moveTo(px, size.height);
        fillPath.lineTo(px, py);
      } else {
        path.lineTo(px, py);
        fillPath.lineTo(px, py);
      }

      // Dot
      canvas.drawCircle(Offset(px, py), 3, dotPaint);
    }

    // Fill
    fillPath.lineTo(
      xRange > 0
          ? (dataPoints.last.x - xMin) / xRange * size.width
          : size.width / 2,
      size.height,
    );
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);

    // Line
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.dataPoints.length != dataPoints.length;
  }
}
