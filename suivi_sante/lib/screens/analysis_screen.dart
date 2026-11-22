// lib/screens/tension/analysis_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:suivi_sante_pro/models/tension_analysis.dart';
import '../../providers/tension_provider.dart';
import '../../models/tension_measure.dart';

/// 📊 Écran d'analyse des tendances de tension artérielle
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  // ============================================
  // VARIABLES D'ÉTAT
  // ============================================
  bool _isLoading = false;
  bool _isInitialLoad = true;
  Map<String, dynamic>? _predictions;
  String? _errorMessage;
  DateTime? _lastAnalysisDate;

  // Contrôleurs pour les animations
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ============================================
  // CYCLE DE VIE
  // ============================================
  @override
  void initState() {
    super.initState();
    _log('🔄 Initialisation de AnalysisScreen');

    // Initialiser les animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // 🔥 Charger les données après la construction
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalysis();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ============================================
  // MÉTHODES DE LOG
  // ============================================
  void _log(String message, {String level = 'INFO'}) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] [$level] 📊 AnalysisScreen: $message');
  }

  // ============================================
  // MÉTHODES DE CHARGEMENT
  // ============================================
  Future<void> _loadAnalysis() async {
    if (_isLoading) return;

    _log('📥 Début du chargement de l\'analyse');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<TensionProvider>();
      _log('📊 Nombre de mesures: ${provider.measures.length}');

      // Vérifier si des données existent
      if (provider.measures.isEmpty) {
        _log('⚠️ Aucune mesure disponible, ajout de données d\'exemple');
        provider.addSampleData();
      }

      _log('🤖 Appel à analyzeTrends...');
      final success = await provider.analyzeTrends();

      if (success) {
        _log('✅ Analyse des tendances terminée');
      } else {
        _log('⚠️ L\'analyse a retourné une erreur: ${provider.error}');
      }

      // Charger les prédictions (Premium)
      if (provider.measures.length >= 3) {
        _log('🔮 Chargement des prédictions...');
        _predictions = await provider.predict(7);
        if (_predictions != null && _predictions!['available'] == true) {
          _log('✅ Prédictions chargées avec succès');
        } else {
          _log('⚠️ Aucune prédiction disponible');
        }
      } else {
        _log(
          '⚠️ Pas assez de données pour les prédictions (${provider.measures.length}/3)',
        );
      }

      _lastAnalysisDate = DateTime.now();
      _log('✅ Analyse terminée avec succès');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialLoad = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      _log('❌ Erreur lors du chargement: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialLoad = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _refreshAnalysis() async {
    _log('🔄 Rafraîchissement manuel');
    await _loadAnalysis();
  }

  // ============================================
  // BUILD PRINCIPAL
  // ============================================
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TensionProvider>();
    final analysis = provider.analysis;
    final measures = provider.measures;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(provider.isLoading),
      body: _buildBody(provider, analysis, measures),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // ============================================
  // APP BAR
  // ============================================
  PreferredSizeWidget _buildAppBar(bool isLoading) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
        onPressed: () {
          _log('🏠 Retour au Dashboard');
          Navigator.pushReplacementNamed(context, '/dashboard');
        },
        tooltip: 'Retour au Dashboard',
      ),
      title: const Row(
        children: [
          Icon(Icons.analytics, color: Color(0xFF2563EB)),
          SizedBox(width: 8),
          Text(
            'Analyse IA',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: const Color(0xFF1E293B),
      actions: [
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF2563EB)),
          onPressed: isLoading ? null : _refreshAnalysis,
          tooltip: 'Rafraîchir',
        ),
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Color(0xFF2563EB)),
          onPressed: _exportReport,
          tooltip: 'Exporter le rapport',
        ),
      ],
    );
  }

  // ============================================
  // BODY PRINCIPAL
  // ============================================
  Widget _buildBody(
    TensionProvider provider,
    TensionAnalysis? analysis,
    List<TensionMeasure> measures,
  ) {
    if (_isLoading) {
      return _buildLoadingShimmer();
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (measures.isEmpty) {
      return _buildNoDataWidget();
    }

    if (analysis == null) {
      return _buildNoAnalysisWidget(measures);
    }

    return _buildContent(analysis, measures);
  }

  // ============================================
  // WIDGETS DE CHARGEMENT
  // ============================================
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // WIDGETS D'ERREUR
  // ============================================
  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Oups ! Une erreur est survenue',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Erreur inconnue',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _refreshAnalysis,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
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
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // WIDGET PAS DE DONNÉES
  // ============================================
  Widget _buildNoDataWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.analytics_outlined,
                size: 48,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune mesure disponible',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez votre première mesure pour commencer l\'analyse.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color.fromARGB(255, 85, 10, 10),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _log('📝 Navigation vers l\'ajout de mesure');
                Navigator.pushNamed(context, '/tension/ajout');
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une mesure'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
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
      ),
    );
  }

  // ============================================
  // WIDGET PAS D'ANALYSE
  // ============================================
  Widget _buildNoAnalysisWidget(List<TensionMeasure> measures) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline,
                size: 48,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Analyse non disponible',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous avez ${measures.length} mesure${measures.length > 1 ? 's' : ''}. L\'analyse nécessite au moins 3 mesures.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _refreshAnalysis,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    _log('📝 Navigation vers l\'ajout de mesure');
                    Navigator.pushNamed(context, '/tension/ajout');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // CONTENU PRINCIPAL
  // ============================================
  Widget _buildContent(
    TensionAnalysis analysis,
    List<TensionMeasure> measures,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _refreshAnalysis,
        color: const Color(0xFF2563EB),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(analysis),
              const SizedBox(height: 16),
              if (measures.length >= 3) ...[
                _buildChart(measures),
                const SizedBox(height: 16),
              ],
              _buildDetails(analysis),
              const SizedBox(height: 16),
              if (_predictions != null &&
                  _predictions!['available'] == true) ...[
                _buildPredictions(_predictions!),
                const SizedBox(height: 16),
              ],
              _buildRecommendations(analysis),
              const SizedBox(height: 16),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // CARTE DE RÉSUMÉ
  // ============================================
  Widget _buildSummaryCard(TensionAnalysis analysis) {
    final gradientColors = analysis.severityLevel == 'danger'
        ? [Colors.red.shade700, Colors.red.shade400]
        : analysis.severityLevel == 'warning'
        ? [Colors.orange.shade700, Colors.orange.shade400]
        : [Colors.green.shade700, Colors.green.shade400];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientColors[0], gradientColors[1]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  analysis.severityIcon,
                  color: gradientColors[0],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  analysis.severityLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  analysis.severityLevel.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              analysis.summary,
              style: const TextStyle(
                color: Colors.white,
                height: 1.6,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // GRAPHIQUE
  // ============================================
  Widget _buildChart(List<TensionMeasure> measures) {
    final reversed = measures.reversed.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                'Évolution des mesures',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey,
                      strokeWidth: 0.5,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${value.toInt()}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < reversed.length) {
                          final measure = reversed[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('dd/MM').format(measure.measureDate),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                minX: 0,
                maxX: reversed.length.toDouble() - 1,
                minY: 40,
                maxY: 200,
                lineBarsData: [
                  LineChartBarData(
                    spots: reversed.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.systolic.toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: Colors.red,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.red.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: reversed.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.diastolic.toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: Colors.blue,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.grey.shade900,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final measure = reversed[spot.spotIndex];
                        return LineTooltipItem(
                          '${spot.barIndex == 0 ? "Systolique" : "Diastolique"}: ${spot.y.toInt()} mmHg\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(measure.measureDate),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.red, 'Systolique'),
              const SizedBox(width: 24),
              _buildLegendItem(Colors.blue, 'Diastolique'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 20, height: 3, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================
  // DÉTAILS DE L'ANALYSE
  // ============================================
  Widget _buildDetails(TensionAnalysis analysis) {
    final details = analysis.details;
    if (details == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Détails de l\'analyse',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.start,
            children: [
              _buildDetailChip(
                label: 'Mesures',
                value: '${details['measure_count'] ?? 0}',
                icon: Icons.analytics,
                color: Colors.blue,
              ),
              _buildDetailChip(
                label: 'Moyenne',
                value:
                    '${details['avg_systolic'] ?? 0}/${details['avg_diastolic'] ?? 0}',
                icon: Icons.calculate,
                color: Colors.purple,
              ),
              _buildDetailChip(
                label: 'Min',
                value:
                    '${details['min_systolic'] ?? 0}/${details['min_diastolic'] ?? 0}',
                icon: Icons.arrow_downward,
                color: Colors.green,
              ),
              _buildDetailChip(
                label: 'Max',
                value:
                    '${details['max_systolic'] ?? 0}/${details['max_diastolic'] ?? 0}',
                icon: Icons.arrow_upward,
                color: Colors.orange,
              ),
              _buildDetailChip(
                label: 'Tendance',
                value:
                    '${(details['trend_systolic'] ?? 0).toStringAsFixed(1)} mmHg/jour',
                icon: Icons.trending_up,
                color: Colors.red,
              ),
              _buildDetailChip(
                label: 'Stabilité',
                value: details['stability'] ?? 'stable',
                icon: Icons.insights,
                color: Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // PRÉDICTIONS (PREMIUM)
  // ============================================
  Widget _buildPredictions(Map<String, dynamic> predictions) {
    final predData = predictions['predictions'] as Map<String, dynamic>?;
    if (predData == null) return const SizedBox();

    final systolic = predData['systolic'] as Map<String, dynamic>?;
    final diastolic = predData['diastolic'] as Map<String, dynamic>?;

    if (systolic == null || diastolic == null) return const SizedBox();

    final systolicValues = systolic['future_values'] as List?;
    final diastolicValues = diastolic['future_values'] as List?;

    if (systolicValues == null || diastolicValues == null)
      return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_graph,
                  color: Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  '🔮 Prédictions 7 jours',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white,
                      strokeWidth: 0.5,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: _predictionLeftTitleWidget,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: _predictionBottomTitleWidget,
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                minX: 0,
                maxX: systolicValues.length.toDouble() - 1,
                minY: 40,
                maxY: 180,
                lineBarsData: [
                  LineChartBarData(
                    spots: systolicValues.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: Colors.white,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.white.withOpacity(0.5),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: diastolicValues.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value.toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: Colors.white.withOpacity(0.6),
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.white.withOpacity(0.6),
                          strokeWidth: 1,
                          strokeColor: Colors.white.withOpacity(0.3),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Colors.white,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final day = spot.spotIndex + 1;
                        return LineTooltipItem(
                          'Jour $day: ${spot.y.toInt()} mmHg',
                          TextStyle(
                            color: spot.barIndex == 0
                                ? Colors.red
                                : Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPredictionLegendItem(Colors.white, 'Systolique'),
              const SizedBox(width: 20),
              _buildPredictionLegendItem(
                Colors.white.withOpacity(0.6),
                'Diastolique',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _predictionLeftTitleWidget(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        '${value.toInt()}',
        style: const TextStyle(fontSize: 10, color: Colors.white70),
      ),
    );
  }

  static Widget _predictionBottomTitleWidget(double value, TitleMeta meta) {
    final day = (value + 1).toInt();
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        'J$day',
        style: const TextStyle(fontSize: 10, color: Colors.white70),
      ),
    );
  }

  Widget _buildPredictionLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 20, height: 3, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  // ============================================
  // RECOMMANDATIONS
  // ============================================
  Widget _buildRecommendations(TensionAnalysis analysis) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: analysis.severityColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.lightbulb,
                  color: Colors.yellow.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  '💡 Recommandations personnalisées',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: analysis.severityColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: analysis.severityColor.withOpacity(0.1),
              ),
            ),
            child: Text(
              analysis.recommendation,
              style: TextStyle(
                height: 1.8,
                color: Colors.grey.shade800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // FOOTER
  // ============================================
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                'Dernière analyse: ${_lastAnalysisDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(_lastAnalysisDate!) : 'N/A'}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 14,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 6),
              Text(
                'IA Médicale sécurisée',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // FLOATING ACTION BUTTON
  // ============================================
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        _log('📝 Navigation vers l\'ajout de mesure depuis le FAB');
        Navigator.pushNamed(context, '/tension/ajout');
      },
      backgroundColor: const Color(0xFF2563EB),
      child: const Icon(Icons.add, color: Colors.white),
      tooltip: 'Ajouter une mesure',
    );
  }

  // ============================================
  // MÉTHODES UTILITAIRES
  // ============================================
  Future<void> _exportReport() async {
    _log('📤 Export du rapport demandé');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📤 Fonctionnalité d\'export en développement'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
