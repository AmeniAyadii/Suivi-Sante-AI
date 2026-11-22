// lib/screens/goals/health_goals_page.dart
// Version: 2.0.8 - CORRECTION DES ERREURS

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:suivi_sante_pro/models/goal.dart';
import 'package:suivi_sante_pro/models/challenge.dart';
import 'package:suivi_sante_pro/models/achievement.dart';
import 'package:suivi_sante_pro/widgets/goal_card.dart';
import 'package:suivi_sante_pro/widgets/challenge_card.dart';
import 'package:suivi_sante_pro/widgets/achievement_badge.dart';
import 'package:suivi_sante_pro/screens/goals/add_goal_page.dart';
import 'package:suivi_sante_pro/screens/goals/goal_detail_page.dart';
import 'package:suivi_sante_pro/providers/goals_provider.dart';

// ============================================================
// LOGGER UTILITY
// ============================================================
class GoalsLogger {
  static const String _tag = '🏆 HEALTH_GOALS';

  static void info(String message) {
    debugPrint('$_tag ℹ️ $message');
  }

  static void success(String message) {
    debugPrint('$_tag ✅ $message');
  }

  static void warning(String message) {
    debugPrint('$_tag ⚠️ $message');
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    debugPrint('$_tag ❌ $message');
    if (error != null) debugPrint('$_tag 📍 Error: $error');
    if (stackTrace != null) debugPrint('$_tag 📍 Stack: $stackTrace');
  }

  static void lifecycle(String message) {
    debugPrint('$_tag 🔄 $message');
  }

  static void data(String message) {
    debugPrint('$_tag 📊 $message');
  }

  static void navigation(String message) {
    debugPrint('$_tag 🧭 $message');
  }
}

// ============================================================
// MAIN PAGE
// ============================================================
class HealthGoalsPage extends StatefulWidget {
  const HealthGoalsPage({Key? key}) : super(key: key);

  @override
  State<HealthGoalsPage> createState() => _HealthGoalsPageState();
}

