// lib/widgets/symptome_stats_card.dart

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class SymptomeStatsCard extends StatelessWidget {
  final int total;
  final int actifs;
  final int resolus;
  final double tauxResolution;

  const SymptomeStatsCard({
    super.key,
    required this.total,
    required this.actifs,
    required this.resolus,
    required this.tauxResolution,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ Utiliser Row sans Expanded problématique
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                label: 'Total',
                value: '$total',
                icon: Iconsax.chart,
                color: const Color(0xFF6C5CE7),
              ),
              _buildStatItem(
                label: 'Actifs',
                value: '$actifs',
                icon: Iconsax.clock,
                color: const Color(0xFF0984E3),
              ),
              _buildStatItem(
                label: 'Résolus',
                value: '$resolus',
                icon: Iconsax.tick_circle,
                color: const Color(0xFF00B894),
              ),
              _buildStatItem(
                label: 'Taux',
                value: '${tauxResolution.toStringAsFixed(0)}%',
                icon: Iconsax.graph,
                color: const Color(0xFFFDCB6E),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}