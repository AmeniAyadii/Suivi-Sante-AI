// lib/screens/vital_tracker/widgets/vital_card.dart

import 'dart:math'; // ✅ IMPORT AJOUTÉ pour max/min
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/constante_vitale.dart';

class VitalCard extends StatelessWidget {
  final TypeConstante type;
  final double? valeur;
  final String unite;
  final String statut;
  final String tendance;
  final List<Map<String, dynamic>>? chartData;
  final bool isCircular;

  const VitalCard({
    Key? key,
    required this.type,
    this.valeur,
    required this.unite,
    required this.statut,
    required this.tendance,
    this.chartData,
    this.isCircular = false,
  }) : super(key: key);

  Color get _statutColor {
    switch (statut) {
      case 'Normal':
      case 'Optimal':
        return Colors.green;
      case 'Alerte':
        return Colors.orange;
      case 'Critique':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: _statutColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            if (valeur != null) _buildValue(),
            const SizedBox(height: 12),
            if (chartData != null && chartData!.isNotEmpty)
              isCircular ? _buildCircularChart() : _buildLineChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          type.icon,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 8),
        Flexible(flex: 1, child: Text(
            type.label.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF152B44),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _statutColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _statutColor == Colors.green ? Icons.check_circle :
                _statutColor == Colors.orange ? Icons.warning_amber :
                Icons.error_outline,
                color: _statutColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                statut,
                style: TextStyle(
                  color: _statutColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildValue() {
    return Row(
      children: [
        Text(
          valeur!.toString(),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0A1F3A),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          unite,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF4D688B),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: tendance.contains('Hausse')
                ? Colors.orange.withOpacity(0.1)
                : tendance.contains('Baisse')
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tendance.contains('Hausse')
                    ? Icons.trending_up
                    : tendance.contains('Baisse')
                        ? Icons.trending_down
                        : Icons.trending_flat,
                color: tendance.contains('Hausse')
                    ? Colors.orange
                    : tendance.contains('Baisse')
                        ? Colors.blue
                        : Colors.green,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                tendance,
                style: TextStyle(
                  color: tendance.contains('Hausse')
                      ? Colors.orange
                      : tendance.contains('Baisse')
                          ? Colors.blue
                          : Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ Graphique en ligne avec fl_chart (CORRIGÉ)
  Widget _buildLineChart() {
    final spots = chartData!.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        (entry.value['value'] as double?) ?? 0.0,
      );
    }).toList();

    final labels = chartData!.map((data) => data['label'].toString()).toList();
    
    // ✅ CORRECTION : Utilisation de reduce pour max et min
    final values = chartData!.map((e) => e['value'] as double).toList();
    final maxValue = values.reduce(max); // ✅ Utilise max de dart:math
    final minValue = values.reduce(min); // ✅ Utilise min de dart:math
    final range = maxValue - minValue;
    final horizontalInterval = range / 4;

    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: horizontalInterval > 0 ? horizontalInterval : 5,
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        labels[index],
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: _statutColor,
              barWidth: 2,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: _statutColor.withOpacity(0.1),
              ),
            ),
          ],
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: (minValue - 5).clamp(0, double.infinity),
          maxY: maxValue + 5,
        ),
      ),
    );
  }

  // ✅ Graphique circulaire avec fl_chart
  Widget _buildCircularChart() {
    final pourcentage = (valeur ?? 0) / 120; // 120 BPM max
    final color = _statutColor;

    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: pourcentage,
                        color: color,
                        radius: 35,
                        showTitle: false,
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                      PieChartSectionData(
                        value: 1 - pourcentage,
                        color: Colors.grey.shade200,
                        radius: 35,
                        showTitle: false,
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                    ],
                    sectionsSpace: 0,
                    centerSpaceRadius: 30,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        valeur != null ? valeur!.toStringAsFixed(0) : '--',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A1F3A),
                        ),
                      ),
                      Text(
                        unite,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF4D688B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Au repos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0A1F3A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tendance,
                  style: TextStyle(
                    fontSize: 14,
                    color: tendance.contains('Hausse') ? Colors.orange :
                           tendance.contains('Baisse') ? Colors.blue : Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600, size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      'Plage normale: 50-100 BPM',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

