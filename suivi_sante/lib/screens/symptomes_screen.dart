// lib/screens/symptomes_screen.dart
// VERSION PRO - Architecture Clean avec Logs Complets

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:iconsax/iconsax.dart';
import 'package:suivi_sante_pro/widgets/ia_analysis_widget.dart';
import '../services/symptome_service.dart';
import '../models/symptome.dart';
import '../widgets/symptome_card.dart';
import '../widgets/symptome_stats_card.dart';
import 'symptome_form_screen.dart';

// ============================================================================
// LOGGER SERVICE INTÉGRÉ
// ============================================================================
class SymptomeLogger {
  static const String _tag = '🩺 SymptomesScreen';

  static void info(String message) {
    final log = '$_tag - ℹ️ $message';
    print(log);
    developer.log(log, name: 'INFO', time: DateTime.now());
  }

  static void debug(String message) {
    final log = '$_tag - 🐛 $message';
    print(log);
    developer.log(log, name: 'DEBUG', time: DateTime.now());
  }

  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    final log = '$_tag - ❌ $message';
    print(log);
    if (error != null) print('Erreur: $error');
    if (stackTrace != null) print(stackTrace);
    developer.log(
      log,
      name: 'ERROR',
      time: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void success(String message) {
    final log = '$_tag - ✅ $message';
    print(log);
    developer.log(log, name: 'SUCCESS', time: DateTime.now());
  }

  static void warning(String message) {
    final log = '$_tag - ⚠️ $message';
    print(log);
    developer.log(log, name: 'WARNING', time: DateTime.now());
  }

  static void api(
    String method,
    String endpoint, {
    Map<String, dynamic>? request,
    Map<String, dynamic>? response,
    int? statusCode,
  }) {
    final log =
        '''
$_tag - 🌐 $method $endpoint
  Status: $statusCode
  Request: ${request != null ? _formatJson(request) : 'N/A'}
  Response: ${response != null ? _formatJson(response) : 'N/A'}''';
    print(log);
    developer.log(log, name: 'API', time: DateTime.now());
  }

  static void performance(String operation, Duration duration) {
    final log = '$_tag - ⏱️ $operation: ${duration.inMilliseconds}ms';
    print(log);
    developer.log(log, name: 'PERFORMANCE', time: DateTime.now());
  }

  static void state(String component, Map<String, dynamic> state) {
    final log = '$_tag - 📊 $component state:\n${_formatJson(state)}';
    print(log);
    developer.log(log, name: 'STATE', time: DateTime.now());
  }

  static String _formatJson(Map<String, dynamic> data) {
    try {
      return data
          .toString()
          .replaceAll('{', '{\n  ')
          .replaceAll('}', '\n}')
          .replaceAll(',', ',\n  ');
    } catch (_) {
      return data.toString();
    }
  }
}

// ============================================================================
// MODÈLE DE STATISTIQUES AVANCÉ
// ============================================================================
// ============================================================================
// MODÈLE DE STATISTIQUES AVANCÉ (CORRIGÉ)
// ============================================================================
class SymptomeStats {
  final int total;
  final int actifs;
  final int resolus;
  final int enAmelioration;
  final int aggravation;
  final Map<String, int> parType;
  final Map<String, int> parStatus;
  final Map<String, int> parSeverite;
  final double tauxResolution;
  final double niveauMoyen;
  final int niveauMax;
  final int niveauMin;
  final List<Symptome> plusRecents;
  final List<Symptome> plusSeveres;

  SymptomeStats({
    required this.total,
    required this.actifs,
    required this.resolus,
    required this.enAmelioration,
    required this.aggravation,
    required this.parType,
    required this.parStatus,
    required this.parSeverite,
    required this.tauxResolution,
    required this.niveauMoyen,
    required this.niveauMax,
    required this.niveauMin,
    required this.plusRecents,
    required this.plusSeveres,
  });