class _HealthGoalsPageState extends State<HealthGoalsPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isInitialLoad = true;
  DateTime? _lastRefreshTime;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    GoalsLogger.lifecycle('Page initialisée');

    _initControllers();
    _loadData();

    WidgetsBinding.instance.addObserver(this);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _handlePostFrame();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    GoalsLogger.lifecycle('Page disposée');

    _tabController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_isDisposed) return;

    GoalsLogger.lifecycle('App lifecycle: $state');

    if (state == AppLifecycleState.resumed) {
      _handleAppResume();
    }
  }

  void _initControllers() {
    _tabController = TabController(length: 3, vsync: this);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _tabController.addListener(() {
      if (_tabController.indexIsChanging && !_isDisposed) {
        GoalsLogger.navigation('Onglet changé vers: ${_tabController.index}');
      }
    });
  }

  void _loadData() {
    if (_isDisposed) return;

    GoalsLogger.info('Chargement initial des données');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || !mounted) return;

      try {
        final provider = context.read<GoalsProvider>();
        provider.loadGoals();
        provider.loadChallenges();
        provider.loadAchievements();

        Future.delayed(const Duration(milliseconds: 300), () {
          if (!_isDisposed && mounted) {
            _animationController.forward();
            _isInitialLoad = false;
            GoalsLogger.success('Données chargées avec succès');
          }
        });
      } catch (e, stackTrace) {
        GoalsLogger.error(
          'Erreur lors du chargement',
          error: e,
          stackTrace: stackTrace,
        );
      }
    });
  }

  void _handlePostFrame() {
    if (_isDisposed) return;
    GoalsLogger.info('Post-frame exécuté');
    _checkForRefresh();
  }

  void _handleAppResume() {
    if (_isDisposed) return;
    GoalsLogger.info('App repris, rafraîchissement des données...');
    _refreshData();
  }

  void _checkForRefresh() {
    if (_isDisposed) return;

    final now = DateTime.now();
    if (_lastRefreshTime == null ||
        now.difference(_lastRefreshTime!).inMinutes > 5) {
      GoalsLogger.info('Rafraîchissement automatique (5min écoulées)');
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    if (_isDisposed) return;

    GoalsLogger.info('Rafraîchissement des données...');
    _lastRefreshTime = DateTime.now();

    try {
      final provider = context.read<GoalsProvider>();
      await Future.wait([
        provider.loadGoals(),
        provider.loadChallenges(),
        provider.loadAchievements(),
      ]);
      if (!_isDisposed && mounted) {
        GoalsLogger.success('Données rafraîchies avec succès');
      }
    } catch (e, stackTrace) {
      if (!_isDisposed && mounted) {
        GoalsLogger.error(
          'Erreur lors du rafraîchissement',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) return const SizedBox.shrink();

    GoalsLogger.lifecycle('Build page');

    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(context),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            GoalsLogger.navigation('Retour au Dashboard');
            Navigator.pushReplacementNamed(context, '/dashboard');
          },
          tooltip: 'Retour au Dashboard',
        ),
      ),
      title: const Text(
        '🎯 Objectifs Santé',
        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _showSearchDialog,
          tooltip: 'Rechercher un objectif',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshData,
          tooltip: 'Rafraîchir',
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
          tooltip: 'Filtrer les objectifs',
        ),
      ],
      bottom: _buildTabBar(),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: Container(
        color: Colors.white,
        child: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          indicatorWeight: 3,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 13,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events, size: 18), text: 'Objectifs'),
            Tab(icon: Icon(Icons.emoji_events, size: 18), text: 'Défis'),
            Tab(icon: Icon(Icons.star, size: 18), text: 'Récompenses'),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: TabBarView(
        controller: _tabController,
        children: const [_GoalsTab(), _ChallengesTab(), _AchievementsTab()],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToAddGoal(context),
      icon: const Icon(Icons.add, size: 22),
      label: const Text(
        'Nouvel objectif',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      tooltip: 'Créer un nouvel objectif de santé',
    );
  }

  void _navigateToAddGoal(BuildContext context) {
    if (_isDisposed) return;

    GoalsLogger.navigation('Navigation vers AddGoalPage');

    Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddGoalPage()),
        )
        .then((result) {
          if (_isDisposed) return;

          if (result == true) {
            GoalsLogger.success('Objectif créé avec succès, rechargement...');
            _refreshData();

            if (mounted) {
              _showSnackBar('🎉 Objectif créé avec succès !', Colors.green);
            }
          }
        })
        .catchError((error, stackTrace) {
          if (_isDisposed) return;

          GoalsLogger.error(
            'Erreur lors de la création',
            error: error,
            stackTrace: stackTrace,
          );
          if (mounted) {
            _showSnackBar('❌ Erreur: ${error.toString()}', Colors.red);
          }
        });
  }

  void _showSearchDialog() {
    if (_isDisposed) return;

    GoalsLogger.navigation('Ouverture de la recherche');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('🔍 Rechercher un objectif'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Titre, description...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              Navigator.pop(context, value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final textField =
                    context
                            .findAncestorWidgetOfExactType<AlertDialog>()
                            ?.content
                        as TextField?;
                Navigator.pop(context, textField?.controller?.text ?? '');
              },
              child: const Text('Rechercher'),
            ),
          ],
        );
      },
    ).then((result) {
      if (result != null && result is String && result.isNotEmpty) {
        final provider = context.read<GoalsProvider>();
        // Utiliser le filtre existant ou ajouter une méthode de recherche
        provider.setCategoryFilter(null);
        // Ici vous pouvez ajouter une méthode de recherche si nécessaire
        _showSnackBar('🔍 Recherche: "$result"', Colors.blue);
      }
    });
  }

  void _showFilterDialog() {
    if (_isDisposed) return;

    GoalsLogger.navigation('Ouverture du filtre');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FilterBottomSheet(
          onApply: (category, status) {
            if (_isDisposed) return;
            GoalsLogger.data('Filtres appliqués - Catégorie: $category');
            final provider = context.read<GoalsProvider>();
            provider.setCategoryFilter(category);
            // Note: provider.setStatusFilter(status); // À ajouter si nécessaire
          },
          onClear: () {
            if (_isDisposed) return;
            GoalsLogger.data('Filtres effacés');
            final provider = context.read<GoalsProvider>();
            provider.setCategoryFilter(null);
            // Note: provider.setStatusFilter(null); // À ajouter si nécessaire
          },
        );
      },
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (_isDisposed || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ============================================================
// TAB 1: OBJECTIFS
// ============================================================
class _GoalsTab extends StatelessWidget {
  const _GoalsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.goals.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.blue, strokeWidth: 3),
                SizedBox(height: 16),
                Text(
                  'Chargement de vos objectifs...',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[300],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Une erreur est survenue',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    provider.error!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    provider.loadGoals();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final goals = provider.filteredGoals;

        if (goals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.grey,
                  child: Icon(
                    Icons.emoji_events,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucun objectif',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez votre premier objectif pour commencer\nvotre suivi santé',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddGoalPage()),
                    ).then((_) {
                      provider.loadGoals();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Créer mon premier objectif'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.loadGoals,
          color: Colors.blue,
          backgroundColor: Colors.white,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildMissionCard(context, goals),
              const SizedBox(height: 16),
              _buildQuickStats(context, provider),
              const SizedBox(height: 16),
              _buildFilterBar(context, provider),
              const SizedBox(height: 16),
              ...goals
                  .map(
                    (goal) => GoalCard(
                      goal: goal,
                      onTap: () => _navigateToGoalDetail(context, goal),
                      onUpdate: () =>
                          _showUpdateProgressDialog(context, goal, provider),
                      onDelete: () =>
                          _showDeleteConfirmation(context, goal, provider),
                    ),
                  )
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMissionCard(BuildContext context, List<Goal> goals) {
    final goal = goals.firstWhere(
      (g) => g.status == GoalStatus.inProgress,
      orElse: () => goals.first,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF3F3D9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MISSION DU MOIS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        goal.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${goal.progressPercentage}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progress,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal.currentValue} / ${goal.targetValue} ${goal.unit}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Row(
                  children: [
                    Icon(Icons.timer, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      goal.timeRemaining,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, GoalsProvider provider) {
    final completedCount = provider.completedGoalsCount;
    final totalCount = provider.goals.length;
    final avgProgress = provider.averageProgress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickStat(
            icon: Icons.check_circle,
            color: Colors.green,
            value: '$completedCount',
            label: 'Complétés',
          ),
          _buildQuickStat(
            icon: Icons.pending,
            color: Colors.orange,
            value: '${totalCount - completedCount}',
            label: 'En cours',
          ),
          _buildQuickStat(
            icon: Icons.trending_up,
            color: Colors.blue,
            value: '${avgProgress.toStringAsFixed(0)}%',
            label: 'Progression',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context, GoalsProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: '📋 Tous',
            isSelected: provider.selectedCategory == null,
            onSelected: () {
              provider.setCategoryFilter(null);
            },
          ),
          ...GoalCategory.values.map(
            (category) => _FilterChip(
              label: _getCategoryLabel(category),
              isSelected: provider.selectedCategory == category,
              onSelected: () {
                provider.setCategoryFilter(category);
              },
            ),
          ),
        ],
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

  void _navigateToGoalDetail(BuildContext context, Goal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GoalDetailPage(goal: goal)),
    ).then((_) {
      context.read<GoalsProvider>().loadGoals();
    });
  }

  void _showUpdateProgressDialog(
    BuildContext context,
    Goal goal,
    GoalsProvider provider,
  ) {
    final controller = TextEditingController(
      text: goal.currentValue.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Text(goal.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Mettre à jour: ${goal.title}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
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
                    _buildProgressInfo(
                      'Actuel',
                      '${goal.currentValue} ${goal.unit}',
                      Colors.blue,
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.blue),
                    _buildProgressInfo(
                      'Objectif',
                      '${goal.targetValue} ${goal.unit}',
                      Colors.green,
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
                  suffixText: goal.unit,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.edit),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null) {
                  provider.updateGoalProgress(goal.id, value);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Progression mise à jour !'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Veuillez entrer une valeur valide'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Goal goal,
    GoalsProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('🗑️ Supprimer l\'objectif'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voulez-vous vraiment supprimer cet objectif ?',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(goal.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        goal.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '⚠️ Cette action est irréversible.',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                provider.deleteGoal(goal.id);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🗑️ Objectif supprimé'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.delete),
              label: const Text('Supprimer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// FILTER CHIP
// ============================================================
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        backgroundColor: Colors.grey[100],
        selectedColor: Colors.blue.withOpacity(0.15),
        checkmarkColor: Colors.blue,
        labelStyle: TextStyle(
          color: isSelected ? Colors.blue : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        avatar: isSelected
            ? const Icon(Icons.check, color: Colors.blue, size: 16)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TAB 2: DÉFIS
// ============================================================
class _ChallengesTab extends StatelessWidget {
  const _ChallengesTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingChallenges) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.blue, strokeWidth: 3),
                SizedBox(height: 16),
                Text(
                  'Chargement des défis...',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final challenges = provider.challenges;

        if (challenges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.grey,
                  child: Icon(
                    Icons.emoji_events,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucun défi disponible',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Revenez plus tard pour découvrir de nouveaux défis\net relever des challenges !',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.loadChallenges,
          color: Colors.blue,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              return ChallengeCard(
                challenge: challenge,
                onJoin: () {
                  provider.joinChallenge(challenge.id);
                },
                onShare: () {
                  _shareChallenge(context, challenge);
                },
                onViewDetails: () {
                  _showChallengeDetails(context, challenge);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _shareChallenge(BuildContext context, Challenge challenge) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📤 Partage du défi: ${challenge.title}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showChallengeDetails(BuildContext context, Challenge challenge) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${challenge.icon} ${challenge.title}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(challenge.description, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
              _buildDetailRow(
                '👥 Participants',
                '${challenge.participantsCount}',
              ),
              _buildDetailRow('📊 Complétion', '${challenge.completionRate}%'),
              _buildDetailRow('⏰ Restant', challenge.daysRemaining),
              if (challenge.rewards.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  '🎁 Récompenses:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...challenge.rewards.map(
                  (reward) => Text(
                    '• ${reward.title} (+${reward.value} pts)',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
            if (!challenge.isJoined && challenge.isActive)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<GoalsProvider>().joinChallenge(challenge.id);
                },
                child: const Text('Rejoindre'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 3: RÉCOMPENSES
// ============================================================
class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingAchievements) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.blue, strokeWidth: 3),
                SizedBox(height: 16),
                Text(
                  'Chargement des récompenses...',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final achievements = provider.achievements;

        if (achievements.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.grey,
                  child: Icon(
                    Icons.emoji_events,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Aucune récompense débloquée',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Atteignez vos objectifs pour gagner\ndes récompenses et des badges !',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final unlockedCount = achievements.where((a) => a.isUnlocked).length;
        final totalPoints = achievements
            .where((a) => a.isUnlocked)
            .fold<int>(0, (sum, a) => sum + a.points);

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber[50]!, Colors.amber[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAchievementStat(
                    '$unlockedCount/${achievements.length}',
                    'Débloquées',
                    Icons.stars,
                    Colors.amber[700]!,
                  ),
                  _buildAchievementStat(
                    '$totalPoints',
                    'Points totaux',
                    Icons.emoji_events,
                    Colors.blue[700]!,
                  ),
                  _buildAchievementStat(
                    '${provider.currentStreak}',
                    'Série actuelle',
                    Icons.local_fire_department,
                    Colors.red[700]!,
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 1,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  return GestureDetector(
                    onTap: () => _showAchievementDetail(context, achievement),
                    child: AchievementBadge(
                      achievement: achievement,
                      isLocked: !achievement.isUnlocked,
                      showTooltip: true,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAchievementStat(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  void _showAchievementDetail(BuildContext context, Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${achievement.icon} ${achievement.title}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.description,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildInfoRow('📂 Type', achievement.typeDisplay),
              _buildInfoRow('⭐ Niveau', '${achievement.level}'),
              _buildInfoRow('💎 Points', '${achievement.points} pts'),
              if (achievement.isUnlocked && achievement.unlockedAt != null)
                _buildInfoRow(
                  '📅 Débloqué le',
                  DateFormat('dd/MM/yyyy').format(achievement.unlockedAt!),
                )
              else
                _buildInfoRow('🔒 Statut', 'Non débloqué'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FILTER BOTTOM SHEET
// ============================================================
class FilterBottomSheet extends StatefulWidget {
  final Function(GoalCategory?, GoalStatus?) onApply;
  final VoidCallback onClear;

  const FilterBottomSheet({
    Key? key,
    required this.onApply,
    required this.onClear,
  }) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  GoalCategory? _selectedCategory;
  GoalStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtrer les objectifs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  widget.onClear();
                  Navigator.pop(context);
                },
                child: const Text('Effacer'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Catégorie',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _FilterOption(
                label: '📋 Toutes',
                isSelected: _selectedCategory == null,
                onTap: () {
                  setState(() => _selectedCategory = null);
                },
              ),
              ...GoalCategory.values.map(
                (category) => _FilterOption(
                  label: _getCategoryLabel(category),
                  isSelected: _selectedCategory == category,
                  onTap: () {
                    setState(() => _selectedCategory = category);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Statut',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _FilterOption(
                label: '📋 Tous',
                isSelected: _selectedStatus == null,
                onTap: () {
                  setState(() => _selectedStatus = null);
                },
              ),
              ...GoalStatus.values.map(
                (status) => _FilterOption(
                  label: _getStatusLabel(status),
                  isSelected: _selectedStatus == status,
                  onTap: () {
                    setState(() => _selectedStatus = status);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_selectedCategory, _selectedStatus);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Appliquer les filtres',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
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

  String _getStatusLabel(GoalStatus status) {
    switch (status) {
      case GoalStatus.notStarted:
        return '📋 Pas commencé';
      case GoalStatus.inProgress:
        return '⚡ En cours';
      case GoalStatus.completed:
        return '✅ Terminé';
      case GoalStatus.failed:
        return '❌ Échoué';
    }
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
