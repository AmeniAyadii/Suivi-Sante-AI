// lib/widgets/quick_actions.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback onAddMeasure;
  final VoidCallback onAnalyze;
  final bool isPremium;

  const QuickActions({
    super.key,
    required this.onAddMeasure,
    required this.onAnalyze,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actions rapides',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionButton(
                icon: FontAwesomeIcons.heartPulse,
                label: 'Mesure',
                color: Colors.blue,
                onTap: onAddMeasure,
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: FontAwesomeIcons.chartLine,
                label: 'Analyser',
                color: isPremium ? Colors.purple : Colors.grey,
                onTap: isPremium ? onAnalyze : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔒 Fonctionnalité Premium'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                isPremium: isPremium,
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: FontAwesomeIcons.calendar,
                label: 'Historique',
                color: Colors.green,
                onTap: () {
                  // Naviguer vers l'historique
                },
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: FontAwesomeIcons.robot,
                label: 'IA Chat',
                color: const Color(0xFF7C3AED),
                onTap: () {
                  // Naviguer vers le chatbot
                },
                isPremium: isPremium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isPremium;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Icon(icon, color: color, size: 24),
                  if (isPremium)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
