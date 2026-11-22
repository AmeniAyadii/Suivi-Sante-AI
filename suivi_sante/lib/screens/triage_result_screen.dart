// lib/screens/triage_result_screen.dart
// Écran d'affichage du résultat

import 'package:flutter/material.dart';
import '../models/triage_result.dart';

class TriageResultScreen extends StatelessWidget {
  final TriageResult result;

  const TriageResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat du Triage'),
        backgroundColor: result.color,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ----- Carte principale du niveau -----
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: result.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: result.color.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(result.emoji, style: const TextStyle(fontSize: 60)),
                  const SizedBox(height: 12),
                  Text(
                    'NIVEAU ${result.triageAcuity}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    result.label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Confiance : ${(result.confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ----- Recommandation -----
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Recommandation',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(result.recommendation, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      '⏱️ Délai maximal : ${result.maxWaitMinutes} minutes',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ----- Distribution des probabilités -----
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📊 Distribution des probabilités',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...result.probabilities.entries.map((e) {
                      final niveau = int.parse(e.key);
                      final proba = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Niveau $niveau'),
                                Text('${(proba * 100).toStringAsFixed(1)}%'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: proba,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(
                                  _getColorForLevel(niveau),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ----- Boutons d'action -----
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Nouvelle évaluation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: () {
                // TODO: Enregistrer dans l'historique
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Résultat enregistré')),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer dans l\'historique'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Color _getColorForLevel(int niveau) {
    switch (niveau) {
      case 1: return const Color(0xFFe74c3c);
      case 2: return const Color(0xFFe67e22);
      case 3: return const Color(0xFFf39c12);
      case 4: return const Color(0xFF3498db);
      case 5: return const Color(0xFF27ae60);
      default: return Colors.grey;
    }
  }
}