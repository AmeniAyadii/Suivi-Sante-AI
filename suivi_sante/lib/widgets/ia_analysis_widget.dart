// lib/widgets/ia_analysis_widget.dart
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:iconsax/iconsax.dart';
import '../models/symptome.dart';
import '../services/symptom_analysis_service.dart';

// ============================================================================
// LOGGER
// ============================================================================
class IAAnalysisLogger {
  static const String _tag = '🤖 IAAnalysisWidget';
  
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
    developer.log(log, name: 'ERROR', time: DateTime.now(), error: error, stackTrace: stackTrace);
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
  
  static void performance(String operation, Duration duration) {
    final log = '$_tag - ⏱️ $operation: ${duration.inMilliseconds}ms';
    print(log);
    developer.log(log, name: 'PERFORMANCE', time: DateTime.now());
  }
}

// ============================================================================
// WIDGET PRINCIPAL
// ============================================================================
class IAAnalysisWidget extends StatefulWidget {
  final List<Symptome> symptomes;

  const IAAnalysisWidget({
    super.key,
    required this.symptomes,
  });

  @override
  State<IAAnalysisWidget> createState() => _IAAnalysisWidgetState();
}

class _IAAnalysisWidgetState extends State<IAAnalysisWidget> {
  final SymptomAnalysisService _service = SymptomAnalysisService();

  bool _isLoading = false;
  bool _hasResult = false;
  Map<String, dynamic>? _analysisResult;
  String? _error;

  @override
  void initState() {
    super.initState();
    IAAnalysisLogger.info('🔄 Initialisation avec ${widget.symptomes.length} symptômes');
    _performAnalysis();
  }

