import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/statistique_service.dart';
import '../services/auth_service.dart';

class StatistiquesScreen extends StatefulWidget {
  const StatistiquesScreen({super.key});

  @override
  State<StatistiquesScreen> createState() => _StatistiquesScreenState();
}

class _StatistiquesScreenState extends State<StatistiquesScreen>
    with TickerProviderStateMixin {
  // ==================== ÉTATS ====================
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _selectedPeriod = 'month';
  bool _isRefreshing = false;
  
  // ✅ CACHE POUR CHARGEMENT RAPIDE
  Map<String, dynamic> _cachedGlobalStats = {};
  Map<String, dynamic> _cachedMedicationStats = {};
  Map<String, dynamic> _cachedSymptomStats = {};
  Map<String, dynamic> _cachedAppointmentStats = {};
  Map<String, dynamic> _cachedHealthStats = {};
  
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 3);
  
  // ✅ INDICATEUR DE PROGRESSION
  int _loadedCount = 0;
  final int _totalRequests = 5;
  
  Map<String, dynamic> _globalStats = {};
  Map<String, dynamic> _medicationStats = {};
  Map<String, dynamic> _symptomStats = {};
  Map<String, dynamic> _appointmentStats = {};
  Map<String, dynamic> _healthStats = {};

  // ==================== ANIMATIONS ====================
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ==================== CONTROLEURS ====================
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initAnimations();
    _loadAllStats();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ==================== CHARGEMENT OPTIMISÉ ====================
  Future<void> _loadAllStats() async {
    // ✅ Vérifier le cache
    if (_cacheTime != null && DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      setState(() {
        _globalStats = _cachedGlobalStats;
        _medicationStats = _cachedMedicationStats;
        _symptomStats = _cachedSymptomStats;
        _appointmentStats = _cachedAppointmentStats;
        _healthStats = _cachedHealthStats;
        _isLoading = false;
      });
      // ✅ Mettre à jour en arrière-plan
      _refreshInBackground();
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _loadedCount = 0;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getUserData();
      
      if (userData == null) {
        throw Exception('Veuillez vous reconnecter');
      }

      final service = StatistiqueService();
      
      // ✅ Charger en parallèle avec timeout
      final results = await Future.wait([
        _loadWithTimeout(() => service.getGlobalStats(period: _selectedPeriod)),
        _loadWithTimeout(() => service.getMedicationStats()),
        _loadWithTimeout(() => service.getSymptomStats(period: _selectedPeriod)),
        _loadWithTimeout(() => service.getAppointmentStats()),
        _loadWithTimeout(() => service.getHealthStats()),
      ]);

      // ✅ Mettre en cache
      _cachedGlobalStats = results[0];
      _cachedMedicationStats = results[1];
      _cachedSymptomStats = results[2];
      _cachedAppointmentStats = results[3];
      _cachedHealthStats = results[4];
      _cacheTime = DateTime.now();

      setState(() {
        _globalStats = results[0];
        _medicationStats = results[1];
        _symptomStats = results[2];
        _appointmentStats = results[3];
        _healthStats = results[4];
        _isLoading = false;
        _loadedCount = _totalRequests;
      });

      _animationController.forward(from: 0);
    } catch (e) {
      // ✅ Utiliser le cache en cas d'erreur
      if (_cachedGlobalStats.isNotEmpty) {
        setState(() {
          _globalStats = _cachedGlobalStats;
          _medicationStats = _cachedMedicationStats;
          _symptomStats = _cachedSymptomStats;
          _appointmentStats = _cachedAppointmentStats;
          _healthStats = _cachedHealthStats;
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Données en cache - Connexion lente';
        });
        return;
      }
      
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      _showErrorSnackbar(_errorMessage);
    }
  }

  // ✅ Méthode avec timeout
  Future<Map<String, dynamic>> _loadWithTimeout(
    Future<Map<String, dynamic>> Function() loader,
  ) async {
    try {
      return await loader().timeout(
        const Duration(seconds: 4),
        onTimeout: () => <String, dynamic>{},
      );
    } catch (e) {
      return <String, dynamic>{};
    }
  }

  // ✅ Mise à jour en arrière-plan
  Future<void> _refreshInBackground() async {
    try {
      final service = StatistiqueService();
      
      final results = await Future.wait([
        _loadWithTimeout(() => service.getGlobalStats(period: _selectedPeriod)),
        _loadWithTimeout(() => service.getMedicationStats()),
        _loadWithTimeout(() => service.getSymptomStats(period: _selectedPeriod)),
        _loadWithTimeout(() => service.getAppointmentStats()),
        _loadWithTimeout(() => service.getHealthStats()),
      ]);

      if (mounted) {
        setState(() {
          _cachedGlobalStats = results[0];
          _cachedMedicationStats = results[1];
          _cachedSymptomStats = results[2];
          _cachedAppointmentStats = results[3];
          _cachedHealthStats = results[4];
          _cacheTime = DateTime.now();
          
          // ✅ Mettre à jour les données affichées
          _globalStats = _cachedGlobalStats;
          _medicationStats = _cachedMedicationStats;
          _symptomStats = _cachedSymptomStats;
          _appointmentStats = _cachedAppointmentStats;
          _healthStats = _cachedHealthStats;
        });
      }
    } catch (e) {
      // Ignorer les erreurs en arrière-plan
    }
  }

  Future<void> _refreshStats() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    
    // ✅ Forcer le rechargement
    _cacheTime = null;
    await _loadAllStats();
    
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingScreen()
          : _hasError
              ? _buildErrorScreen()
              : RefreshIndicator(
                  onRefresh: _refreshStats,
                  color: const Color(0xFF6C63FF),
                  backgroundColor: Colors.white,
                  child: Column(
                    children: [
                      _buildPeriodSelector(),
                      if (_isRefreshing)
                        const LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                          minHeight: 2,
                        ),
                      Flexible(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              GlobalStatsTab(stats: _globalStats),
                              MedicationStatsTab(stats: _medicationStats),
                              HealthStatsTab(
                                healthStats: _healthStats,
                                symptomStats: _symptomStats,
                              ),
                              AppointmentStatsTab(stats: _appointmentStats),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // ==================== APP BAR ====================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF6C63FF),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          tooltip: 'Retour au Dashboard',
        ),
      ),
      title: const Text(
        'Statistiques',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Général'),
          Tab(text: 'Médicaments'),
          Tab(text: 'Santé'),
          Tab(text: 'Rendez-vous'),
        ],
      ),
    );
  }

  // ==================== PÉRIODE SELECTOR ====================
  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPeriodButton('Semaine', 'week'),
          const SizedBox(width: 6),
          _buildPeriodButton('Mois', 'month'),
          const SizedBox(width: 6),
          _buildPeriodButton('Année', 'year'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Flexible(
      flex: 1,
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPeriod = value);
          _cacheTime = null; // ✅ Vider le cache pour recharger
          _loadAllStats();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== ÉCRAN DE CHARGEMENT OPTIMISÉ ====================
  Widget _buildLoadingScreen() {
    final progress = _loadedCount / _totalRequests;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF8B83FF)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chargement des statistiques...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            // ✅ Barre de progression
            Container(
              width: 200,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF8B83FF)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ÉCRAN D'ERREUR ====================
  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops ! Une erreur est survenue',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _refreshStats,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Retour au Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== UTILITAIRES ====================
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Flexible(flex: 1, child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Réessayer',
          textColor: Colors.white,
          onPressed: _refreshStats,
        ),
      ),
    );
  }
}