  factory SymptomeStats.fromData(List<Symptome> symptomes) {
    final parStatus = <String, int>{};
    final parType = <String, int>{};
    final parSeverite = <String, int>{};

    int total = symptomes.length;
    int actifs = 0;
    int resolus = 0;
    int enAmelioration = 0;
    int aggravation = 0;
    int sommeNiveaux = 0;
    int niveauMax = 0;
    int niveauMin = 10;

    for (final s in symptomes) {
      // ✅ Utiliser des valeurs par défaut pour les null
      final status = s.status ?? 'actif';
      final type = s.type ?? 'autre';

      parStatus[status] = (parStatus[status] ?? 0) + 1;
      switch (status) {
        case 'actif':
          actifs++;
          break;
        case 'resolu':
          resolus++;
          break;
        case 'en_amelioration':
          enAmelioration++;
          break;
        case 'aggravation':
          aggravation++;
          break;
      }

      parType[type] = (parType[type] ?? 0) + 1;

      sommeNiveaux += s.niveau;
      if (s.niveau > niveauMax) niveauMax = s.niveau;
      if (s.niveau < niveauMin) niveauMin = s.niveau;

      final severite = _getSeveriteLabel(s.niveau);
      parSeverite[severite] = (parSeverite[severite] ?? 0) + 1;
    }

    final plusRecents = List<Symptome>.from(symptomes)
      ..sort((a, b) => b.dateEnregistrement.compareTo(a.dateEnregistrement));

    final plusSeveres = List<Symptome>.from(symptomes)
      ..sort((a, b) => b.niveau.compareTo(a.niveau));

    return SymptomeStats(
      total: total,
      actifs: actifs,
      resolus: resolus,
      enAmelioration: enAmelioration,
      aggravation: aggravation,
      parType: parType,
      parStatus: parStatus,
      parSeverite: parSeverite,
      tauxResolution: total > 0 ? (resolus / total * 100) : 0,
      niveauMoyen: total > 0 ? (sommeNiveaux / total) : 0,
      niveauMax: niveauMax,
      niveauMin: niveauMin == 10 ? 0 : niveauMin,
      plusRecents: plusRecents.take(5).toList(),
      plusSeveres: plusSeveres.take(5).toList(),
    );
  }

  static String _getSeveriteLabel(int niveau) {
    if (niveau <= 3) return 'Faible';
    if (niveau <= 6) return 'Modéré';
    if (niveau <= 8) return 'Élevé';
    return 'Critique';
  }
}

// ============================================================================
// SCREEN PRINCIPAL
// ============================================================================
class SymptomesScreen extends StatefulWidget {
  const SymptomesScreen({super.key});

  @override
  State<SymptomesScreen> createState() => _SymptomesScreenState();
}

class _SymptomesScreenState extends State<SymptomesScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // ==========================================================================
  // ÉTATS
  // ==========================================================================
  List<Symptome> _symptomes = [];
  SymptomeStats? _stats;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String _filterStatus = 'tous';
  String _filterType = 'tous';
  String _searchQuery = '';
  bool _isSearching = false;

