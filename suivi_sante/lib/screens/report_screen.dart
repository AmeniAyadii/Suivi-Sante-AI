// lib/screens/report_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../services/report_service.dart';
import '../services/logger_service.dart';
import '../models/report.dart';
import '../widgets/report_card.dart';
import '../widgets/report_form_dialog.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with TickerProviderStateMixin {
  // ==================== ÉTATS ====================
  List<Report> _reports = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  int _selectedType = 0;
  String _searchQuery = '';
  String _filterStatus = 'Tous';
  bool _isGridView = false;
  bool _isFilterExpanded = false;
  int _selectedYear = DateTime.now().year;

  // ==================== TYPES DE RAPPORTS ====================
  final List<Map<String, dynamic>> _reportTypes = [
    {'label': '📊 Mensuel', 'value': 'monthly', 'days': 30, 'icon': Iconsax.calendar},
    {'label': '📈 Trimestriel', 'value': 'quarterly', 'days': 90, 'icon': Iconsax.chart},
    {'label': '📉 Annuel', 'value': 'annual', 'days': 365, 'icon': Iconsax.chart_2},
    {'label': '📋 Personnalisé', 'value': 'custom', 'days': 0, 'icon': Iconsax.edit},
  ];

  // ==================== STATISTIQUES ====================
  Map<String, int> _stats = {
    'total': 0,
    'completed': 0,
    'pending': 0,
    'failed': 0,
  };

  // ==================== ANIMATIONS ====================
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    print('🔵🔵🔵 ReportScreen INITIALIZED 🔵🔵🔵');
    LoggerService.info('🔄 Initialisation de ReportScreen');
    _initAnimations();
    _loadReports();
    _selectedYear = DateTime.now().year;
    LoggerService.debug('📅 Année sélectionnée par défaut: $_selectedYear');
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    LoggerService.debug('🗑️ ReportScreen détruit');
    super.dispose();
  }

  // ==================== CHARGEMENT DES DONNÉES ====================
  Future<void> _loadReports() async {
    print('🔵🔵🔵 _loadReports() CALLED 🔵🔵🔵');
    LoggerService.info('🔄 Chargement des rapports...');
    final stopwatch = Stopwatch()..start();
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reportService = ReportService();
      _reports = await reportService.getReports();
      _updateStats();
      
      LoggerService.state('ReportScreen', {
        'total': _stats['total'],
        'completed': _stats['completed'],
        'pending': _stats['pending'],
        'failed': _stats['failed'],
      });
      
      setState(() => _isLoading = false);
      LoggerService.success('✅ ${_reports.length} rapports chargés avec succès');
      
      stopwatch.stop();
      LoggerService.performance('Chargement des rapports', stopwatch.elapsed);
      
    } catch (e, stackTrace) {
      LoggerService.error('Erreur lors du chargement', error: e, stackTrace: stackTrace);
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _updateStats() {
    _stats = {
      'total': _reports.length,
      'completed': _reports.where((r) => r.status == 'completed').length,
      'pending': _reports.where((r) => r.status == 'pending').length,
      'failed': _reports.where((r) => r.status == 'failed').length,
    };
  }

  Future<void> _refreshReports() async {
    LoggerService.info('🔄 Rafraîchissement des rapports...');
    setState(() => _isRefreshing = true);
    await _loadReports();
    setState(() => _isRefreshing = false);
  }

  // ==================== FILTRES ====================
  List<Report> get _filteredReports {
    return _reports.where((report) {
      final searchMatch = _searchQuery.isEmpty ||
          report.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report.type.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final statusMatch = _filterStatus == 'Tous' || report.status == _filterStatus;
      
      final yearMatch = _selectedYear == 0 || 
          report.createdAt.year == _selectedYear;
      
      return searchMatch && statusMatch && yearMatch;
    }).toList();
  }

  List<int> get _availableYears {
    final years = _reports.map((r) => r.createdAt.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  // ==================== GÉNÉRATION DE RAPPORT ====================
  Future<void> _generateReport(String type) async {
    LoggerService.info('🚀 Génération d\'un rapport de type: $type');
    
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (type) {
      case 'monthly':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'quarterly':
        startDate = now.subtract(const Duration(days: 90));
        break;
      case 'annual':
        startDate = now.subtract(const Duration(days: 365));
        break;
      default:
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => const ReportFormDialog(),
        );
        if (result == null) return;
        startDate = result['startDate'];
        endDate = result['endDate'];
        break;
    }

    setState(() => _isLoading = true);

    try {
      final reportService = ReportService();
      await reportService.generateReport(
        dateStart: startDate.toIso8601String(),
        dateEnd: endDate.toIso8601String(),
        type: type,
      );

      if (mounted) {
        await _loadReports();
        _showSnackbar('✅ Rapport généré avec succès', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('❌ Erreur: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== GÉNÉRATION PDF ====================
  Future<void> _generatePDF(Report report) async {
    LoggerService.info('📄 Génération du PDF pour le rapport #${report.id}');
    
    try {
      final pdf = await _createPDF(report);
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/rapport_${report.id}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '📄 Rapport médical - ${report.title}\n\n'
               'Période: ${DateFormat('dd/MM/yyyy').format(report.dateStart)} - ${DateFormat('dd/MM/yyyy').format(report.dateEnd)}\n'
               'Généré avec Suivi Santé AI',
      );

      LoggerService.success('✅ PDF partagé avec succès');
      _showSnackbar('✅ PDF partagé avec succès', Colors.green);
    } catch (e) {
      LoggerService.error('Erreur lors de la génération du PDF', error: e);
      _showSnackbar('❌ Erreur: $e', Colors.red);
    }
  }

  // ==================== CRÉATION PDF ====================
  Future<pw.Document> _createPDF(Report report) async {
    final pdf = pw.Document();
    final data = report.data ?? {};
    final user = data['user'] ?? {};
    final stats = data['stats'] ?? {};
    final medicaments = data['medicaments'] ?? [];
    final symptomes = data['symptomes'] ?? [];
    final rendezvous = data['rendezvous'] ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildPDFHeader(report),
          pw.SizedBox(height: 20),
          _buildPDFPatientInfo(user),
          pw.SizedBox(height: 20),
          _buildPDFSummary(stats),
          pw.SizedBox(height: 20),
          _buildPDFMedications(medicaments),
          pw.SizedBox(height: 20),
          _buildPDFSymptoms(symptomes),
          pw.SizedBox(height: 20),
          _buildPDFAppointments(rendezvous),
          pw.SizedBox(height: 20),
          _buildPDFFooter(),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildPDFHeader(Report report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '📄 Rapport Médical',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: report.status == 'completed' ? PdfColors.green100 : PdfColors.orange100,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Text(
                report.statusLabel,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: report.status == 'completed' ? PdfColors.green700 : PdfColors.orange700,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Généré le ${DateFormat('dd MMMM yyyy à HH:mm').format(report.createdAt)}',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildPDFPatientInfo(Map<String, dynamic> user) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '👤 Informations Patient',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Nom: ${user['nom'] ?? 'Non renseigné'}'),
          pw.SizedBox(height: 4),
          pw.Text('Âge: ${user['age'] ?? 'Non renseigné'} ans'),
          pw.SizedBox(height: 4),
          pw.Text('Email: ${user['email'] ?? 'Non renseigné'}'),
          pw.SizedBox(height: 4),
          pw.Text('Sexe: ${user['sexe'] ?? 'Non renseigné'}'),
          pw.SizedBox(height: 4),
          pw.Text('Taille: ${user['taille'] ?? 'Non renseigné'} cm'),
          pw.SizedBox(height: 4),
          pw.Text('Poids: ${user['poids'] ?? 'Non renseigné'} kg'),
          if (user['allergies'] != null && user['allergies'].isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text('Allergies: ${user['allergies']}'),
          ],
          if (user['maladies_chroniques'] != null && user['maladies_chroniques'].isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text('Maladies chroniques: ${user['maladies_chroniques']}'),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildPDFSummary(Map<String, dynamic> stats) {
    final totalMedicaments = stats['medicaments_total'] ?? 0;
    final totalSymptomes = stats['symptomes_total'] ?? 0;
    final totalRendezvous = stats['rendezvous_total'] ?? 0;
    final adherence = totalMedicaments > 0 
        ? (stats['medicaments_actifs'] ?? 0) / totalMedicaments * 100
        : 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '📊 Résumé de la période',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatBox('Médicaments', totalMedicaments.toString()),
              _buildStatBox('Symptômes', totalSymptomes.toString()),
              _buildStatBox('Rendez-vous', totalRendezvous.toString()),
              _buildStatBox('Adhérence', '${adherence.toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        boxShadow: [
          const pw.BoxShadow(
            color: PdfColors.grey200,
            blurRadius: 4,
          ),
        ],
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFMedications(List<dynamic> medicaments) {
    if (medicaments.isEmpty) return pw.Container();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '💊 Médicaments (${medicaments.length})',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Nom', isHeader: true),
                _buildTableCell('Dosage', isHeader: true),
                _buildTableCell('Fréquence', isHeader: true),
                _buildTableCell('Statut', isHeader: true),
              ],
            ),
            ...medicaments.map((med) => pw.TableRow(
              children: [
                _buildTableCell(med['nom'] ?? 'N/A'),
                _buildTableCell(med['dosage'] ?? 'N/A'),
                _buildTableCell(med['frequence'] ?? 'N/A'),
                _buildTableCell(med['statut'] ?? 'N/A'),
              ],
            )).toList(),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPDFSymptoms(List<dynamic> symptomes) {
    if (symptomes.isEmpty) return pw.Container();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '🩺 Symptômes (${symptomes.length})',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Description', isHeader: true),
                _buildTableCell('Niveau', isHeader: true),
                _buildTableCell('Date', isHeader: true),
              ],
            ),
            ...symptomes.map((sym) => pw.TableRow(
              children: [
                _buildTableCell(sym['description'] ?? 'N/A'),
                _buildTableCell('${sym['niveau'] ?? 'N/A'}/10'),
                _buildTableCell(
                  sym['date_enregistrement'] != null 
                    ? DateFormat('dd/MM/yyyy').format(DateTime.parse(sym['date_enregistrement']))
                    : 'N/A'
                ),
              ],
            )).toList(),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPDFAppointments(List<dynamic> rendezvous) {
    if (rendezvous.isEmpty) return pw.Container();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '📅 Rendez-vous (${rendezvous.length})',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Titre', isHeader: true),
                _buildTableCell('Médecin', isHeader: true),
                _buildTableCell('Date', isHeader: true),
                _buildTableCell('Statut', isHeader: true),
              ],
            ),
            ...rendezvous.map((rdv) => pw.TableRow(
              children: [
                _buildTableCell(rdv['titre'] ?? 'N/A'),
                _buildTableCell(rdv['medecin_nom'] ?? 'N/A'),
                _buildTableCell(
                  rdv['date_heure'] != null 
                    ? DateFormat('dd/MM/yyyy').format(DateTime.parse(rdv['date_heure']))
                    : 'N/A'
                ),
                _buildTableCell(rdv['statut'] ?? 'N/A'),
              ],
            )).toList(),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 11 : 10,
        ),
      ),
    );
  }

  pw.Widget _buildPDFFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(
          'Ce rapport a été généré automatiquement. Les informations sont confidentielles.',
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey500,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '© ${DateTime.now().year} Suivi Santé AI - Tous droits réservés',
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey500,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    print('🔵🔵🔵 ReportScreen BUILD called 🔵🔵🔵');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFF5F7FB),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingScreen() : _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  // ==================== APP BAR ====================
  PreferredSizeWidget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = _stats['total'] ?? 0;

    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? Colors.grey[850] : Colors.white,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          tooltip: 'Retour au Dashboard',
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rapports médicaux',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$total rapports disponibles',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: AnimatedRotation(
            turns: _isRefreshing ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : Colors.grey.shade700,
            ),
          ),
          onPressed: _refreshReports,
          tooltip: 'Rafraîchir',
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              _isGridView ? Icons.list_rounded : Icons.grid_view_rounded,
              color: isDark ? Colors.white : Colors.grey.shade700,
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'Vue en liste' : 'Vue en grille',
          ),
        ),
      ],
    );
  }

  // ==================== BODY ====================
  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (_reports.isEmpty) {
      return _buildEmptyScreen();
    }

    return Column(
      children: [
        _buildStatsOverview(),
        _buildSearchAndFilter(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshReports,
            color: Colors.blue,
            backgroundColor: Colors.white,
            child: _isGridView ? _buildGridView() : _buildListView(),
          ),
        ),
      ],
    );
  }

  // ==================== STATS OVERVIEW (CORRIGÉ SANS OVERFLOW) ====================
  Widget _buildStatsOverview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = _stats['total'] ?? 0;
    final completed = _stats['completed'] ?? 0;
    final pending = _stats['pending'] ?? 0;
    final failed = _stats['failed'] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatChip('📊 Total', total, Colors.blue),
            const SizedBox(width: 8),
            _buildStatChip('✅ Terminés', completed, Colors.green),
            const SizedBox(width: 8),
            _buildStatChip('⏳ En cours', pending, Colors.orange),
            const SizedBox(width: 8),
            _buildStatChip('❌ Échoués', failed, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SEARCH AND FILTER (CORRIGÉ) ====================
  Widget _buildSearchAndFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded( // ✅ Expanded au lieu de Flexible
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    ),
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un rapport...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                      prefixIcon: Icon(
                        Iconsax.search_normal,
                        size: 20,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: isDark ? Colors.grey[500] : Colors.grey[500],
                              ),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    _isFilterExpanded ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
                    color: isDark ? Colors.white : Colors.grey[700],
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
                  tooltip: 'Filtres',
                ),
              ),
            ],
          ),
          if (_isFilterExpanded) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true, // ✅ Important
                        value: _filterStatus,
                        icon: Icon(
                          Iconsax.status,
                          size: 18,
                          color: isDark ? Colors.white : Colors.grey[700],
                        ),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[800],
                          fontSize: 13,
                        ),
                        onChanged: (value) {
                          setState(() => _filterStatus = value!);
                        },
                        items: ['Tous', 'completed', 'pending', 'failed']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status == 'Tous' ? 'Tous' : status),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true, // ✅ Important
                        value: _selectedYear,
                        icon: Icon(
                          Iconsax.calendar,
                          size: 18,
                          color: isDark ? Colors.white : Colors.grey[700],
                        ),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.grey[800],
                          fontSize: 13,
                        ),
                        onChanged: (value) {
                          setState(() => _selectedYear = value!);
                        },
                        items: [
                          const DropdownMenuItem(
                            value: 0,
                            child: Text('Toutes les années'),
                          ),
                          ..._availableYears.map((year) => DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ==================== LIST VIEW ====================
  Widget _buildListView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredReports.length,
        itemBuilder: (context, index) {
          final report = _filteredReports[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildReportCard(report),
          );
        },
      ),
    );
  }

  // ==================== GRID VIEW ====================
  Widget _buildGridView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600 ? 2 : 3;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.85,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _filteredReports.length,
        itemBuilder: (context, index) {
          final report = _filteredReports[index];
          return _buildReportCard(report, isGrid: true);
        },
      ),
    );
  }

  // ==================== REPORT CARD ====================
  Widget _buildReportCard(Report report, {bool isGrid = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: InkWell(
        onTap: () => _viewReport(report),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: isGrid ? const EdgeInsets.all(10) : const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          report.status == 'completed'
                              ? Colors.green.shade700
                              : report.status == 'pending'
                                  ? Colors.orange.shade700
                                  : Colors.red.shade700,
                          report.status == 'completed'
                              ? Colors.green.shade400
                              : report.status == 'pending'
                                  ? Colors.orange.shade400
                                  : Colors.red.shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      report.status == 'completed'
                          ? Iconsax.document
                          : report.status == 'pending'
                              ? Iconsax.clock
                              : Iconsax.close_circle,
                      color: Colors.white,
                      size: isGrid ? 16 : 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          report.title,
                          style: TextStyle(
                            fontSize: isGrid ? 12 : 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isGrid) ...[
                          Text(
                            report.typeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isGrid) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: report.status == 'completed'
                            ? Colors.green.withOpacity(0.1)
                            : report.status == 'pending'
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        report.statusLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: report.status == 'completed'
                              ? Colors.green.shade700
                              : report.status == 'pending'
                                  ? Colors.orange.shade700
                                  : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              if (isGrid) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: report.status == 'completed'
                        ? Colors.green.withOpacity(0.1)
                        : report.status == 'pending'
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.statusLabel,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: report.status == 'completed'
                          ? Colors.green.shade700
                          : report.status == 'pending'
                              ? Colors.orange.shade700
                              : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 6),
              
              Row(
                children: [
                  Icon(
                    Iconsax.calendar_1,
                    size: isGrid ? 10 : 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${DateFormat('dd/MM/yy').format(report.dateStart)} → ${DateFormat('dd/MM/yy').format(report.dateEnd)}',
                      style: TextStyle(
                        fontSize: isGrid ? 9 : 12,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              if (!isGrid) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Iconsax.calendar,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Créé le ${DateFormat('dd MMM yyyy').format(report.createdAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _generatePDF(report),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.export_1,
                          size: isGrid ? 14 : 16,
                          color: Colors.blue.shade700,
                        ),
                        if (!isGrid) ...[
                          const SizedBox(width: 4),
                          Text(
                            'Partager',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Iconsax.trash,
                      size: isGrid ? 16 : 18,
                      color: Colors.red.shade400,
                    ),
                    onPressed: () => _deleteReport(report),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: isGrid ? 16 : 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== LOADING SCREEN ====================
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
                colors: [Color(0xFF6C63FF), Color(0xFF8B83FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.3),
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
              'Chargement des rapports...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== EMPTY SCREEN ====================
  Widget _buildEmptyScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade50,
                    Colors.blue.shade100.withOpacity(0.3),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.document_text,
                size: 72,
                color: Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun rapport',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Générez votre premier rapport pour\nsuivre votre santé',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade700,
                        Colors.blue.shade500,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3 + _pulseController.value * 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _showGenerateDialog(),
                    icon: const Icon(Iconsax.add, color: Colors.white),
                    label: const Text(
                      'Générer un rapport',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ERROR SCREEN ====================
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
              'Une erreur est survenue',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _loadReports,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
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
                    backgroundColor: Colors.blue.shade700,
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

  // ==================== FAB ====================
  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: FloatingActionButton.extended(
            onPressed: () => _showGenerateDialog(),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Générer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.blue.shade700,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  // ==================== GÉNÉRER DIALOG ====================
  void _showGenerateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          int selectedType = 0;

          return Container(
            height: MediaQuery.of(context).size.height * 0.65,
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '📄 Générer un rapport',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choisissez la période :',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._reportTypes.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final type = entry.value;
                          return RadioListTile<int>(
                            value: idx,
                            groupValue: selectedType,
                            onChanged: (value) => setState(() => selectedType = value!),
                            title: Text(type['label']),
                            secondary: type['days'] > 0
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${type['days']} jours',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  )
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            selectedTileColor: Colors.blue.withOpacity(0.05),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF8B83FF)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _generateReport(_reportTypes[selectedType]['value']);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Générer le rapport',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
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
        },
      ),
    );
  }

  // ==================== VIEW REPORT ====================
  void _viewReport(Report report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.document, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                report.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('Type', report.typeLabel, Iconsax.category),
            const SizedBox(height: 8),
            _buildDetailItem(
              'Période',
              '${DateFormat('dd/MM/yyyy').format(report.dateStart)} - ${DateFormat('dd/MM/yyyy').format(report.dateEnd)}',
              Iconsax.calendar,
            ),
            const SizedBox(height: 8),
            _buildDetailItem('Statut', report.statusLabel, Iconsax.status),
            const SizedBox(height: 8),
            _buildDetailItem(
              'Créé le',
              DateFormat('dd MMMM yyyy à HH:mm').format(report.createdAt),
              Iconsax.clock,
            ),
            if (report.data != null && report.data!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildDetailItem(
                'Données',
                '${report.data!.length} éléments',
                Iconsax.data,
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.info_circle,
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Ce rapport contient des informations médicales confidentielles',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _generatePDF(report);
            },
            icon: const Icon(Iconsax.export_1),
            label: const Text('Partager'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ==================== DELETE REPORT ====================
  Future<void> _deleteReport(Report report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Supprimer le rapport'),
        content: Text(
          'Voulez-vous vraiment supprimer "${report.title}" ?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
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
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
        final reportService = ReportService();
        await reportService.deleteReport(report.id);
        await _loadReports();
        _showSnackbar('✅ Rapport supprimé', Colors.green);
      } catch (e) {
        _showSnackbar('❌ Erreur: $e', Colors.red);
      }
    }
  }

  // ==================== SNACKBAR ====================
    // ==================== SNACKBAR ====================
  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Flexible(flex: 1, child: Text(message)),
          ],
        ),
        backgroundColor: color,
        // ❌ SUPPRIME OU COMMENTE CES 4 LIGNES :
        // behavior: SnackBarBehavior.floating,
        // margin: const EdgeInsets.all(16),
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // ✅ AJOUTE CECI POUR QU'IL S'AFFICHE EN BAS :
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}