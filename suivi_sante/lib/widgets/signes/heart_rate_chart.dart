import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:health_connector/health_connector.dart';

class HeartRateChart extends StatelessWidget {
  final List<HeartRateRecord> data;

  const HeartRateChart({required this.data});

  @override
  Widget build(BuildContext context) {
    // Transformer les données pour le graphique
    final chartData = data.map((record) {
      return HeartRateData(
        time: record.startTime,
        value: record.count.value.toDouble(),
      );
    }).toList();

    return Container(
      height: 200,
      child: SfCartesianChart(
        primaryXAxis: DateTimeAxis(
          title: AxisTitle(text: 'Heure'),
          dateFormat: DateFormat.Hm(),
        ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: 'BPM'),
          minimum: 40,
          maximum: 120,
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        series: <CartesianSeries<HeartRateData, DateTime>>[
          LineSeries<HeartRateData, DateTime>(
            dataSource: chartData,
            xValueMapper: (HeartRateData d, _) => d.time,
            yValueMapper: (HeartRateData d, _) => d.value,
            name: 'Fréquence cardiaque',
            color: Colors.red,
            markerSettings: const MarkerSettings(isVisible: true),
          ),
        ],
      ),
    );
  }
}

class HeartRateData {
  final DateTime time;
  final double value;

  HeartRateData({required this.time, required this.value});
}