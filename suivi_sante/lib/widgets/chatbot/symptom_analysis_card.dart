// lib/widgets/symptom_analysis_card.dart
import 'package:flutter/material.dart';

class SymptomAnalysisCard extends StatelessWidget {
  final Map<String, dynamic> analysis;
  final Function(String) onAction;

  const SymptomAnalysisCard({
    super.key,
    required this.analysis,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final severity = analysis['severity'] ?? 'green';
    final color = _getSeverityColor(severity);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec indicateur de gravité
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getSeverityLabel(severity),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(analysis['timestamp']),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Message principal
            Text(
              analysis['message'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            
            // Contexte temporel
            if (analysis['time_context'] != null)
              _buildTimeContext(analysis['time_context']),
            
            // Comorbidités
            if (analysis['comorbidities'] != null)
              _buildComorbidities(analysis['comorbidities']),
            
            // Actions
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (analysis['actions'] as List? ?? []).map((action) {
                return ActionChip(
                  label: Text(action),
                  onPressed: () => onAction(action),
                  backgroundColor: color.withOpacity(0.1),
                  side: BorderSide(color: color),
                );
              }).toList(),
            ),
            
            // Snapshot Santé
            if (analysis['snapshot'] != null)
              _buildSnapshot(analysis['snapshot']),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeContext(Map<String, dynamic> timeContext) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.timer, color: Colors.blue),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⏰ Contexte temporel',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (timeContext['duration'] != null)
                    Text(
                      'Depuis ${timeContext['duration']} ${timeContext['unit']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComorbidities(Map<String, dynamic> comorbidities) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.medical_information, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  '📋 Contexte médical',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (comorbidities['allergies'] != null && comorbidities['allergies'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '🔴 Allergies: ${comorbidities['allergies'].join(', ')}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            if (comorbidities['chronic_conditions'] != null && comorbidities['chronic_conditions'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '🟡 Maladies chroniques: ${comorbidities['chronic_conditions'].join(', ')}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshot(Map<String, dynamic> snapshot) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.screenshot, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  '📸 Snapshot Santé',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
            Text(
              snapshot['summary'] ?? '',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'red': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getSeverityLabel(String severity) {
    switch (severity) {
      case 'green': return '🟢 Autosoins';
      case 'orange': return '🟡 Consultation';
      case 'red': return '🔴 URGENCE';
      default: return 'Non défini';
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}
