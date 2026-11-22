// lib/screens/medicaments_screen.dart
// Version 1.2.0 — Corrigé sans overflow (RenderFlex 7.7px)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

// ==================== MODÈLE MÉDICAMENT ====================
class Medication {
  final int id;
  final String nom;
  final String? dosage;
  final String? frequence;
  final DateTime? prochainePrise;
  final String? notes;
  final String statut;
  final String? type;
  final int? quantite;
  final String? laboratoire;
  final double? prix;
  final String? codeBarre;
  final DateTime? dateAjout;
  final DateTime? dateExpiration;

  Medication({
    required this.id,
    required this.nom,
    this.dosage,
    this.frequence,
    this.prochainePrise,
    this.notes,
    this.statut = 'actif',
    this.type,
    this.quantite,
    this.laboratoire,
    this.prix,
    this.codeBarre,
    this.dateAjout,
    this.dateExpiration,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? 'Inconnu',
      dosage: json['dosage'],
      frequence: json['frequence'],
      prochainePrise: json['prochaine_prise'] != null
          ? DateTime.parse(json['prochaine_prise'])
          : null,
      notes: json['notes'],
      statut: json['statut'] ?? 'actif',
      type: json['type'],
      quantite: json['quantite'],
      laboratoire: json['laboratoire'],
      prix: json['prix'] != null
          ? double.tryParse(json['prix'].toString())
          : null,
      codeBarre: json['code_barre'],
      dateAjout: json['date_ajout'] != null
          ? DateTime.parse(json['date_ajout'])
          : null,
      dateExpiration: json['date_expiration'] != null
          ? DateTime.parse(json['date_expiration'])
          : null,
    );
  }
}

// ==================== SCREEN PRINCIPAL ====================
class MedicamentsScreen extends StatefulWidget {
  const MedicamentsScreen({super.key});

  @override
  State<MedicamentsScreen> createState() => _MedicamentsScreenState();
}

