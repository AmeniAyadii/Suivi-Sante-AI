import 'package:flutter/material.dart';
import 'package:health_connector/health_connector.dart';
import 'package:suivi_sante_pro/s/signes/news2_score.dart';
import 'package:suivi_sante_pro/services/signes/health_data_service.dart';
import 'package:suivi_sante_pro/widgets/signes/heart_rate_chart.dart';


class HealthDashboard extends StatefulWidget {
  @override
  _HealthDashboardState createState() => _HealthDashboardState();
}

class _HealthDashboardState extends State<HealthDashboard> {
  final healthService = HealthDataService();
  bool isReady = false;
  int steps = 0;
  List<HeartRateRecord> heartRates = [];
  List<BloodPressureRecord> bpRecords = [];
  int news2Score = 0;

  @override
  void initState() {
    super.initState();
    _initHealth();
  }

  Future<void> _initHealth() async {
    try {
      // 1. Initialiser le service
      await healthService.initialize();

      // 2. Demander les permissions
      final granted = await healthService.requestPermissions();

      if (granted) {
        // 3. Charger les données
        steps = await healthService.getStepsToday();
        heartRates = await healthService.getHeartRateLast24h();
        bpRecords = await healthService.getBloodPressureThisWeek();

        // 4. Calculer le score NEWS2
        if (heartRates.isNotEmpty && bpRecords.isNotEmpty) {
          final latestBP = bpRecords.last;
          final latestHR = heartRates.last;
          
          news2Score = NEWS2Score.calculate(
            respirationRate: 16, // À remplacer par des vraies données
            oxygenSaturation: 98,
            onOxygen: false,
            pulseRate: latestHR.count.value.toInt(),
            systolicBP: latestBP.systolic.value.toInt(),
            temperature: 37.0,
          );
        }

        setState(() {
          isReady = true;
        });
      }
    } catch (e) {
      print('Erreur: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suivi Santé'),
        backgroundColor: NEWS2Score.getAlertColor(news2Score),
      ),
      body: isReady
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Cartes de résumé
                  Row(
                    children: [
                      _buildMetricCard(
                        title: 'Pas',
                        value: '$steps',
                        icon: Icons.directions_walk,
                        color: Colors.blue,
                      ),
                      _buildMetricCard(
                        title: 'Fréquence cardiaque',
                        value: heartRates.isNotEmpty 
                            ? '${heartRates.last.count.value.toInt()} bpm'
                            : '--',
                        icon: Icons.favorite,
                        color: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Score NEWS2
                  Card(
                    color: NEWS2Score.getAlertColor(news2Score).withOpacity(0.1),
                    child: ListTile(
                      leading: Icon(
                        Icons.warning,
                        color: NEWS2Score.getAlertColor(news2Score),
                      ),
                      title: Text(
                        'Score NEWS2: $news2Score',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: NEWS2Score.getAlertColor(news2Score),
                        ),
                      ),
                      subtitle: Text(NEWS2Score.getAlertLevel(news2Score)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Graphique
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fréquence cardiaque (24h)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          heartRates.isNotEmpty
                              ? HeartRateChart(data: heartRates)
                              : Center(
                                  child: Text('Aucune donnée disponible'),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Flexible(flex: 1, child: 
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
