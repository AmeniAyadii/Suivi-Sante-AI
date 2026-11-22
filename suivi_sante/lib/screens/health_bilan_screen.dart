// lib/screens/health_bilan_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../services/health_assessment_service.dart';
import '../models/health_assessment.dart';
import 'health_assessment_form_screen.dart';
import '../services/logger_service.dart';
import '../theme/app_theme.dart';

// ============================================================
// LOGGER UTILITY
// ============================================================
class HealthBilanLogger {
  static const String _tag = '🩺 BILAN SANTÉ';

  static void info(String message) => LoggerService.info('$_tag ℹ️ $message');
  static void success(String message) => LoggerService.success('$_tag ✅ $message');
  static void warning(String message) => LoggerService.warning('$_tag ⚠️ $message');
  static void error(String message, {dynamic error, StackTrace? stackTrace}) =>
      LoggerService.error('$_tag ❌ $message', error: error, stackTrace: stackTrace);
  static void debug(String message) => LoggerService.debug('$_tag 🐛 $message');
  static void data(String message) => LoggerService.info('$_tag 📊 $message');
  static void network(String message) => LoggerService.info('$_tag 🌐 $message');
  static void navigation(String message) => LoggerService.info('$_tag 🧭 $message');
  static void animation(String message) => LoggerService.debug('$_tag 🎬 $message');
  static void ui(String message) => LoggerService.info('$_tag 🎨 $message');
}

// ============================================================
// HEALTH BILAN SCREEN
// ============================================================
class HealthBilanScreen extends StatefulWidget {
  const HealthBilanScreen({super.key});

  @override
  State<HealthBilanScreen> createState() => _HealthBilanScreenState();
}

