import 'package:flutter/material.dart';
import '../models/goal.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;
  final VoidCallback? onUpdate;
  final VoidCallback? onDelete;

  const GoalCard({
    Key? key,
    required this.goal,
    this.onTap,
    this.onUpdate,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(goal.colorHex.replaceFirst('#', ''), radix: 16));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        goal.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${goal.currentValue} / ${goal.targetValue} ${goal.unit}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(goal).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(goal),
                      style: TextStyle(
                        fontSize: 11,
                        color: _getStatusColor(goal),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${goal.progressPercentage}% accompli',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      if (goal.isOverdue)
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 16,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        goal.timeRemaining,
                        style: TextStyle(
                          fontSize: 12,
                          color: goal.isOverdue ? Colors.orange : Colors.grey[600],
                          fontWeight: goal.isOverdue ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (goal.milestones.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: goal.milestones.map((milestone) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: milestone.isCompleted 
                            ? Colors.green[100] 
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            milestone.isCompleted 
                                ? Icons.check_circle 
                                : Icons.radio_button_unchecked,
                            size: 14,
                            color: milestone.isCompleted 
                                ? Colors.green[700] 
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            milestone.title,
                            style: TextStyle(
                              fontSize: 11,
                              color: milestone.isCompleted 
                                  ? Colors.green[800] 
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (onUpdate != null || onDelete != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onUpdate != null)
                      TextButton(
                        onPressed: onUpdate,
                        child: const Text('Mettre à jour'),
                      ),
                    if (onDelete != null)
                      TextButton(
                        onPressed: onDelete,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Supprimer'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(Goal goal) {
    if (goal.isCompleted) return Colors.green;
    if (goal.isOverdue) return Colors.orange;
    switch (goal.status) {
      case GoalStatus.inProgress:
        return Colors.blue;
      case GoalStatus.notStarted:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(Goal goal) {
    if (goal.isCompleted) return '✅ Terminé';
    if (goal.isOverdue) return '⚠️ En retard';
    switch (goal.status) {
      case GoalStatus.inProgress:
        return 'En cours';
      case GoalStatus.notStarted:
        return 'Pas commencé';
      default:
        return '';
    }
  }
}
