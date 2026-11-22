// lib/widgets/symptome_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import '../models/symptome.dart';

class SymptomeCard extends StatelessWidget {
  final Symptome symptome;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onResolve;

  const SymptomeCard({
    super.key,
    required this.symptome,
    required this.onTap,
    required this.onDelete,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: symptome.severityColor.withOpacity(0.1),
        highlightColor: symptome.severityColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicateur de sévérité
              Container(
                width: 5,
                height: 50,
                decoration: BoxDecoration(
                  color: symptome.severityColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),

              // ✅ CONTENU PRINCIPAL - Utiliser Flexible au lieu de Expanded
              Flexible(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      symptome.description,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildTag(
                          text: symptome.typeLabel,
                          color: Colors.blue.shade700,
                          icon: symptome.typeIcon,
                        ),
                        _buildTag(
                          text: symptome.statusLabel,
                          color: symptome.statusColor,
                          icon: Icons.circle,
                        ),
                        _buildTag(
                          text: '${symptome.niveau}/10',
                          color: symptome.severityColor,
                          icon: Icons.star,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(
                            symptome.dateEnregistrement,
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (symptome.status != 'resolu')
                    _buildActionButton(
                      icon: Icons.check_circle_outline_rounded,
                      color: Colors.green,
                      onPressed: onResolve,
                      tooltip: 'Marquer comme résolu',
                    ),
                  _buildActionButton(
                    icon: Icons.delete_outline_rounded,
                    color: Colors.red,
                    onPressed: onDelete,
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 18),
        onPressed: onPressed,
        tooltip: tooltip,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        splashRadius: 20,
        highlightColor: color.withOpacity(0.1),
      ),
    );
  }

  Widget _buildTag({
    required String text,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 10),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}