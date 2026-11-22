// lib/screens/goals/goal_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:suivi_sante_pro/models/goal.dart';
import 'package:suivi_sante_pro/providers/goals_provider.dart';
import 'package:suivi_sante_pro/screens/goals/add_goal_page.dart';

class GoalDetailPage extends StatefulWidget {
  final Goal goal;

  const GoalDetailPage({Key? key, required this.goal}) : super(key: key);

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.goal.progress,
    ).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(
      int.parse(widget.goal.colorHex.replaceFirst('#', ''), radix: 16),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
          tooltip: 'Retour au Dashboard',
        ),
        title: Text(widget.goal.title),
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditGoal(context),
          ),
          IconButton(icon: const Icon(Icons.share), onPressed: _shareGoal),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(color),
            const SizedBox(height: 16),

            // Progression
            _buildProgressSection(color),
            const SizedBox(height: 16),

            // Détails
            _buildDetailsSection(),
            const SizedBox(height: 16),

            // Milestones
            if (widget.goal.milestones.isNotEmpty) _buildMilestonesSection(),

            // Statistiques
            _buildStatsSection(),
            const SizedBox(height: 16),

            // Actions
            _buildActionsSection(color),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    widget.goal.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.goal.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCategoryLabel(widget.goal.category),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          if (widget.goal.description != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.goal.description!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String label;
    IconData icon;

    if (widget.goal.isCompleted) {
      badgeColor = Colors.green;
      label = 'Terminé';
      icon = Icons.check_circle;
    } else if (widget.goal.isOverdue) {
      badgeColor = Colors.red;
      label = 'En retard';
      icon = Icons.warning;
    } else {
      switch (widget.goal.status) {
        case GoalStatus.inProgress:
          badgeColor = Colors.blue;
          label = 'En cours';
          icon = Icons.play_circle;
          break;
        case GoalStatus.notStarted:
          badgeColor = Colors.grey;
          label = 'Pas commencé';
          icon = Icons.pending;
          break;
        default:
          badgeColor = Colors.grey;
          label = 'Non défini';
          icon = Icons.help;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: badgeColor, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progression',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Text(
                      '${(_progressAnimation.value * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progressAnimation.value,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 12,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actuel',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '${widget.goal.currentValue} ${widget.goal.unit}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Objectif',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '${widget.goal.targetValue} ${widget.goal.unit}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (widget.goal.targetDate != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.goal.isOverdue
                      ? Colors.red[50]
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.goal.isOverdue
                        ? Colors.red[200]!
                        : Colors.blue[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.goal.isOverdue ? Icons.warning : Icons.timer,
                      color: widget.goal.isOverdue ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 1,
                      child: Text(
                        widget.goal.isOverdue
                            ? '⚠️ Objectif dépassé de ${widget.goal.targetDate!.difference(DateTime.now()).inDays.abs()} jours'
                            : '📅 ${widget.goal.timeRemaining}',
                        style: TextStyle(
                          color: widget.goal.isOverdue
                              ? Colors.red[800]
                              : Colors.blue[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations détaillées',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              '📅 Date de début',
              DateFormat('dd/MM/yyyy').format(widget.goal.startDate),
            ),
            const Divider(),
            _buildInfoRow(
              '🎯 Date cible',
              widget.goal.targetDate != null
                  ? DateFormat('dd/MM/yyyy').format(widget.goal.targetDate!)
                  : 'Non définie',
            ),
            const Divider(),
            _buildInfoRow(
              '📊 Catégorie',
              _getCategoryLabel(widget.goal.category),
            ),
            const Divider(),
            _buildInfoRow(
              '🔄 Récurrent',
              widget.goal.isRecurring
                  ? 'Oui (${_getRecurrenceLabel(widget.goal.recurrencePattern)})'
                  : 'Non',
            ),
            const Divider(),
            _buildInfoRow(
              '📈 Progression',
              '${widget.goal.progressPercentage}%',
            ),
            if (widget.goal.reminders.isNotEmpty) ...[
              const Divider(),
              _buildInfoRow(
                '🔔 Rappels',
                '${widget.goal.reminders.length} configurés',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📌 Étapes intermédiaires',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...widget.goal.milestones.map((milestone) {
              final isCompleted =
                  milestone.isCompleted ||
                  widget.goal.currentValue >= milestone.targetValue;

              return ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green[100] : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.radio_button_unchecked,
                    color: isCompleted ? Colors.green : Colors.grey,
                    size: 18,
                  ),
                ),
                title: Text(
                  milestone.title,
                  style: TextStyle(
                    fontWeight: isCompleted
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isCompleted ? Colors.green[800] : null,
                  ),
                ),
                subtitle: Text(
                  'Valeur: ${milestone.targetValue} ${widget.goal.unit}',
                  style: TextStyle(
                    color: isCompleted ? Colors.green[600] : Colors.grey[600],
                  ),
                ),
                trailing: isCompleted
                    ? Icon(Icons.star, color: Colors.amber[600], size: 20)
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Statistiques',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '${widget.goal.progressPercentage}%',
                  'Progression',
                  Icons.trending_up,
                  Colors.blue,
                ),
                _buildStatItem(
                  widget.goal.timeRemaining,
                  'Temps restant',
                  Icons.timer,
                  Colors.orange,
                ),
                _buildStatItem(
                  '${widget.goal.milestones.where((m) => m.isCompleted).length}/${widget.goal.milestones.length}',
                  'Étapes complétées',
                  Icons.flag,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionsSection(Color color) {
    return Row(
      children: [
        Flexible(
          flex: 1,
          child: ElevatedButton.icon(
            onPressed: () => _showUpdateProgressDialog(context),
            icon: const Icon(Icons.update),
            label: const Text('Mettre à jour'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: OutlinedButton.icon(
            onPressed: _shareGoal,
            icon: const Icon(Icons.share),
            label: const Text('Partager'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }

  void _showUpdateProgressDialog(BuildContext context) {
    final controller = TextEditingController(
      text: widget.goal.currentValue.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('📈 Mettre à jour: ${widget.goal.title}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Actuel',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${widget.goal.currentValue} ${widget.goal.unit}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.blue),
                    Column(
                      children: [
                        Text(
                          'Objectif',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${widget.goal.targetValue} ${widget.goal.unit}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nouvelle valeur',
                  suffixText: widget.goal.unit,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.edit),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null) {
                  final provider = context.read<GoalsProvider>();
                  provider.updateGoalProgress(widget.goal.id, value);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Progression mise à jour !'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToEditGoal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddGoalPage(goalId: widget.goal.id)),
    ).then((result) {
      if (result == true) {
        // Recharger les données
        context.read<GoalsProvider>().loadGoals();
        // Recharger la page (ou naviguer vers le détail mis à jour)
      }
    });
  }

  void _shareGoal() {
    // Implémentation du partage
    final shareText =
        '''
🎯 Objectif Santé
-----------------
${widget.goal.icon} ${widget.goal.title}
📊 Progression: ${widget.goal.progressPercentage}%
📈 ${widget.goal.currentValue}/${widget.goal.targetValue} ${widget.goal.unit}
📅 ${widget.goal.timeRemaining}

#ObjectifSanté #SuiviMédical #MediTrackAI
''';

    // Utiliser share_plus package ou autre
    // Share.share(shareText);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📤 Progression copiée dans le presse-papiers'),
      ),
    );
  }

  String _getCategoryLabel(GoalCategory category) {
    switch (category) {
      case GoalCategory.medication:
        return '💊 Médicaments';
      case GoalCategory.exercise:
        return '🏃 Sport';
      case GoalCategory.nutrition:
        return '🍎 Nutrition';
      case GoalCategory.sleep:
        return '😴 Sommeil';
      case GoalCategory.hydration:
        return '💧 Hydratation';
      case GoalCategory.weight:
        return '⚖️ Poids';
      case GoalCategory.bloodPressure:
        return '❤️ Tension';
      case GoalCategory.bloodSugar:
        return '🩸 Glycémie';
      case GoalCategory.stress:
        return '🧘 Stress';
      default:
        return '📌 Autre';
    }
  }

  String _getRecurrenceLabel(String? pattern) {
    switch (pattern) {
      case 'daily':
        return 'Quotidien';
      case 'weekly':
        return 'Hebdomadaire';
      case 'monthly':
        return 'Mensuel';
      default:
        return 'Non défini';
    }
  }
}