// ==================== GLOBAL STATS TAB ====================
class GlobalStatsTab extends StatelessWidget {
  final Map<String, dynamic> stats;

  const GlobalStatsTab({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildGlobalCards(),
          const SizedBox(height: 16),
          _buildScoreCard(),
          const SizedBox(height: 16),
          _buildEvolutionChart(),
        ],
      ),
    );
  }

  Widget _buildGlobalCards() {
    final cards = [
      {
        'title': 'Médicaments',
        'value': stats['total_medicaments'] ?? 0,
        'subtitle': '${stats['medicaments_actifs'] ?? 0} actifs',
        'icon': Iconsax.health,
        'color': const Color(0xFF6C63FF),
        'gradient': const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8B83FF)],
        ),
      },
      {
        'title': 'Rendez-vous',
        'value': stats['total_rendezvous'] ?? 0,
        'subtitle': '${stats['rendezvous_a_venir'] ?? 0} à venir',
        'icon': Iconsax.calendar,
        'color': const Color(0xFF10B981),
        'gradient': const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF34D399)],
        ),
      },
      {
        'title': 'Symptômes',
        'value': stats['total_symptomes'] ?? 0,
        'subtitle': '${stats['symptomes_mois'] ?? 0} ce mois',
        'icon': Iconsax.health,
        'color': const Color(0xFFF59E0B),
        'gradient': const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        ),
      },
      {
        'title': 'Taux complétion',
        'value': '${stats['taux_completion'] ?? 0}%',
        'subtitle': 'Médicaments pris',
        'icon': Iconsax.tick_circle,
        'color': const Color(0xFF3B82F6),
        'gradient': const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
        ),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Container(
          decoration: BoxDecoration(
            gradient: card['gradient'] as Gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (card['color'] as Color).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    card['icon'] as IconData,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card['value'].toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      card['title'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      card['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreCard() {
    final score = stats['score_sante'] ?? 0;
    final status = score >= 80 ? 'Excellent' : score >= 60 ? 'Bon' : 'À améliorer';
    final color = score >= 80
        ? Colors.green
        : score >= 60
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.shade200,
                  color: color,
                ),
              ),
              Column(
                children: [
                  Text(
                    '$score%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Score de santé',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Basé sur vos données médicales, vos suivis et votre activité',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Membre depuis ${DateFormat('MMMM yyyy').format(DateTime.now())}',
                    style: TextStyle(
                      fontSize: 9,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionChart() {
    final evolution = stats['evolution_mensuelle'] ?? [];
    
    if (evolution.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 Évolution mensuelle',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.chart_2,
                      size: 32,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Aucune donnée d\'évolution',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final List<FlSpot> spots = [];
    for (int i = 0; i < evolution.length; i++) {
      final item = evolution[i];
      final value = (item['total'] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), value));
    }

    final double maxY = spots.isEmpty 
        ? 10.0 
        : (spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 2).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 Évolution mensuelle',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < evolution.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              evolution[index]['mois'] ?? '',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                minX: 0,
                maxX: (evolution.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF6C63FF),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(
                      show: true,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== MEDICATION STATS TAB ====================
class MedicationStatsTab extends StatelessWidget {
  final Map<String, dynamic> stats;

  const MedicationStatsTab({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMedicationSummary(),
          const SizedBox(height: 16),
          _buildCategoryChart(),
          const SizedBox(height: 16),
          _buildTopMedications(),
        ],
      ),
    );
  }

  Widget _buildMedicationSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            label: 'Total',
            value: (stats['total'] ?? 0).toString(),
            color: const Color(0xFF6C63FF),
          ),
          _buildSummaryItem(
            label: 'Actifs',
            value: (stats['actifs'] ?? 0).toString(),
            color: const Color(0xFF10B981),
          ),
          _buildSummaryItem(
            label: 'Terminés',
            value: (stats['termines'] ?? 0).toString(),
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChart() {
    final categories = stats['par_categorie'] ?? [];
    
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Répartition par catégorie',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.chart_1,
                      size: 28,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Aucune catégorie disponible',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF3B82F6),
    ];

    final total = stats['total'] ?? 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Répartition par catégorie',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: categories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value;
                  final value = (category['total'] ?? 0).toDouble();
                  final percentage = (value / total) * 100;
                  
                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: value,
                    title: '${percentage.toStringAsFixed(1)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                startDegreeOffset: -90,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: categories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors[index % colors.length].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      category['categorie'] ?? 'Non catégorisé',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors[index % colors.length],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${category['total']})',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors[index % colors.length].withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMedications() {
    final meds = stats['frequence_plus_utilisee'] ?? [];
    
    if (meds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Iconsax.health, size: 36, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Aucun médicament enregistré',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 Médicaments les plus utilisés',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(meds.length > 5 ? 5 : meds.length, (index) {
            final med = meds[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF8B83FF)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      med['nom'] ?? 'Médicament ${index + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${med['total']} prises',
                      style: TextStyle(
                        fontSize: 10,
                        color: const Color(0xFF6C63FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ==================== HEALTH STATS TAB ====================
class HealthStatsTab extends StatelessWidget {
  final Map<String, dynamic> healthStats;
  final Map<String, dynamic> symptomStats;

  const HealthStatsTab({
    super.key,
    required this.healthStats,
    required this.symptomStats,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHealthIndicators(),
          const SizedBox(height: 16),
          _buildIMCCard(),
          const SizedBox(height: 16),
          _buildRecommendations(),
          const SizedBox(height: 16),
          _buildSymptomStats(),
        ],
      ),
    );
  }

  Widget _buildHealthIndicators() {
    final indicators = healthStats['indicateurs'] ?? {};
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Indicateurs de santé',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildIndicatorItem(
                label: 'Taille',
                value: '${indicators['taille'] ?? '-'} cm',
                color: const Color(0xFF3B82F6),
              ),
              _buildIndicatorItem(
                label: 'Poids',
                value: '${indicators['poids'] ?? '-'} kg',
                color: const Color(0xFF10B981),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildIndicatorItem(
                label: 'Âge',
                value: '${indicators['age'] ?? '-'} ans',
                color: const Color(0xFFF59E0B),
              ),
              _buildIndicatorItem(
                label: 'Groupe sanguin',
                value: indicators['groupe_sanguin'] ?? '-',
                color: const Color(0xFFEF4444),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Flexible(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIMCCard() {
    final imc = healthStats['imc'];
    final status = healthStats['statut'] ?? {};
    final poidsIdeal = healthStats['poids_ideal'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8B83FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Indice de Masse Corporelle',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    imc != null ? imc.toString() : 'Non calculé',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status['label'] ?? 'Normal',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (poidsIdeal != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.weight,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Poids idéal: $poidsIdeal kg',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = healthStats['recommandations'] ?? [];
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Iconsax.lamp, color: Color(0xFFF59E0B), size: 18),
              SizedBox(width: 6),
              Text(
                '💡 Recommandations',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...recommendations.map((rec) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        rec,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSymptomStats() {
    final total = symptomStats['total'] ?? 0;
    final levels = symptomStats['par_niveau'] ?? [];
    
    final List<Map<String, dynamic>> levelList = [];
    
    if (levels is List) {
      for (var item in levels) {
        if (item is Map) {
          final niveau = (item['niveau'] ?? 0) is int 
              ? (item['niveau'] ?? 0) as int
              : int.tryParse(item['niveau']?.toString() ?? '0') ?? 0;
          
          final totalItem = (item['total'] ?? 0) is int
              ? (item['total'] ?? 0) as int
              : int.tryParse(item['total']?.toString() ?? '0') ?? 0;
          
          levelList.add({
            'niveau': niveau,
            'total': totalItem,
          });
        }
      }
    }

    int leger = 0;
    int modere = 0;
    int severe = 0;
    
    for (var level in levelList) {
      final niveau = level['niveau'] as int;
      final total = level['total'] as int;
      
      if (niveau <= 3) {
        leger += total;
      } else if (niveau <= 6) {
        modere += total;
      } else {
        severe += total;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🩺 Symptômes enregistrés',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildSymptomLevel(
                label: 'Léger',
                count: leger,
                color: Colors.green,
              ),
              _buildSymptomLevel(
                label: 'Modéré',
                count: modere,
                color: Colors.orange,
              ),
              _buildSymptomLevel(
                label: 'Sévère',
                count: severe,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total: $total symptômes enregistrés',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomLevel({
    required String label,
    required int count,
    required Color color,
  }) {
    return Flexible(
      flex: 1,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== APPOINTMENT STATS TAB ====================
class AppointmentStatsTab extends StatelessWidget {
  final Map<String, dynamic> stats;

  const AppointmentStatsTab({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.calendar_1,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun rendez-vous',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore de rendez-vous enregistré',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAppointmentSummary(),
          const SizedBox(height: 16),
          _buildAppointmentChart(),
          const SizedBox(height: 16),
          _buildUpcomingAppointments(),
        ],
      ),
    );
  }

  Widget _buildAppointmentSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAppointmentItem(
            label: 'Total',
            value: (stats['total'] ?? 0).toString(),
            color: const Color(0xFF6C63FF),
          ),
          _buildAppointmentItem(
            label: 'À venir',
            value: (stats['a_venir'] ?? 0).toString(),
            color: const Color(0xFF10B981),
          ),
          _buildAppointmentItem(
            label: 'Passés',
            value: (stats['passes'] ?? 0).toString(),
            color: const Color(0xFFF59E0B),
          ),
          _buildAppointmentItem(
            label: 'Assiduité',
            value: '${stats['taux_assiduite'] ?? 0}%',
            color: const Color(0xFF3B82F6),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentChart() {
    final parMois = stats['par_mois'] ?? [];
    
    if (parMois.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Rendez-vous par mois',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.chart_1,
                      size: 28,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Aucune donnée de rendez-vous',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < parMois.length; i++) {
      final item = parMois[i];
      final value = (item['total'] ?? 0).toDouble();
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: value,
              color: const Color(0xFF6C63FF),
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    final double maxY = barGroups.isEmpty 
        ? 5.0 
        : (barGroups.map((e) => e.barRods.first.toY).reduce((a, b) => a > b ? a : b) + 2).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Rendez-vous par mois',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()} rendez-vous',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < parMois.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              parMois[index]['mois'] ?? '',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    final appointments = stats['prochains_rendezvous'] ?? [];
    
    if (appointments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Iconsax.calendar, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Aucun rendez-vous à venir',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 Prochains rendez-vous',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 10),
          ...appointments.map((appointment) => Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment['titre'] ?? 'Rendez-vous',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Dr. ${appointment['medecin_nom'] ?? 'Inconnu'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('dd/MM/yyyy').format(
                            DateTime.parse(appointment['date_heure']),
                          ),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm').format(
                            DateTime.parse(appointment['date_heure']),
                          ),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}