class _HealthBilanScreenState extends State<HealthBilanScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ==================== ÉTATS ====================
  HealthAssessment? _latestAssessment;
  List<HealthAssessment> _history = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _isGridView = false;
  String _selectedPeriod = '6 mois';

  // ==================== ANIMATIONS ====================
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late AnimationController _pulseController;

  // ==================== TAB CONTROLLER ====================
  late TabController _tabController;

  // ==================== STATS ====================
  int _totalAssessments = 0;
  double _averageScore = 0;
  int _bestScore = 0;
  int _worstScore = 0;

  // ==================== THÈME ====================
  Color _primaryColor = const Color(0xFF6C5CE7);
  Color _secondaryColor = const Color(0xFFA29BFE);
  Color _surfaceColor = Colors.white;
  Color _backgroundColor = const Color(0xFFF8F9FE);
  Color _textColor = Colors.black87;
  Color _textSecondaryColor = Colors.grey;
  Color _cardShadowColor = Colors.black12;

  @override
  void initState() {
    super.initState();
    HealthBilanLogger.info('🩺 Page Bilan de santé initialisée');
    _initAnimations();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      HealthBilanLogger.navigation('📑 Onglet changé: ${_tabController.index}');
    }
  }

  void _initAnimations() {
    HealthBilanLogger.animation('🎬 Initialisation des animations');

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _slideAnimation = Tween<double>(begin: 0.2, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    HealthBilanLogger.animation('✅ Animations initialisées avec succès');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      HealthBilanLogger.info('🔄 Application reprise - Rechargement du bilan');
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_isRefreshing) return;

    HealthBilanLogger.info('🔄 Chargement des données du bilan de santé');
    final stopwatch = Stopwatch()..start();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = HealthAssessmentService();

      HealthBilanLogger.network('🌐 Appel API: getLatest()');
      final latest = await service.getLatest();
      HealthBilanLogger.success('✅ Dernier bilan récupéré avec succès');

      HealthBilanLogger.network('🌐 Appel API: getHistory()');
      final history = await service.getHistory();
      HealthBilanLogger.success('✅ Historique récupéré: ${history.length} bilans');

      _calculateStats(history);

      if (mounted) {
        setState(() {
          _latestAssessment = latest;
          _history = history;
          _isLoading = false;
          _isRefreshing = false;
          _animationController.forward();
        });
      }

      stopwatch.stop();
      HealthBilanLogger.success('✅ Données chargées en ${stopwatch.elapsedMilliseconds}ms');
    } catch (e, stackTrace) {
      HealthBilanLogger.error('❌ Erreur: $e', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          // ✅ Nettoie l'affichage de l'erreur
          _errorMessage = e.toString().replaceAll('Exception: ', ''); 
        });
      }
    }
  }

  void _calculateStats(List<HealthAssessment> history) {
    if (history.isEmpty) {
      _totalAssessments = 0;
      _averageScore = 0;
      _bestScore = 0;
      _worstScore = 0;
      return;
    }

    _totalAssessments = history.length;
    final scores = history.map((h) => h.overallScore ?? 0).toList();
    _averageScore = scores.reduce((a, b) => a + b) / scores.length;
    _bestScore = scores.reduce((a, b) => a > b ? a : b);
    _worstScore = scores.reduce((a, b) => a < b ? a : b);

    HealthBilanLogger.data('📊 Stats: Avg=${_averageScore.round()}%, Best=$_bestScore%, Worst=$_worstScore%');
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _loadData();
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  void dispose() {
    HealthBilanLogger.info('🗑️ Page Bilan de santé disposée');
    _animationController.dispose();
    _pulseController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _updateThemeColors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    HealthBilanLogger.ui('🎨 Construction du widget - Mode ${isDark ? 'Sombre' : 'Clair'}');

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildStatsBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingScreen()
                  : _errorMessage != null
                      ? _buildErrorScreen()
                      : _latestAssessment == null
                          ? _buildEmptyState()
                          : _buildMainContent(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ==================== THÈME ====================
  void _updateThemeColors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _primaryColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    _secondaryColor = isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight;
    _surfaceColor = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    _backgroundColor = isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight;
    _textColor = isDark ? AppTheme.textDark : AppTheme.textLight;
    _textSecondaryColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
    _cardShadowColor = isDark ? Colors.black.withOpacity(0.3) : AppTheme.primaryLight.withOpacity(0.1);
  }

  // ==================== APP BAR ====================
  Widget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppTheme.primaryDark, AppTheme.primaryDark.withOpacity(0.8)]
              : [AppTheme.primaryLight, AppTheme.primaryLight.withOpacity(0.9)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLight.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
              onPressed: () {
                HealthBilanLogger.navigation('🔙 Retour au Dashboard');
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
              tooltip: 'Retour au Dashboard',
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bilan de Santé',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _latestAssessment != null
                      ? 'Dernier bilan: ${DateFormat('dd/MM/yyyy').format(_latestAssessment!.assessmentDate)}'
                      : 'Aucun bilan enregistré',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(
                _isGridView ? Icons.list_rounded : Icons.grid_view_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => setState(() => _isGridView = !_isGridView),
              tooltip: _isGridView ? 'Vue en liste' : 'Vue en grille',
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              onPressed: _isRefreshing ? null : _refreshData,
              tooltip: 'Rafraîchir',
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STATS BAR ====================
  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: _surfaceColor,
      child: Row(
        children: [
          Expanded(
            child: _buildStatChip(
              icon: Iconsax.calendar,
              label: 'Total',
              value: '$_totalAssessments',
              color: AppTheme.primaryLight,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildStatChip(
              icon: Iconsax.star,
              label: 'Moy.',
              value: '${_averageScore.round()}%',
              color: AppTheme.success,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildStatChip(
              icon: Iconsax.arrow_up,
              label: 'Max',
              value: '$_bestScore%',
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildStatChip(
              icon: Iconsax.arrow_down,
              label: 'Min',
              value: '$_worstScore%',
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: GoogleFonts.inter(
              color: color.withOpacity(0.75),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CONTENU PRINCIPAL ====================
  Widget _buildMainContent() {
    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildTrendsTab(),
              _buildAnalysisTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: _surfaceColor,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: '📊 Aperçu'),
          Tab(text: '📈 Tendances'),
          Tab(text: '📋 Analyse'),
        ],
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: _textSecondaryColor,
        indicatorColor: AppTheme.primaryLight,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.normal, fontSize: 12),
      ),
    );
  }

  // ==================== ONGLET APERÇU ====================
  Widget _buildOverviewTab() {
    final assessment = _latestAssessment;
    if (assessment == null) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.primaryLight,
      backgroundColor: _surfaceColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreCard(assessment),
            const SizedBox(height: 20),
            _buildSectionTitle('📊 Paramètres vitaux'),
            const SizedBox(height: 12),
            _buildVitalParameters(assessment),
            const SizedBox(height: 20),
            _buildSectionTitle('🌿 Mode de vie'),
            const SizedBox(height: 12),
            _buildLifestyle(assessment),
            if (assessment.recommendations != null &&
                assessment.recommendations!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildRecommendations(assessment),
            ],
            if (_history.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildHistorySection(),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== ONGLET TENDANCES ====================
  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodFilter(),
          const SizedBox(height: 16),
          _buildSectionTitle('📈 Évolution du score'),
          const SizedBox(height: 12),
          _buildTrendChart(),
          const SizedBox(height: 24),
          _buildSectionTitle('📊 Progression des paramètres'),
          const SizedBox(height: 12),
          _buildParametersProgress(),
        ],
      ),
    );
  }

  // ==================== ONGLET ANALYSE ====================
  Widget _buildAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🔍 Analyse détaillée'),
          const SizedBox(height: 12),
          _buildDetailedAnalysis(),
          const SizedBox(height: 20),
          _buildSectionTitle('💡 Points d\'attention'),
          const SizedBox(height: 12),
          _buildAttentionPoints(),
          const SizedBox(height: 20),
          _buildSectionTitle('📋 Recommandations globales'),
          const SizedBox(height: 12),
          _buildGlobalRecommendations(),
        ],
      ),
    );
  }

  // ==================== PÉRIODE FILTER ====================
  Widget _buildPeriodFilter() {
    final periods = ['3 mois', '6 mois', '1 an', 'Tout'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: periods.map((period) {
        final isSelected = _selectedPeriod == period;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedPeriod = period);
            HealthBilanLogger.debug('📅 Période sélectionnée: $period');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.primaryLight : _textSecondaryColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              period,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : _textSecondaryColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==================== CARTE SCORE ====================
  Widget _buildScoreCard(HealthAssessment assessment) {
    final score = assessment.overallScore ?? 0;
    final color = _getScoreColor(score);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.9), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Score de santé global',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(assessment.assessmentDate),
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score%',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        assessment.overallScoreLabel,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getScoreSubtitle(score),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.white.withOpacity(0.2),
              color: Colors.white,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PARAMÈTRES VITAUX ====================
  Widget _buildVitalParameters(HealthAssessment assessment) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        _buildParameterCard(
          icon: Iconsax.monitor,
          label: 'IMC',
          value: assessment.bmi != null ? assessment.bmi!.toStringAsFixed(1) : '—',
          subtitle: assessment.bmiLabel,
          color: assessment.bmiColor,
        ),
        _buildParameterCard(
          icon: Iconsax.heart,
          label: 'Pression',
          value: assessment.bloodPressureSystolic != null &&
                  assessment.bloodPressureDiastolic != null
              ? '${assessment.bloodPressureSystolic}/${assessment.bloodPressureDiastolic}'
              : '—',
          subtitle: assessment.bloodPressureLabel,
          color: assessment.bloodPressureLabel == 'Normale' ? Colors.green : Colors.orange,
        ),
        _buildParameterCard(
          icon: Iconsax.heart,
          label: 'FC',
          value: assessment.heartRate != null ? '${assessment.heartRate} bpm' : '—',
          subtitle: assessment.heartRate != null &&
                  assessment.heartRate! >= 60 &&
                  assessment.heartRate! <= 100
              ? 'Normal'
              : 'Anormal',
          color: assessment.heartRate != null &&
                  assessment.heartRate! >= 60 &&
                  assessment.heartRate! <= 100
              ? Colors.green
              : Colors.orange,
        ),
        _buildParameterCard(
          icon: Iconsax.monitor,
          label: 'Température',
          value: assessment.temperature != null ? '${assessment.temperature}°C' : '—',
          subtitle: assessment.temperature != null &&
                  assessment.temperature! >= 36.5 &&
                  assessment.temperature! <= 37.5
              ? 'Normal'
              : 'Anormal',
          color: assessment.temperature != null &&
                  assessment.temperature! >= 36.5 &&
                  assessment.temperature! <= 37.5
              ? Colors.green
              : Colors.orange,
        ),
      ],
    );
  }

  Widget _buildParameterCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _cardShadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== MODE DE VIE ====================
  Widget _buildLifestyle(HealthAssessment assessment) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        _buildLifeParameter(
          icon: Iconsax.moon,
          label: 'Sommeil',
          value: assessment.sleepHours != null ? '${assessment.sleepHours}h' : '—',
          status: assessment.sleepHours != null &&
                  assessment.sleepHours! >= 7 &&
                  assessment.sleepHours! <= 9
              ? 'Optimal'
              : 'À améliorer',
          isGood: assessment.sleepHours != null &&
              assessment.sleepHours! >= 7 &&
              assessment.sleepHours! <= 9,
        ),
        _buildLifeParameter(
          icon: Iconsax.activity,
          label: 'Exercice',
          value: assessment.exerciseMinutes != null ? '${assessment.exerciseMinutes}min' : '—',
          status: assessment.exerciseMinutes != null &&
                  assessment.exerciseMinutes! >= 30
              ? 'Actif'
              : 'Sédentaire',
          isGood: assessment.exerciseMinutes != null &&
              assessment.exerciseMinutes! >= 30,
        ),
        _buildLifeParameter(
          icon: Iconsax.ranking,
          label: 'Hydratation',
          value: assessment.waterIntake != null ? '${assessment.waterIntake}ml' : '—',
          status: assessment.waterIntake != null &&
                  assessment.waterIntake! >= 1500
              ? 'Bien hydraté'
              : 'Hydratez-vous',
          isGood: assessment.waterIntake != null &&
              assessment.waterIntake! >= 1500,
        ),
        _buildLifeParameter(
          icon: Icons.psychology,
          label: 'Stress',
          value: assessment.stressLevel != null ? '${assessment.stressLevel}/10' : '—',
          status: assessment.stressLevel != null
              ? assessment.stressLevel! <= 3
                  ? 'Faible'
                  : assessment.stressLevel! <= 6
                      ? 'Modéré'
                      : 'Élevé'
              : '—',
          isGood: assessment.stressLevel != null && assessment.stressLevel! <= 3,
        ),
      ],
    );
  }

  Widget _buildLifeParameter({
    required IconData icon,
    required String label,
    required String value,
    required String status,
    required bool isGood,
  }) {
    final color = isGood ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGood ? Colors.green.shade200 : Colors.orange.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _cardShadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    isGood ? Icons.check_circle : Icons.warning_amber,
                    size: 12,
                    color: color,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      status,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== RECOMMANDATIONS ====================
  Widget _buildRecommendations(HealthAssessment assessment) {
    final recommendations = assessment.recommendations ?? const <String>[];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.amber.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '💡 Recommandations personnalisées',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    rec.startsWith('⚠️') ? Icons.warning : Icons.check_circle,
                    color: rec.startsWith('⚠️') ? Colors.orange : Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _textSecondaryColor,
                      ),
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

  // ==================== HISTORIQUE ====================
  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📈 Historique des bilans',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final item = _history[index];
              final color = _getScoreColor(item.overallScore ?? 0);

              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.overallScore != null ? '${item.overallScore}%' : '—',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd/MM').format(item.assessmentDate),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: _textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== TENDANCES ====================
  Widget _buildTrendChart() {
    if (_history.length < 2) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _cardShadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Iconsax.chart, size: 48, color: _textSecondaryColor),
            const SizedBox(height: 8),
            Text(
              'Pas assez de données',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.inter(
                color: _textSecondaryColor,
                fontSize: 14,
              ),
            ),
            Text(
              'Ajoutez au moins 2 bilans pour voir les tendances',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: GoogleFonts.inter(
                color: _textSecondaryColor.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final spots = _history.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final value = entry.value.overallScore?.toDouble() ?? 0;
      return FlSpot(index, value);
    }).toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _cardShadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: _textSecondaryColor.withOpacity(0.2),
                strokeWidth: 0.5,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (_history.length > 3 && value % 2 == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('dd/MM').format(
                          _history[value.toInt()].assessmentDate,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: _textSecondaryColor,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: _textSecondaryColor,
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppTheme.primaryLight,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryLight.withOpacity(0.2),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: AppTheme.primaryLight,
                  );
                },
              ),
            ),
          ],
          minX: 0,
          maxX: spots.length > 1 ? spots.length - 1 : 1,
          minY: 0,
          maxY: 100,
        ),
      ),
    );
  }

  // ==================== ANALYSE DÉTAILLÉE ====================
  Widget _buildDetailedAnalysis() {
    final assessment = _latestAssessment;
    if (assessment == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _cardShadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAnalysisItem(
            title: 'Indice de masse corporelle (IMC)',
            value: assessment.bmi != null
                ? '${assessment.bmi!.toStringAsFixed(1)} kg/m²'
                : 'Non mesuré',
            status: assessment.bmiLabel,
            color: assessment.bmiColor,
            icon: Iconsax.monitor,
          ),
          const Divider(),
          _buildAnalysisItem(
            title: 'Pression artérielle',
            value: assessment.bloodPressureSystolic != null &&
                    assessment.bloodPressureDiastolic != null
                ? '${assessment.bloodPressureSystolic}/${assessment.bloodPressureDiastolic} mmHg'
                : 'Non mesurée',
            status: assessment.bloodPressureLabel,
            color: assessment.bloodPressureLabel == 'Normale' ? Colors.green : Colors.orange,
            icon: Iconsax.heart,
          ),
          const Divider(),
          _buildAnalysisItem(
            title: 'Fréquence cardiaque',
            value: assessment.heartRate != null ? '${assessment.heartRate} bpm' : 'Non mesurée',
            status: assessment.heartRate != null &&
                    assessment.heartRate! >= 60 &&
                    assessment.heartRate! <= 100
                ? 'Normale'
                : 'Anormale',
            color: assessment.heartRate != null &&
                    assessment.heartRate! >= 60 &&
                    assessment.heartRate! <= 100
                ? Colors.green
                : Colors.orange,
            icon: Iconsax.heart,
          ),
          const Divider(),
          _buildAnalysisItem(
            title: 'Qualité du sommeil',
            value: assessment.sleepHours != null ? '${assessment.sleepHours} heures' : 'Non renseigné',
            status: assessment.sleepHours != null &&
                    assessment.sleepHours! >= 7 &&
                    assessment.sleepHours! <= 9
                ? 'Optimal'
                : 'À améliorer',
            color: assessment.sleepHours != null &&
                    assessment.sleepHours! >= 7 &&
                    assessment.sleepHours! <= 9
                ? Colors.green
                : Colors.orange,
            icon: Iconsax.moon,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem({
    required String title,
    required String value,
    required String status,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textColor,
                  ),
                ),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                status,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== POINTS D'ATTENTION ====================
  Widget _buildAttentionPoints() {
    final assessment = _latestAssessment;
    if (assessment == null) return const SizedBox.shrink();

    final List<Map<String, dynamic>> points = [];

    if (assessment.bmi != null && (assessment.bmi! < 18.5 || assessment.bmi! > 25)) {
      points.add({
        'title': 'IMC ${assessment.bmi! < 18.5 ? 'faible' : 'élevé'}',
        'description': assessment.bmi! < 18.5
            ? 'Votre IMC est inférieur à la normale. Pensez à consulter un nutritionniste.'
            : 'Votre IMC est supérieur à la normale. Une activité physique régulière est recommandée.',
        'icon': Iconsax.danger,
        'color': Colors.orange,
      });
    }

    if (assessment.bloodPressureSystolic != null && assessment.bloodPressureSystolic! >= 130) {
      points.add({
        'title': 'Pression artérielle élevée',
        'description': 'Votre pression artérielle est élevée. Surveillez votre alimentation et consultez un médecin.',
        'icon': Iconsax.danger,
        'color': Colors.red,
      });
    }

    if (assessment.stressLevel != null && assessment.stressLevel! > 6) {
      points.add({
        'title': 'Stress élevé',
        'description': 'Votre niveau de stress est élevé. Essayez des techniques de relaxation.',
        'icon': Iconsax.danger,
        'color': Colors.orange,
      });
    }

    if (assessment.sleepHours != null && assessment.sleepHours! < 7) {
      points.add({
        'title': 'Manque de sommeil',
        'description': 'Vous dormez moins de 7 heures. Essayez d\'augmenter votre temps de sommeil.',
        'icon': Iconsax.danger,
        'color': Colors.orange,
      });
    }

    if (points.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Icon(Iconsax.tick_circle, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aucun point d\'attention particulier. Continuez vos efforts !',
                style: GoogleFonts.inter(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: points.map((point) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (point['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (point['color'] as Color).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(point['icon'] as IconData, color: point['color'] as Color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point['title'] as String,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: point['color'] as Color,
                      ),
                    ),
                    Text(
                      point['description'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ==================== RECOMMANDATIONS GLOBALES ====================
  Widget _buildGlobalRecommendations() {
    final recommendations = [
      '✅ Maintenez une activité physique régulière (30 min par jour)',
      '✅ Adoptez une alimentation équilibrée riche en fruits et légumes',
      '✅ Dormez 7 à 8 heures par nuit pour une bonne récupération',
      '✅ Gérez votre stress avec des techniques de relaxation',
      '✅ Hydratez-vous régulièrement (1.5L à 2L par jour)',
      '✅ Consultez votre médecin pour un suivi régulier',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: recommendations.map((rec) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Iconsax.tick_circle, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==================== PROGRESSIONS ====================
  Widget _buildParametersProgress() {
    final assessment = _latestAssessment;
    if (assessment == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _cardShadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProgressItem(
            label: 'Score global',
            value: assessment.overallScore ?? 0,
            color: _getScoreColor(assessment.overallScore ?? 0),
          ),
          const SizedBox(height: 12),
          _buildProgressItem(
            label: 'IMC',
            value: assessment.bmi != null ? _getBMIScore(assessment.bmi!) : 0,
            color: assessment.bmiColor,
          ),
          const SizedBox(height: 12),
          _buildProgressItem(
            label: 'Sommeil',
            value: assessment.sleepHours != null
                ? ((assessment.sleepHours! / 8) * 100).round()
                : 0,
            color: assessment.sleepHours != null &&
                    assessment.sleepHours! >= 7 &&
                    assessment.sleepHours! <= 9
                ? Colors.green
                : Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildProgressItem(
            label: 'Exercice',
            value: assessment.exerciseMinutes != null
                ? ((assessment.exerciseMinutes! / 30) * 100).round()
                : 0,
            color: assessment.exerciseMinutes != null &&
                    assessment.exerciseMinutes! >= 30
                ? Colors.green
                : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem({
    required String label,
    required int value,
    required Color color,
  }) {
    final safeValue = value.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _textSecondaryColor,
                ),
              ),
            ),
            Text(
              '$safeValue%',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: safeValue / 100,
            backgroundColor: _textSecondaryColor.withOpacity(0.2),
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ==================== ÉCRAN DE CHARGEMENT ====================
  Widget _buildLoadingScreen() {
    return Center(
      child: Shimmer.fromColors(
        baseColor: _textSecondaryColor.withOpacity(0.2),
        highlightColor: _textSecondaryColor.withOpacity(0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryLight, AppTheme.primaryLight.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
              'Chargement de votre bilan...',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Préparation de vos données',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _textSecondaryColor.withOpacity(0.7),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.danger, size: 64, color: AppTheme.error),
            ),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Veuillez réessayer',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: _textSecondaryColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _refreshData,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryLight,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    HealthBilanLogger.navigation('🔙 Retour au Dashboard');
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Retour'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

  // ==================== ÉCRAN VIDE ====================
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryLight.withOpacity(0.1),
                    AppTheme.primaryLight.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.health,
                size: 64,
                color: AppTheme.primaryLight.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucun bilan de santé',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre premier bilan de santé dès maintenant',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: _textSecondaryColor,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _navigateToForm,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Créer un bilan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    HealthBilanLogger.navigation('🔙 Retour au Dashboard');
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Retour'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryLight,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

  // ==================== FAB ====================
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _navigateToForm,
      backgroundColor: AppTheme.primaryLight,
      elevation: 8,
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
    );
  }

  // ==================== UTILITAIRES ====================
  void _navigateToForm() {
    HealthBilanLogger.navigation('📝 Navigation vers le formulaire de bilan');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HealthAssessmentFormScreen(),
      ),
    ).then((_) {
      HealthBilanLogger.info('🔄 Retour du formulaire - Rechargement');
      _loadData();
    });
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
      style: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: _textColor,
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green.shade700;
    if (score >= 75) return Colors.lightGreen.shade700;
    if (score >= 60) return Colors.orange.shade700;
    if (score >= 40) return Colors.deepOrange.shade700;
    return Colors.red.shade700;
  }

  String _getScoreSubtitle(int score) {
    if (score >= 90) return 'Excellente santé ! 🎉';
    if (score >= 75) return 'Bonne santé, continuez ! 💪';
    if (score >= 60) return 'Santé moyenne, à améliorer 📈';
    if (score >= 40) return 'Santé à surveiller ⚠️';
    return 'Santé préoccupante 🚨';
  }

  int _getBMIScore(double bmi) {
    if (bmi >= 18.5 && bmi <= 24.9) return 90;
    if ((bmi >= 25 && bmi <= 29.9) || (bmi >= 16 && bmi <= 18.4)) return 60;
    return 30;
  }
}