  @override
  void didUpdateWidget(IAAnalysisWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.symptomes.length != oldWidget.symptomes.length) {
      IAAnalysisLogger.debug('🔄 Mise à jour: ${oldWidget.symptomes.length} → ${widget.symptomes.length} symptômes');
      _performAnalysis();
    }
  }

  Future<void> _performAnalysis() async {
    if (widget.symptomes.isEmpty) {
      IAAnalysisLogger.warning('⚠️ Aucun symptôme à analyser');
      return;
    }

    IAAnalysisLogger.info('🔍 Début de l\'analyse');
    final stopwatch = Stopwatch()..start();

    setState(() {
      _isLoading = true;
      _hasResult = false;
      _error = null;
    });

    try {
      final result = await _service.analyzeSymptoms(widget.symptomes);
      
      stopwatch.stop();
      IAAnalysisLogger.performance('Analyse terminée', stopwatch.elapsed);
      
      if (mounted) {
        setState(() {
          _analysisResult = result;
          _hasResult = true;
          _isLoading = false;
        });
        IAAnalysisLogger.success('✅ Analyse réussie');
        IAAnalysisLogger.debug('📊 Résultat: ${result.keys.join(', ')}');
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      IAAnalysisLogger.error('Erreur lors de l\'analyse', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshAnalysis() async {
    IAAnalysisLogger.info('🔄 Rafraîchissement de l\'analyse');
    await _performAnalysis();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingShimmer();
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (!_hasResult || _analysisResult == null) {
      return const SizedBox.shrink();
    }

    return _buildResultWidget();
  }

  // ==========================================================================
  // LOADING
  // ==========================================================================
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 40, color: Colors.grey),
              SizedBox(height: 12),
              Text('Analyse IA en cours...', style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // ERROR
  // ==========================================================================
  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Erreur: $_error',
              style: const TextStyle(color: Colors.red, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: _refreshAnalysis,
            child: const Text('Réessayer', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // RESULTAT PRINCIPAL
  // ==========================================================================
  Widget _buildResultWidget() {
    final summary = _analysisResult?['summary'] ?? '';
    final insights = _analysisResult?['insights'] ?? {};
    final recommendations = _analysisResult?['recommendations'] ?? '';
    final severityTrend = _analysisResult?['severity_trend'] ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6C5CE7),
            Color(0xFFA29BFE),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildSummarySection(summary),
          if (insights.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInsightsSection(insights),
          ],
          if (severityTrend.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSeverityTrendSection(severityTrend),
          ],
          if (recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildRecommendationsSection(recommendations),
          ],
          const SizedBox(height: 8),
          _buildFooter(),
        ],
      ),
    );
  }

  // ==========================================================================
  // HEADER
  // ==========================================================================
  Widget _buildHeader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          '🤖 Analyse IA',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // ✅ SECTION RÉSUMÉ - CORRIGÉE AVEC FORMATAGE PROPRE
  // ==========================================================================
  Widget _buildSummarySection(String summary) {
    if (summary.isEmpty) {
      return const SizedBox.shrink();
    }

    // ✅ Nettoyer et formater le texte
    final cleanSummary = summary
        .replaceAll('**', '')
        .replaceAll('\\n', '\n')
        .replaceAll('\n\n', '\n')
        .replaceAll('• ', '•')  // Nettoyer les puces
        .trim();

    // ✅ Découper en lignes et filtrer les vides
    final lines = cleanSummary
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: lines.asMap().entries.map((entry) {
          final index = entry.key;
          final line = entry.value;
          
          // ✅ Détecter les titres (lignes avec emojis ou premières lignes)
          final isTitle = line.startsWith('📊') || 
                          line.startsWith('🔍') ||
                          line.startsWith('⚠️') ||
                          line.startsWith('✅') ||
                          line.startsWith('•') ||
                          (index == 0 && lines.length > 1);

          // ✅ Détecter les puces
          final isBullet = line.startsWith('•') || line.startsWith('-');

          // ✅ Extraire le texte sans la puce
          final displayText = isBullet ? line.substring(1).trim() : line;

          // ✅ Style différent pour les puces
          if (isBullet) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      displayText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // ✅ Texte normal ou titre
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              line,
              style: TextStyle(
                color: Colors.white,
                fontSize: isTitle ? 14 : 13,
                fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
                height: 1.5,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================================================
  // SECTION INSIGHTS
  // ==========================================================================
  Widget _buildInsightsSection(Map<String, dynamic> insights) {
    final items = <Widget>[];

    if (insights['most_frequent'] != null && insights['most_frequent'] != 'Aucun') {
      items.add(_buildInsightItem(
        icon: Icons.trending_up,
        text: 'Symptôme le plus fréquent: ${insights['most_frequent']}',
        color: Colors.amber.shade300,
      ));
    }

    if (insights['overall_trend'] != null) {
      final trend = insights['overall_trend'];
      String trendLabel = trend;
      if (trend == 'amélioration') trendLabel = '✅ En amélioration';
      else if (trend == 'détérioration') trendLabel = '⚠️ Détérioration';
      else trendLabel = '➡️ Stable';
      
      items.add(_buildInsightItem(
        icon: Icons.analytics,
        text: 'Tendance globale: $trendLabel',
        color: Colors.cyan.shade300,
      ));
    }

    if (insights['worst_day'] != null) {
      final worstDay = insights['worst_day'];
      if (worstDay['symptom'] != null) {
        items.add(_buildInsightItem(
          icon: Icons.warning,
          text: '⚠️ Jour critique: ${worstDay['symptom']} (Niveau ${worstDay['level'] ?? '?'}/10)',
          color: Colors.red.shade300,
        ));
      }
    }

    if (insights['most_severe'] != null) {
      final severe = insights['most_severe'];
      if (severe['symptom'] != null) {
        items.add(_buildInsightItem(
          icon: Icons.emergency,
          text: '🔴 Plus sévère: ${severe['symptom']} (Niveau ${severe['level'] ?? '?'}/10)',
          color: Colors.red.shade300,
        ));
      }
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(
                '💡 Insights',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String text,
    Color color = Colors.white70,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SECTION SÉVÉRITÉ
  // ==========================================================================
  Widget _buildSeverityTrendSection(Map<String, dynamic> severityTrend) {
    final avg = severityTrend['average'] ?? 0;
    final maxVal = severityTrend['max'] ?? 0;
    final minVal = severityTrend['min'] ?? 0;
    final stdDev = severityTrend['std_dev'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.assessment, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(
                '📊 Tendance de sévérité',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildSeverityChip(
                label: 'Moyenne',
                value: avg.toString(),
                icon: Icons.calculate,
                color: Colors.cyan.shade300,
              ),
              _buildSeverityChip(
                label: 'Max',
                value: maxVal.toString(),
                icon: Icons.arrow_upward,
                color: Colors.red.shade300,
              ),
              _buildSeverityChip(
                label: 'Min',
                value: minVal.toString(),
                icon: Icons.arrow_downward,
                color: Colors.green.shade300,
              ),
              _buildSeverityChip(
                label: 'Écart-type',
                value: stdDev.toString(),
                icon: Icons.insights,
                color: Colors.orange.shade300,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChip({
    required String label,
    required String value,
    required IconData icon,
    Color color = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SECTION RECOMMANDATIONS
  // ==========================================================================
  Widget _buildRecommendationsSection(String recommendations) {
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    // ✅ Nettoyer et formater les recommandations
    final cleanRecommendations = recommendations
        .replaceAll('\\n', '\n')
        .replaceAll('\n\n', '\n')
        .trim();

    final lines = cleanRecommendations
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(Icons.medical_services, color: Colors.white, size: 16),
              SizedBox(width: 6),
              Text(
                '💡 Recommandations',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...lines.map((line) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Text(
                    line,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.6,
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

  // ==========================================================================
  // FOOTER
  // ==========================================================================
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 12,
            color: Colors.white.withOpacity(0.4),
          ),
          const SizedBox(width: 4),
          Text(
            'Analyse basée sur ${widget.symptomes.length} symptômes',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}