  // ==========================================================================
  // CONTROLEURS
  // ==========================================================================
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  // ==========================================================================
  // INIT
  // ==========================================================================
  @override
  void initState() {
    super.initState();
    SymptomeLogger.info('🔄 Initialisation de SymptomesScreen');

    _tabController = TabController(length: 2, vsync: this);
    _initAnimations();
    _loadData();
    _setupSearchListener();
    _setupScrollListener();

    SymptomeLogger.debug('📋 Configuration initiale terminée');
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
    SymptomeLogger.debug('🎬 Animations initialisées');
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
      if (_searchQuery.isNotEmpty) {
        SymptomeLogger.debug('🔍 Recherche: "$_searchQuery"');
      }
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        SymptomeLogger.debug('📜 Fin de liste atteinte');
      }
    });
  }

  @override
  void dispose() {
    SymptomeLogger.debug('🗑️ Destruction de SymptomesScreen');
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // CHARGEMENT DES DONNÉES
  // ==========================================================================
  Future<void> _loadData() async {
    SymptomeLogger.info('📥 Chargement des données...');
    final stopwatch = Stopwatch()..start();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = SymptomeService();
      SymptomeLogger.api('GET', '/symptomes');

      final symptomes = await service.getSymptomes();
      _symptomes = symptomes as List<Symptome>;

      SymptomeLogger.success('✅ ${_symptomes.length} symptômes chargés');

      // Calcul des statistiques
      _stats = SymptomeStats.fromData(_symptomes);
      SymptomeLogger.state('Stats', {
        'total': _stats!.total,
        'actifs': _stats!.actifs,
        'resolus': _stats!.resolus,
        'taux_resolution': '${_stats!.tauxResolution.toStringAsFixed(1)}%',
        'niveau_moyen': _stats!.niveauMoyen.toStringAsFixed(1),
        'types': _stats!.parType.keys.join(', '),
        'status': _stats!.parStatus.keys.join(', '),
      });

      setState(() => _isLoading = false);

      stopwatch.stop();
      SymptomeLogger.performance('Chargement des symptômes', stopwatch.elapsed);

      _animationController.forward(from: 0);
    } catch (e, stackTrace) {
      SymptomeLogger.error(
        'Erreur lors du chargement',
        error: e,
        stackTrace: stackTrace,
      );
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _refreshData() async {
    SymptomeLogger.info('🔄 Rafraîchissement manuel');
    setState(() => _isRefreshing = true);
    await _loadData();
    setState(() => _isRefreshing = false);
    SymptomeLogger.success('✅ Rafraîchissement terminé');
  }

  // ==========================================================================
  // FILTRES AVANCÉS
  // ==========================================================================
  List<Symptome> get _filteredSymptomes {
    return _symptomes.where((s) {
      final statusMatch = _filterStatus == 'tous' || s.status == _filterStatus;
      final typeMatch = _filterType == 'tous' || s.type == _filterType;
      final searchMatch =
          _searchQuery.isEmpty ||
          s.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.typeLabel.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (s.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false);
      return statusMatch && typeMatch && searchMatch;
    }).toList();
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================
  // ==========================================================================
  // BODY PRINCIPAL - AVEC SCROLL
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    super.build(context);
    SymptomeLogger.debug('🔨 Build SymptomesScreen');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A1A)
          : const Color(0xFFF8F9FE),
      body: _isLoading
          ? _buildLoadingScreen()
          : _errorMessage != null
          ? _buildErrorScreen()
          : SafeArea(
              // ✅ Ajout de SafeArea
              child: SingleChildScrollView(
                // ✅ Scroll pour tout le contenu
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildSearchBar(),
                    _buildStatsOverview(),
                    _buildFilterBar(),
                    _buildTabContent(),
                  ],
                ),
              ),
            ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildTabContent() {
    return SizedBox(
      height:
          MediaQuery.of(context).size.height *
          0.55, // ✅ Hauteur fixe avec scroll
      child: TabBarView(
        controller: _tabController,
        children: [_buildListTab(), _buildStatsTab()],
      ),
    );
  }

  // ==========================================================================
  // CONTENU PRINCIPAL
  // ==========================================================================
  Widget _buildMainContent() {
    return Column(
      children: [
        _buildHeader(),
        _buildSearchBar(),
        _buildStatsOverview(),
        _buildFilterBar(),
        Flexible(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: const Color(0xFF6C5CE7),
            backgroundColor: Colors.white,
            child: TabBarView(
              controller: _tabController,
              children: [_buildListTab(), _buildStatsTab()],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // HEADER AVANCÉ
  // ==========================================================================
  // ==========================================================================
  // HEADER - CORRIGÉ (HAUTEUR RÉDUITE)
  // ==========================================================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 12), // ✅ Padding réduit
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {
                SymptomeLogger.debug('🔙 Retour Dashboard');
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
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
                const Text(
                  '🩺 Mes symptômes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_symptomes.length} symptômes suivis',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (_symptomes.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _showFullAnalysisDialog,
                tooltip: 'Analyse IA complète',
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _refreshData,
              tooltip: 'Rafraîchir',
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SEARCH BAR AVANCÉE
  // ==========================================================================
  // ==========================================================================
  // SEARCH BAR - CORRIGÉE
  // ==========================================================================
  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ), // ✅ Padding réduit
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher un symptôme...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(
              Iconsax.search_normal,
              color: Colors.grey.shade400,
              size: 18,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.shade400,
                      size: 18,
                    ),
                    onPressed: () {
                      SymptomeLogger.debug('🧹 Recherche effacée');
                      _searchController.clear();
                    },
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 4,
            ),
            filled: true,
            fillColor: Colors.transparent,
          ),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 13,
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              SymptomeLogger.debug('🔍 Recherche: "$value"');
            }
          },
        ),
      ),
    );
  }

  // ==========================================================================
  // STATS OVERVIEW AVEC ANIMATION
  // ==========================================================================
  // ==========================================================================
  // STATS OVERVIEW - CORRIGÉE (SANS DÉBORDEMENT)
  // ==========================================================================
  Widget _buildStatsOverview() {
    if (_stats == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min, // ✅ IMPORTANT : mainAxisSize.min
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 70, // ✅ Hauteur fixe réduite
          child: Row(
            children: [
              _buildStatItem(
                label: 'Total',
                value: '${_stats!.total}',
                color: const Color(0xFF6C5CE7),
                icon: Iconsax.chart,
              ),
              _buildStatItem(
                label: 'Actifs',
                value: '${_stats!.actifs}',
                color: const Color(0xFF0984E3),
                icon: Iconsax.clock,
              ),
              _buildStatItem(
                label: 'Résolus',
                value: '${_stats!.resolus}',
                color: const Color(0xFF00B894),
                icon: Iconsax.tick_circle,
              ),
              _buildStatItem(
                label: 'Taux',
                value: '${_stats!.tauxResolution.toStringAsFixed(0)}%',
                color: const Color(0xFFFDCB6E),
                icon: Iconsax.graph,
              ),
            ],
          ),
        ),
        if (_symptomes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: IAAnalysisWidget(symptomes: _symptomes),
          ),
        ],
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      // ✅ Utiliser Expanded au lieu de Flexible
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.1), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 12),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // FILTER BAR AVANCÉE
  // ==========================================================================
  // ==========================================================================
  // FILTER BAR - CORRIGÉE
  // ==========================================================================
  Widget _buildFilterBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: isDark ? const Color(0xFF0A0A1A) : const Color(0xFFF8F9FE),
      child: Row(
        children: [
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Tous',
                    value: 'tous',
                    selected: _filterStatus == 'tous',
                    icon: Iconsax.element_4,
                    onSelected: () {
                      SymptomeLogger.debug('📊 Filtre: Tous');
                      setState(() => _filterStatus = 'tous');
                    },
                  ),
                  _buildFilterChip(
                    label: 'Actif',
                    value: 'actif',
                    selected: _filterStatus == 'actif',
                    icon: Iconsax.clock,
                    onSelected: () {
                      SymptomeLogger.debug('📊 Filtre: Actif');
                      setState(() => _filterStatus = 'actif');
                    },
                  ),
                  _buildFilterChip(
                    label: 'Résolu',
                    value: 'resolu',
                    selected: _filterStatus == 'resolu',
                    icon: Iconsax.tick_circle,
                    onSelected: () {
                      SymptomeLogger.debug('📊 Filtre: Résolu');
                      setState(() => _filterStatus = 'resolu');
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                Iconsax.setting_2,
                color: isDark ? Colors.white : Colors.black,
                size: 18,
              ),
              onPressed: _showAdvancedFilterDialog,
              tooltip: 'Filtres avancés',
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required bool selected,
    required IconData icon,
    required VoidCallback onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        selected: selected,
        onSelected: (_) => onSelected(),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        selectedColor: const Color(0xFF6C5CE7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected
                ? const Color(0xFF6C5CE7)
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: 1,
          ),
        ),
        labelStyle: TextStyle(
          color: selected
              ? Colors.white
              : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          fontSize: 11,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        elevation: selected ? 1 : 0,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // ==========================================================================
  // LIST TAB AVEC PERFORMANCE OPTIMISÉE
  // ==========================================================================
  Widget _buildListTab() {
    final filtered = _filteredSymptomes;
    SymptomeLogger.debug('📋 Affichage de ${filtered.length} symptômes');

    if (filtered.isEmpty) {
      return _buildEmptyState(
        _symptomes.isEmpty ? 'Aucun symptôme' : 'Aucun résultat',
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final symptome = filtered[index];
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SymptomeCard(
            symptome: symptome,
            onTap: () => _showSymptomeDetails(symptome),
            onDelete: () => _deleteSymptome(symptome.id!),
            onResolve: () => _resolveSymptome(symptome.id!),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // STATS TAB AVEC ANALYSE DÉTAILLÉE
  // ==========================================================================
  Widget _buildStatsTab() {
    if (_stats == null) {
      return const Center(child: Text('Aucune statistique disponible'));
    }

    SymptomeLogger.debug('📊 Affichage des statistiques détaillées');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsOverviewCard(),
          const SizedBox(height: 16),
          _buildStatusDistribution(),
          const SizedBox(height: 16),
          _buildTypeDistribution(),
          const SizedBox(height: 16),
          _buildSeverityDistribution(),
          const SizedBox(height: 16),
          _buildTopSymptoms(),
        ],
      ),
    );
  }

  Widget _buildStatsOverviewCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📊 Vue d\'ensemble',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_stats!.total} symptômes',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatBlock(
                label: 'Taux résolution',
                value: '${_stats!.tauxResolution.toStringAsFixed(0)}%',
                icon: Iconsax.graph,
              ),
              _buildStatBlock(
                label: 'Niveau moyen',
                value: _stats!.niveauMoyen.toStringAsFixed(1),
                icon: Iconsax.chart_2,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatBlock(
                label: 'Actifs',
                value: '${_stats!.actifs}',
                icon: Iconsax.clock,
                color: const Color(0xFF0984E3),
              ),
              _buildStatBlock(
                label: 'Résolus',
                value: '${_stats!.resolus}',
                icon: Iconsax.tick_circle,
                color: const Color(0xFF00B894),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBlock({
    required String label,
    required String value,
    required IconData icon,
    Color color = Colors.white,
  }) {
    return Flexible(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDistribution() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColors = {
      'actif': const Color(0xFF0984E3),
      'resolu': const Color(0xFF00B894),
      'en_amelioration': const Color(0xFFFDCB6E),
      'aggravation': const Color(0xFFE17055),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 Répartition par statut',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._stats!.parStatus.entries.map((entry) {
            final percentage = (_stats!.total > 0)
                ? (entry.value / _stats!.total * 100).round()
                : 0;
            final color = statusColors[entry.key] ?? Colors.grey;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getStatusLabel(entry.key),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${entry.value} (${percentage}%)',
                        style: TextStyle(
                          fontSize: 13,
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
                      value: percentage / 100,
                      backgroundColor: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      color: color,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTypeDistribution() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Répartition par type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _stats!.parType.entries.map((entry) {
              final percentage = (_stats!.total > 0)
                  ? (entry.value / _stats!.total * 100).round()
                  : 0;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6C5CE7).withOpacity(0.08),
                      const Color(0xFFA29BFE).withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6C5CE7).withOpacity(0.15),
                  ),
                ),
                child: Text(
                  '${_getTypeLabel(entry.key)}: ${entry.value} (${percentage}%)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6C5CE7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityDistribution() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final severities = {
      'Faible': _symptomes.where((s) => s.niveau <= 3).length,
      'Modéré': _symptomes.where((s) => s.niveau > 3 && s.niveau <= 6).length,
      'Élevé': _symptomes.where((s) => s.niveau > 6 && s.niveau <= 8).length,
      'Critique': _symptomes.where((s) => s.niveau > 8).length,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚠️ Distribution des niveaux',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...severities.entries.map((entry) {
            final percentage = _symptomes.isNotEmpty
                ? (entry.value / _symptomes.length * 100).round()
                : 0;
            final color = _getSeverityColor(entry.key);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                      Text(
                        '${entry.value} (${percentage}%)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                      color: color,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopSymptoms() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_stats!.plusSeveres.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔥 Symptômes les plus sévères',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._stats!.plusSeveres.take(5).map((s) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: s.severityColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.description,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: s.severityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${s.niveau}/10',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: s.severityColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ==========================================================================
  // ÉTATS VIDES AVEC LOGO
  // ==========================================================================
  Widget _buildEmptyState(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sick_outlined,
              size: 64,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez à suivre vos symptômes',
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          _buildGradientButton(
            onPressed: _navigateToForm,
            icon: Icons.add_rounded,
            label: 'Ajouter un symptôme',
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // ÉCRANS DE CHARGEMENT ET D'ERREUR
  // ==========================================================================
  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
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
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: const Text(
              'Chargement des symptômes...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
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
              'Oups ! Une erreur est survenue',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildGradientButton(
                  onPressed: _loadData,
                  icon: Icons.refresh_rounded,
                  label: 'Réessayer',
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    SymptomeLogger.debug('🔙 Retour Dashboard (depuis erreur)');
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  },
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : Colors.grey.shade700,
                  ),
                  label: Text(
                    'Retour au Dashboard',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
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

  // ==========================================================================
  // FILTRES AVANCÉS - DIALOG
  // ==========================================================================
  void _showAdvancedFilterDialog() {
    SymptomeLogger.debug('📝 Ouverture filtres avancés');

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          String tempStatus = _filterStatus;
          String tempType = _filterType;

          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filtres avancés',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Type de symptôme',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildTypeFilterChip(
                      'Tous',
                      'tous',
                      tempType,
                      setStateDialog,
                    ),
                    _buildTypeFilterChip(
                      'Douleur',
                      'douleur',
                      tempType,
                      setStateDialog,
                    ),
                    _buildTypeFilterChip(
                      'Fatigue',
                      'fatigue',
                      tempType,
                      setStateDialog,
                    ),
                    _buildTypeFilterChip(
                      'Digestif',
                      'digestif',
                      tempType,
                      setStateDialog,
                    ),
                    _buildTypeFilterChip(
                      'Respiratoire',
                      'respiratoire',
                      tempType,
                      setStateDialog,
                    ),
                    _buildTypeFilterChip(
                      'Neurologique',
                      'neurologique',
                      tempType,
                      setStateDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Statut',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildStatusFilterChip(
                      'Tous',
                      'tous',
                      tempStatus,
                      setStateDialog,
                    ),
                    _buildStatusFilterChip(
                      'Actif',
                      'actif',
                      tempStatus,
                      setStateDialog,
                    ),
                    _buildStatusFilterChip(
                      'Résolu',
                      'resolu',
                      tempStatus,
                      setStateDialog,
                    ),
                    _buildStatusFilterChip(
                      'Amélioration',
                      'en_amelioration',
                      tempStatus,
                      setStateDialog,
                    ),
                    _buildStatusFilterChip(
                      'Aggravation',
                      'aggravation',
                      tempStatus,
                      setStateDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        SymptomeLogger.debug('🔄 Réinitialisation des filtres');
                        setState(() {
                          _filterStatus = 'tous';
                          _filterType = 'tous';
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Réinitialiser'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        SymptomeLogger.debug(
                          '✅ Application des filtres: status=$tempStatus, type=$tempType',
                        );
                        setState(() {
                          _filterStatus = tempStatus;
                          _filterType = tempType;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Appliquer'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeFilterChip(
    String label,
    String value,
    String current,
    StateSetter setStateDialog,
  ) {
    final selected = current == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setStateDialog(() => current = value),
      backgroundColor: Colors.transparent,
      selectedColor: const Color(0xFF6C5CE7).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? const Color(0xFF6C5CE7) : Colors.grey.shade300,
        ),
      ),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF6C5CE7) : Colors.grey.shade600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildStatusFilterChip(
    String label,
    String value,
    String current,
    StateSetter setStateDialog,
  ) {
    final selected = current == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setStateDialog(() => current = value),
      backgroundColor: Colors.transparent,
      selectedColor: const Color(0xFF6C5CE7).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? const Color(0xFF6C5CE7) : Colors.grey.shade300,
        ),
      ),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF6C5CE7) : Colors.grey.shade600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  // ==========================================================================
  // ACTIONS SUR LES SYMPTÔMES
  // ==========================================================================
  void _showSymptomeDetails(Symptome symptome) {
    SymptomeLogger.info('👁️ Visualisation du symptôme #${symptome.id}');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            _buildModalHandle(isDark),
            const SizedBox(height: 16),
            _buildModalHeader(symptome, isDark),
            const Divider(),
            Flexible(
              flex: 1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildModalContent(symptome, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalHandle(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildModalHeader(Symptome symptome, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: symptome.severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  symptome.severityIcon,
                  color: symptome.severityColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Détails du symptôme',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildModalContent(Symptome symptome, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          symptome.description,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Flexible(
              child: _buildDetailCard(
                icon: symptome.severityIcon,
                label: 'Niveau',
                value: '${symptome.niveau}/10',
                color: symptome.severityColor,
                subtitle: symptome.severityLabel,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: _buildDetailCard(
                icon: Icons.circle,
                label: 'Statut',
                value: symptome.statusLabel,
                color: symptome.statusColor,
                isStatus: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDetailInfo(
          icon: symptome.typeIcon,
          label: 'Type',
          value: symptome.typeLabel,
          color: isDark ? Colors.white : Colors.black,
        ),
        const Divider(),
        _buildDetailInfo(
          icon: Icons.calendar_today_rounded,
          label: 'Date',
          value: DateFormat(
            'dd MMMM yyyy à HH:mm',
            'fr',
          ).format(symptome.dateEnregistrement),
          color: isDark ? Colors.white : Colors.black,
        ),
        if (symptome.duree != null) ...[
          const Divider(),
          _buildDetailInfo(
            icon: Icons.timer_rounded,
            label: 'Durée',
            value: symptome.duree!,
            color: isDark ? Colors.white : Colors.black,
          ),
        ],
        if (symptome.frequence != null) ...[
          const Divider(),
          _buildDetailInfo(
            icon: Icons.repeat_rounded,
            label: 'Fréquence',
            value: symptome.frequence!,
            color: isDark ? Colors.white : Colors.black,
          ),
        ],
        if (symptome.notes != null && symptome.notes!.isNotEmpty) ...[
          const Divider(),
          _buildDetailInfo(
            icon: Icons.note_rounded,
            label: 'Notes',
            value: symptome.notes!,
            color: isDark ? Colors.white : Colors.black,
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Flexible(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: () {
                  SymptomeLogger.info(
                    '✅ Résolution du symptôme #${symptome.id}',
                  );
                  Navigator.pop(context);
                  _resolveSymptome(symptome.id!);
                },
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Résoudre'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: () {
                  SymptomeLogger.debug(
                    '✏️ Modification du symptôme #${symptome.id}',
                  );
                  Navigator.pop(context);
                  _editSymptome(symptome.id!);
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Modifier'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6C5CE7),
                  side: const BorderSide(color: Color(0xFF6C5CE7)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              SymptomeLogger.warning(
                '🗑️ Suppression du symptôme #${symptome.id}',
              );
              Navigator.pop(context);
              _deleteSymptome(symptome.id!);
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Supprimer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subtitle,
    bool isStatus = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade800.withOpacity(0.5)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isStatus ? color : (isDark ? Colors.white : Colors.black),
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailInfo({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            flex: 1,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // CRUD OPERATIONS
  // ==========================================================================
  Future<void> _deleteSymptome(int id) async {
    SymptomeLogger.info('🗑️ Suppression du symptôme #$id');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.trash, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text(
              'Supprimer le symptôme',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Voulez-vous vraiment supprimer ce symptôme ? Cette action est irréversible.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              SymptomeLogger.debug('❌ Suppression annulée');
              Navigator.pop(context, false);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Annuler'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () {
                SymptomeLogger.debug('✅ Suppression confirmée');
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Supprimer',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final service = SymptomeService();
        SymptomeLogger.api('DELETE', '/symptomes/$id');

        await service.deleteSymptome(id);
        await _loadData();

        SymptomeLogger.success('✅ Symptôme #$id supprimé');
        if (mounted) {
          _showSnackbar('Symptôme supprimé avec succès');
        }
      } catch (e, stackTrace) {
        SymptomeLogger.error(
          'Erreur lors de la suppression',
          error: e,
          stackTrace: stackTrace,
        );
        if (mounted) {
          _showSnackbar('Erreur: $e', isError: true);
        }
      }
    }
  }

  Future<void> _resolveSymptome(int id) async {
    SymptomeLogger.info('✅ Résolution du symptôme #$id');

    try {
      final service = SymptomeService();
      SymptomeLogger.api('PATCH', '/symptomes/$id/resolve');

      await service.resolveSymptome(id);
      await _loadData();

      SymptomeLogger.success('✅ Symptôme #$id résolu');
      if (mounted) {
        _showSnackbar('✅ Symptôme marqué comme résolu !');
      }
    } catch (e, stackTrace) {
      SymptomeLogger.error(
        'Erreur lors de la résolution',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showSnackbar('Erreur: $e', isError: true);
      }
    }
  }

  Future<void> _editSymptome(int id) async {
    SymptomeLogger.info('✏️ Édition du symptôme #$id');

    final symptome = _symptomes.firstWhere((s) => s.id == id);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SymptomeFormScreen(symptome: symptome),
      ),
    );
    await _loadData();
    SymptomeLogger.success('✅ Symptôme #$id modifié');
  }

  // ==========================================================================
  // SNACKBAR
  // ==========================================================================
  void _showSnackbar(String message, {bool isError = false}) {
    SymptomeLogger.debug(
      '📢 Snackbar: "$message" (${isError ? 'error' : 'success'})',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError
            ? Colors.red.shade500
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white.withOpacity(0.8),
          onPressed: () {},
        ),
      ),
    );
  }

  // ==========================================================================
  // FAB
  // ==========================================================================
  Widget _buildFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: FloatingActionButton(
        onPressed: _navigateToForm,
        backgroundColor: const Color(0xFF6C5CE7),
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        tooltip: 'Ajouter un symptôme',
      ),
    );
  }

  void _navigateToForm() {
    SymptomeLogger.info('➕ Navigation vers le formulaire d\'ajout');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SymptomeFormScreen()),
    ).then((_) => _loadData());
  }

  // ==========================================================================
  // DIALOGUE D'ANALYSE IA
  // ==========================================================================
  void _showFullAnalysisDialog() {
    if (_symptomes.isEmpty) {
      SymptomeLogger.warning('❌ Tentative d\'analyse IA sans symptômes');
      _showSnackbar('❌ Aucun symptôme à analyser');
      return;
    }

    SymptomeLogger.info('📊 Ouverture de l\'analyse IA complète');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '📊 Analyse IA complète',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Flexible(
              flex: 1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: IAAnalysisWidget(symptomes: _symptomes),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================
  String _getStatusLabel(String status) {
    switch (status) {
      case 'actif':
        return 'Actif';
      case 'resolu':
        return 'Résolu';
      case 'en_amelioration':
        return 'En amélioration';
      case 'aggravation':
        return 'Aggravation';
      default:
        return status;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'douleur':
        return 'Douleur';
      case 'fatigue':
        return 'Fatigue';
      case 'digestif':
        return 'Digestif';
      case 'respiratoire':
        return 'Respiratoire';
      case 'neurologique':
        return 'Neurologique';
      case 'cardiaque':
        return 'Cardiaque';
      case 'musculaire':
        return 'Musculaire';
      case 'cutane':
        return 'Cutane';
      default:
        return type;
    }
  }

  Color _getSeverityColor(String level) {
    switch (level) {
      case 'Faible':
        return const Color(0xFF00B894);
      case 'Modéré':
        return const Color(0xFFFDCB6E);
      case 'Élevé':
        return const Color(0xFFE17055);
      case 'Critique':
        return const Color(0xFFD63031);
      default:
        return Colors.grey;
    }
  }
}