class _MedicamentsScreenState extends State<MedicamentsScreen>
    with SingleTickerProviderStateMixin {
  List<Medication> _medications = [];
  List<Medication> _filteredMedications = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String _filterStatus = 'Tous';
  bool _isGridView = false;
  int _selectedTab = 0;

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _frequenceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _laboratoireController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  final TextEditingController _codeBarreController = TextEditingController();
  DateTime? _selectedDate;
  DateTime? _selectedExpirationDate;
  TimeOfDay? _selectedTime;
  String _selectedType = 'Comprimé';
  String _selectedUnite = 'mg';
  int _quantite = 1;
  bool _isSaving = false;
  bool _isEditing = false;
  int? _editingId;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _totalMedications = 0;
  int _activeMedications = 0;
  int _inactiveMedications = 0;
  int _expiringThisWeek = 0;

  late Color _primaryColor;
  late Color _secondaryColor;
  late Color _surfaceColor;
  late Color _backgroundColor;
  late Color _textColor;
  late Color _textSecondaryColor;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadMedications();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  void _updateThemeColors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _primaryColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    _secondaryColor = isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight;
    _surfaceColor = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    _backgroundColor =
        isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight;
    _textColor = isDark ? AppTheme.textDark : AppTheme.textLight;
    _textSecondaryColor =
        isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
  }

  Future<void> _loadMedications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getUserData();
      final userId = userData?['id'] ?? 1;

      final api = ApiService();
      final response = await api.get('/medicaments?user_id=$userId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['data'] ?? [];

        setState(() {
          _medications =
              items.map((item) => Medication.fromJson(item)).toList();
          _updateStats();
          _applyFilters();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur de chargement des données';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur de connexion au serveur';
      });
    }
  }

  void _updateStats() {
    _totalMedications = _medications.length;
    _activeMedications = _medications.where((m) => m.statut == 'actif').length;
    _inactiveMedications =
        _medications.where((m) => m.statut == 'inactif').length;
    _expiringThisWeek = _medications.where((m) {
      if (m.prochainePrise == null) return false;
      final now = DateTime.now();
      final diff = m.prochainePrise!.difference(now).inDays;
      return diff >= 0 && diff <= 7;
    }).length;
  }

  void _applyFilters() {
    setState(() {
      _filteredMedications = _medications.where((med) {
        final matchesSearch = _searchQuery.isEmpty ||
            med.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (med.dosage?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                false) ||
            (med.frequence
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false);

        bool matchesStatus = true;
        switch (_filterStatus) {
          case 'Actif':
            matchesStatus = med.statut == 'actif';
            break;
          case 'Inactif':
            matchesStatus = med.statut == 'inactif';
            break;
          case 'Expiré':
            matchesStatus = med.statut == 'expire';
            break;
          default:
            matchesStatus = true;
        }

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _saveMedication() async {
    if (_nomController.text.isEmpty) {
      _showSnackbar(
          'Veuillez entrer le nom du médicament', Colors.red.shade700);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getUserData();
      final userId = userData?['id'] ?? 1;

      DateTime? prochainePrise;
      if (_selectedDate != null && _selectedTime != null) {
        prochainePrise = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      }

      final data = {
        'user_id': userId,
        'nom': _nomController.text.trim(),
        'dosage': '${_dosageController.text.trim()} $_selectedUnite',
        'frequence': _frequenceController.text.trim(),
        'prochaine_prise': prochainePrise?.toIso8601String(),
        'notes': _notesController.text.trim(),
        'statut': 'actif',
        'type': _selectedType,
        'quantite': _quantite,
        'laboratoire': _laboratoireController.text.trim(),
        'prix': _prixController.text.trim(),
        'code_barre': _codeBarreController.text.trim(),
        'date_expiration': _selectedExpirationDate?.toIso8601String(),
      };

      final api = ApiService();
      final response = _isEditing
          ? await api.put('/medicaments/$_editingId', data)
          : await api.post('/medicaments', data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _clearForm();
        _loadMedications();
        if (context.mounted) {
          Navigator.pop(context);
          _showSnackbar(
            _isEditing
                ? '✅ Médicament modifié avec succès'
                : '✅ Médicament ajouté avec succès',
            AppTheme.success,
          );
        }
      } else {
        throw Exception('Erreur lors de l\'enregistrement');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackbar(
          _isEditing
              ? '❌ Erreur lors de la modification: ${e.toString()}'
              : '❌ Erreur lors de l\'ajout: ${e.toString()}',
          AppTheme.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _clearForm() {
    _nomController.clear();
    _dosageController.clear();
    _frequenceController.clear();
    _notesController.clear();
    _laboratoireController.clear();
    _prixController.clear();
    _codeBarreController.clear();
    _selectedDate = null;
    _selectedTime = null;
    _selectedExpirationDate = null;
    _selectedType = 'Comprimé';
    _selectedUnite = 'mg';
    _quantite = 1;
    _isEditing = false;
    _editingId = null;
  }

  void _editMedication(Medication medication) {
    _isEditing = true;
    _editingId = medication.id;
    _nomController.text = medication.nom;
    _dosageController.text =
        medication.dosage?.replaceAll(RegExp(r' \w+$'), '') ?? '';
    _frequenceController.text = medication.frequence ?? '';
    _notesController.text = medication.notes ?? '';
    _selectedDate = medication.prochainePrise;
    _selectedTime = medication.prochainePrise != null
        ? TimeOfDay(
            hour: medication.prochainePrise!.hour,
            minute: medication.prochainePrise!.minute,
          )
        : null;
    _selectedExpirationDate = medication.dateExpiration;
    _selectedType = medication.type ?? 'Comprimé';
    _quantite = medication.quantite ?? 1;
    _laboratoireController.text = medication.laboratoire ?? '';
    _prixController.text = medication.prix?.toString() ?? '';
    _codeBarreController.text = medication.codeBarre ?? '';
    _showAddMedicationDialog();
  }

  void _deleteMedication(Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Supprimer le médicament',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer "${medication.nom}" ?',
          style: GoogleFonts.inter(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(color: AppTheme.textSecondaryLight),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final api = ApiService();
                final response =
                    await api.delete('/medicaments/${medication.id}');
                if (response.statusCode == 200) {
                  _loadMedications();
                  _showSnackbar(
                      '🗑️ Médicament supprimé avec succès', AppTheme.warning);
                } else {
                  _showSnackbar('❌ Erreur lors de la suppression',
                      AppTheme.error);
                }
              } catch (e) {
                _showSnackbar('❌ Erreur: ${e.toString()}', AppTheme.error);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              'Supprimer',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _dosageController.dispose();
    _frequenceController.dispose();
    _notesController.dispose();
    _laboratoireController.dispose();
    _prixController.dispose();
    _codeBarreController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _updateThemeColors(context);
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildStatsBar(),
            _buildSearchAndFilter(),
            Flexible(
              flex: 1,
              child: _isLoading
                  ? _buildLoadingScreen()
                  : _errorMessage != null
                      ? _buildErrorScreen()
                      : _filteredMedications.isEmpty
                          ? _buildEmptyScreen()
                          : _isGridView
                              ? _buildGridView()
                              : _buildListView(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // ==================== APP BAR (CORRIGÉE) ====================
  Widget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppTheme.primaryDark, AppTheme.primaryDark.withOpacity(0.8)]
              : [
                  AppTheme.primaryLight,
                  AppTheme.primaryLight.withOpacity(0.9)
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLight.withOpacity(0.3),
            blurRadius: 15,
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
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 20),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/dashboard'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            // ✅ Expanded pour éviter l'overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mes Médicaments',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  '$_totalMedications médicaments',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(
                _isGridView
                    ? Icons.list_rounded
                    : Icons.grid_view_rounded,
                color: Colors.white,
                size: 20,
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints.tightFor(width: 38, height: 38),
              onPressed: () => setState(() => _isGridView = !_isGridView),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 20),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints.tightFor(width: 38, height: 38),
              onPressed: _loadMedications,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STATS BAR (CORRIGÉE) ====================
  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: _surfaceColor,
      // ✅ SingleChildScrollView horizontal pour éviter l'overflow
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatItem(
              label: 'Actifs',
              value: _activeMedications,
              color: AppTheme.success,
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(width: 8),
            _buildStatItem(
              label: 'Inactifs',
              value: _inactiveMedications,
              color: AppTheme.warning,
              icon: Icons.pause_circle_rounded,
            ),
            const SizedBox(width: 8),
            _buildStatItem(
              label: 'Cette semaine',
              value: _expiringThisWeek,
              color: AppTheme.error,
              icon: Icons.timer_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            '$value',
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color.withOpacity(0.7),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SEARCH & FILTER (CORRIGÉE) ====================
  Widget _buildSearchAndFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: _surfaceColor,
      child: Column(
        children: [
          Row(
            children: [
              // ✅ Expanded au lieu de Flexible
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppTheme.surfaceDark : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade300.withOpacity(0.3),
                    ),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _applyFilters();
                      });
                    },
                    style: GoogleFonts.inter(color: _textColor, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      hintStyle: GoogleFonts.inter(
                        color:
                            isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color:
                            isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // ✅ Dropdown compact
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.blue.shade200.withOpacity(0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterStatus,
                    icon: Icon(
                      Icons.filter_list_rounded,
                      color:
                          isDark ? Colors.grey.shade400 : Colors.blue.shade700,
                      size: 18,
                    ),
                    style: GoogleFonts.inter(
                      color:
                          isDark ? Colors.grey.shade300 : Colors.blue.shade700,
                      fontSize: 12,
                    ),
                    dropdownColor: isDark ? AppTheme.surfaceDark : Colors.white,
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value!;
                        _applyFilters();
                      });
                    },
                    items: ['Tous', 'Actif', 'Inactif', 'Expiré']
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status, style: TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ✅ Filtres : SingleChildScrollView horizontal
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tous', 0),
                _buildFilterChip('Actifs', 1),
                _buildFilterChip('Inactifs', 2),
                _buildFilterChip('Expirés', 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 11.5,
          ),
        ),
        backgroundColor: isSelected
            ? AppTheme.primaryLight
            : (isDark ? AppTheme.surfaceDark : Colors.grey.shade100),
        onPressed: () {
          setState(() {
            _selectedTab = index;
            _filterStatus = ['Tous', 'Actif', 'Inactif', 'Expiré'][index];
            _applyFilters();
          });
        },
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isSelected
              ? BorderSide.none
              : BorderSide(
                  color: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade300.withOpacity(0.3)),
        ),
        elevation: isSelected ? 2 : 0,
      ),
    );
  }

  // ==================== LOADING SCREEN ====================
  Widget _buildLoadingScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryLight),
          const SizedBox(height: 20),
          Text(
            'Chargement de vos médicaments...',
            style: GoogleFonts.inter(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ERROR SCREEN ====================
  Widget _buildErrorScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: _textSecondaryColor,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadMedications,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Réessayer',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== EMPTY SCREEN ====================
  Widget _buildEmptyScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
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
                Icons.medication_rounded,
                size: 64,
                color: AppTheme.primaryLight.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucun médicament',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez à gérer vos traitements\nen ajoutant votre premier médicament',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: _textSecondaryColor,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddMedicationDialog,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'Ajouter un médicament',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== LIST VIEW ====================
  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _loadMedications,
      color: AppTheme.primaryLight,
      backgroundColor: _surfaceColor,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: _filteredMedications.length,
          itemBuilder: (context, index) {
            final medication = _filteredMedications[index];
            return _buildMedicationCard(medication)
                .animate()
                .fadeIn(duration: 300.ms, delay: (index * 50).ms)
                .slideX(
                    begin: 0.2,
                    end: 0,
                    duration: 300.ms,
                    delay: (index * 50).ms);
          },
        ),
      ),
    );
  }

  // ==================== GRID VIEW ====================
  Widget _buildGridView() {
    return RefreshIndicator(
      onRefresh: _loadMedications,
      color: AppTheme.primaryLight,
      backgroundColor: _surfaceColor,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _filteredMedications.length,
        itemBuilder: (context, index) {
          final medication = _filteredMedications[index];
          return _buildMedicationGridCard(medication)
              .animate()
              .fadeIn(duration: 300.ms, delay: (index * 50).ms)
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                duration: 300.ms,
                delay: (index * 50).ms,
              );
        },
      ),
    );
  }

  // ==================== MEDICATION CARD ====================
  Widget _buildMedicationCard(Medication medication) {
    final isActive = medication.statut == 'actif';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isActive
        ? AppTheme.primaryLight
        : (isDark ? Colors.grey.shade600 : Colors.grey.shade600);

    return Card(
      elevation: 4,
      shadowColor: isDark
          ? Colors.black.withOpacity(0.3)
          : AppTheme.primaryLight.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isActive
              ? AppTheme.primaryLight.withOpacity(0.2)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          width: 1,
        ),
      ),
      color: _surfaceColor,
      child: InkWell(
        onTap: () => _showMedicationDetails(medication),
        borderRadius: BorderRadius.circular(20),
        hoverColor: AppTheme.primaryLight.withOpacity(0.05),
        splashColor: AppTheme.primaryLight.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.2),
                          color.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getMedicationIcon(medication.type),
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    // ✅ Expanded pour le bloc central
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.nom,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (medication.dosage != null)
                          Text(
                            medication.dosage!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: _textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.success.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isActive ? 'Actif' : 'Inactif',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? AppTheme.success
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ✅ Wrap au lieu de Row → évite l'overflow des 2 pills
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (medication.prochainePrise != null)
                    _pill(
                      icon: Icons.access_time_rounded,
                      label: DateFormat('dd/MM HH:mm')
                          .format(medication.prochainePrise!),
                      color: AppTheme.warning,
                    ),
                  if (medication.frequence != null)
                    _pill(
                      icon: Icons.repeat_rounded,
                      label: medication.frequence!,
                      color: AppTheme.primaryLight,
                    ),
                ],
              ),
              if (medication.notes != null && medication.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '📝 ${medication.notes}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== GRID CARD ====================
  Widget _buildMedicationGridCard(Medication medication) {
    final isActive = medication.statut == 'actif';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isActive
        ? AppTheme.primaryLight
        : (isDark ? Colors.grey.shade600 : Colors.grey.shade600);

    return Card(
      elevation: 4,
      shadowColor: isDark
          ? Colors.black.withOpacity(0.3)
          : AppTheme.primaryLight.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isActive
              ? AppTheme.primaryLight.withOpacity(0.2)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
          width: 1,
        ),
      ),
      color: _surfaceColor,
      child: InkWell(
        onTap: () => _showMedicationDetails(medication),
        borderRadius: BorderRadius.circular(20),
        hoverColor: AppTheme.primaryLight.withOpacity(0.05),
        splashColor: AppTheme.primaryLight.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.15),
                      color.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getMedicationIcon(medication.type),
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                medication.nom,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              if (medication.dosage != null)
                Text(
                  medication.dosage!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.success.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive
                          ? Icons.check_circle_rounded
                          : Icons.pause_circle_rounded,
                      size: 11,
                      color: isActive
                          ? AppTheme.success
                          : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isActive ? 'Actif' : 'Inactif',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? AppTheme.success
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMedicationIcon(String? type) {
    switch (type) {
      case 'Comprimé':
        return Icons.medication_rounded;
      case 'Gélule':
        return Icons.circle_rounded;
      case 'Injection':
        return Icons.medical_information_rounded;
      case 'Sirop':
        return Icons.science_rounded;
      case 'Crème':
        return Icons.health_and_safety_rounded;
      default:
        return Icons.medication_rounded;
    }
  }

  // ==================== FLOATING ACTION BUTTON ====================
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showAddMedicationDialog,
      backgroundColor: AppTheme.primaryLight,
      elevation: 8,
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
    );
  }

  // ==================== ADD MEDICATION DIALOG ====================
  void _showAddMedicationDialog() {
    if (!_isEditing) {
      _clearForm();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            height: MediaQuery.of(context).size.height * 0.92,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : AppTheme.primaryLight.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _isEditing
                              ? 'Modifier le médicament'
                              : 'Ajouter un médicament',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                          ),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                              width: 40, height: 40),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.primaryLight),
                Flexible(
                  flex: 1,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField(
                                label: 'Type',
                                value: _selectedType,
                                items: const [
                                  'Comprimé',
                                  'Gélule',
                                  'Injection',
                                  'Sirop',
                                  'Crème'
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedType = value!);
                                },
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildNumberField(
                                label: 'Quantité',
                                value: _quantite,
                                onChanged: (value) {
                                  setState(() => _quantite = value);
                                },
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _nomController,
                          label: 'Nom du médicament',
                          icon: Icons.medication_rounded,
                          hint: 'Ex: Doliprane',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: _dosageController,
                                label: 'Dosage',
                                icon: Icons.science_rounded,
                                hint: '1000',
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDropdownField(
                                label: 'Unité',
                                value: _selectedUnite,
                                items: const ['mg', 'g', 'µg', 'ml', 'UI'],
                                onChanged: (value) {
                                  setState(() => _selectedUnite = value!);
                                },
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _frequenceController,
                          label: 'Fréquence',
                          icon: Icons.repeat_rounded,
                          hint: 'Ex: Toutes les 8h, 2x par jour',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDatePicker(
                                  context, setState, isDark),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTimePicker(
                                  context, setState, isDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDateExpirationPicker(context, setState, isDark),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _laboratoireController,
                                label: 'Laboratoire',
                                icon: Icons.business_rounded,
                                hint: 'Nom du labo',
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildTextField(
                                controller: _prixController,
                                label: 'Prix (€)',
                                icon: Icons.euro_rounded,
                                hint: '0.00',
                                isNumeric: true,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _codeBarreController,
                          label: 'Code-barres',
                          icon: Icons.qr_code_scanner_rounded,
                          hint: 'Code du produit',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _notesController,
                          label: 'Notes',
                          icon: Icons.note_rounded,
                          hint: 'Instructions particulières...',
                          maxLines: 3,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            if (_isEditing)
                              Expanded(
                                flex: 1,
                                child: OutlinedButton(
                                  onPressed: () {
                                    _deleteMedication(
                                      Medication(
                                        id: _editingId!,
                                        nom: _nomController.text,
                                      ),
                                    );
                                    Navigator.pop(context);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.error,
                                    side: const BorderSide(
                                        color: AppTheme.error, width: 2),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.delete_outline,
                                          size: 18, color: AppTheme.error),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Suppr.',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: AppTheme.error,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_isEditing) const SizedBox(width: 10),
                            Expanded(
                              flex: _isEditing ? 2 : 1,
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed:
                                      _isSaving ? null : _saveMedication,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppTheme.primaryLight,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 4,
                                    shadowColor: AppTheme.primaryLight
                                        .withOpacity(0.3),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _isEditing
                                                  ? Icons.edit_outlined
                                                  : Icons.add_circle_outline,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _isEditing
                                                  ? 'Modifier'
                                                  : 'Ajouter',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_isEditing)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight
                                    .withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.primaryLight
                                      .withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline,
                                      color: AppTheme.primaryLight,
                                      size: 16),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Vous modifiez : ${_nomController.text}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    bool isNumeric = false,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumeric
          ? TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(
          fontSize: 12.5,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade700,
        ),
        prefixIcon: Icon(icon, color: AppTheme.primaryLight, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color:
                  isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.grey.shade800.withOpacity(0.5)
                : Colors.grey.shade300.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.primaryLight, width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isDark,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      dropdownColor: isDark ? AppTheme.surfaceDark : Colors.white,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        );
      }).toList(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 12.5,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color:
                  isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.grey.shade800.withOpacity(0.5)
                : Colors.grey.shade300.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.primaryLight, width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required int value,
    required Function(int) onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark
              ? Colors.grey.shade800.withOpacity(0.5)
              : Colors.grey.shade300.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.remove_rounded,
                size: 18, color: AppTheme.primaryLight),
            onPressed: () => onChanged(value > 1 ? value - 1 : 1),
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints.tightFor(width: 30, height: 36),
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add_rounded,
                size: 18, color: AppTheme.primaryLight),
            onPressed: () => onChanged(value + 1),
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints.tightFor(width: 30, height: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(
      BuildContext context, StateSetter setState, bool isDark) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 7)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.dark(
                  primary: AppTheme.primaryLight,
                  onPrimary: Colors.white,
                  surface: isDark ? AppTheme.surfaceDark : Colors.white,
                  onSurface: isDark ? Colors.white : Colors.black87,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark
                ? Colors.grey.shade800.withOpacity(0.5)
                : Colors.grey.shade300.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                color: AppTheme.primaryLight, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _selectedDate != null
                    ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                    : 'Date',
                style: GoogleFonts.inter(
                  color: _selectedDate != null
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade600),
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(
      BuildContext context, StateSetter setState, bool isDark) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _selectedTime ?? TimeOfDay.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.dark(
                  primary: AppTheme.primaryLight,
                  onPrimary: Colors.white,
                  surface: isDark ? AppTheme.surfaceDark : Colors.white,
                  onSurface: isDark ? Colors.white : Colors.black87,
                ),
              ),
              child: child!,
            );
          },
        );
        if (time != null) {
          setState(() => _selectedTime = time);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark
                ? Colors.grey.shade800.withOpacity(0.5)
                : Colors.grey.shade300.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded,
                color: AppTheme.primaryLight, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _selectedTime != null
                    ? _selectedTime!.format(context)
                    : 'Heure',
                style: GoogleFonts.inter(
                  color: _selectedTime != null
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade600),
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateExpirationPicker(
      BuildContext context, StateSetter setState, bool isDark) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedExpirationDate ??
              DateTime.now().add(const Duration(days: 30)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 730)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.dark(
                  primary: AppTheme.primaryLight,
                  onPrimary: Colors.white,
                  surface: isDark ? AppTheme.surfaceDark : Colors.white,
                  onSurface: isDark ? Colors.white : Colors.black87,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          setState(() => _selectedExpirationDate = date);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark
                ? Colors.grey.shade800.withOpacity(0.5)
                : Colors.grey.shade300.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                color: AppTheme.primaryLight, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _selectedExpirationDate != null
                    ? 'Exp: ${DateFormat('dd/MM/yyyy').format(_selectedExpirationDate!)}'
                    : 'Expiration (optionnel)',
                style: GoogleFonts.inter(
                  color: _selectedExpirationDate != null
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark
                          ? Colors.grey.shade500
                          : Colors.grey.shade600),
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MEDICATION DETAILS ====================
  void _showMedicationDetails(Medication medication) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : AppTheme.primaryLight.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryLight.withOpacity(0.2),
                          AppTheme.primaryLight.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getMedicationIcon(medication.type),
                      color: AppTheme.primaryLight,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.nom,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (medication.dosage != null)
                          Text(
                            medication.dosage!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: medication.statut == 'actif'
                          ? AppTheme.success.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      medication.statut == 'actif' ? 'Actif' : 'Inactif',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: medication.statut == 'actif'
                            ? AppTheme.success
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildDetailItem(
                icon: Icons.access_time_rounded,
                label: 'Fréquence',
                value: medication.frequence ?? 'Non spécifiée',
                isDark: isDark,
              ),
              _buildDetailItem(
                icon: Icons.calendar_today_rounded,
                label: 'Prochaine prise',
                value: medication.prochainePrise != null
                    ? DateFormat('dd/MM/yyyy à HH:mm')
                        .format(medication.prochainePrise!)
                    : 'Non programmé',
                isDark: isDark,
              ),
              if (medication.dateExpiration != null)
                _buildDetailItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Expiration',
                  value: DateFormat('dd/MM/yyyy')
                      .format(medication.dateExpiration!),
                  isDark: isDark,
                ),
              if (medication.type != null)
                _buildDetailItem(
                  icon: Icons.category_rounded,
                  label: 'Type',
                  value: medication.type!,
                  isDark: isDark,
                ),
              if (medication.quantite != null)
                _buildDetailItem(
                  icon: Icons.numbers_rounded,
                  label: 'Quantité',
                  value: '${medication.quantite}',
                  isDark: isDark,
                ),
              if (medication.laboratoire != null)
                _buildDetailItem(
                  icon: Icons.business_rounded,
                  label: 'Laboratoire',
                  value: medication.laboratoire!,
                  isDark: isDark,
                ),
              if (medication.prix != null)
                _buildDetailItem(
                  icon: Icons.euro_rounded,
                  label: 'Prix',
                  value: '${medication.prix!.toStringAsFixed(2)} €',
                  isDark: isDark,
                ),
              if (medication.codeBarre != null)
                _buildDetailItem(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Code-barres',
                  value: medication.codeBarre!,
                  isDark: isDark,
                ),
              if (medication.notes != null && medication.notes!.isNotEmpty)
                _buildDetailItem(
                  icon: Icons.note_rounded,
                  label: 'Notes',
                  value: medication.notes!,
                  multiline: true,
                  isDark: isDark,
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _editMedication(medication);
                      },
                      icon: Icon(Icons.edit_outlined,
                          color: AppTheme.primaryLight, size: 18),
                      label: Text(
                        'Modifier',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: AppTheme.primaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryLight,
                        side: BorderSide(
                            color: AppTheme.primaryLight, width: 2),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteMedication(medication);
                      },
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.white, size: 18),
                      label: Text(
                        'Supprimer',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor:
                            AppTheme.error.withOpacity(0.3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    bool multiline = false,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 16,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color:
                    isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 12.5,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: multiline ? 5 : 1,
              overflow: multiline
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}