// lib/screens/rendezvous/rendezvous_screen.dart
// Version 3.2.0 — Overflow résolu, créneaux affichés, structure inchangée

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/doctor_list_service.dart';
import '../theme/app_theme.dart';

// ==================== MODÈLE RENDEZ-VOUS ====================
class Appointment {
  final int id;
  final String titre;
  final DateTime dateHeure;
  final String? medecinNom;
  final String? lieu;
  final String? notes;
  final String statut;
  final String? type;
  final String? specialite;
  final String? telephone;
  final String? email;
  final String? adresse;
  final String? rappel;
  final String? priority;

  Appointment({
    required this.id,
    required this.titre,
    required this.dateHeure,
    this.medecinNom,
    this.lieu,
    this.notes,
    this.statut = 'à_venir',
    this.type,
    this.specialite,
    this.telephone,
    this.email,
    this.adresse,
    this.rappel,
    this.priority,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? 'Rendez-vous',
      dateHeure: json['date_heure'] != null
          ? DateTime.parse(json['date_heure'])
          : DateTime.now(),
      medecinNom: json['medecin_nom'],
      lieu: json['lieu'],
      notes: json['notes'],
      statut: json['statut'] ?? 'à_venir',
      type: json['type'],
      specialite: json['specialite'],
      telephone: json['telephone'],
      email: json['email'],
      adresse: json['adresse'],
      rappel: json['rappel'],
      priority: json['priority'],
    );
  }
}

// ==================== SCREEN PRINCIPAL ====================
class RendezvousScreen extends StatefulWidget {
  const RendezvousScreen({super.key});

  @override
  State<RendezvousScreen> createState() => _RendezvousScreenState();
}

class _RendezvousScreenState extends State<RendezvousScreen>
    with SingleTickerProviderStateMixin {
  // État
  List<Appointment> _appointments = [];
  List<Appointment> _filteredAppointments = [];
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;
  bool _isLoadingDoctors = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _filterStatus = 'Tous';
  bool _isGridView = false;
  int _selectedTab = 0;

  // Form
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSaving = false;
  bool _isEditing = false;
  int? _editingId;
  String _selectedRappel = '15 min avant';
  String _selectedType = 'Consultation';
  String _selectedPriority = 'Normale';

  Map<String, dynamic>? _selectedDoctor;
  List<Map<String, dynamic>> _availableSlots = [];
  bool _isLoadingSlots = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _totalAppointments = 0;
  int _upcomingAppointments = 0;
  int _pastAppointments = 0;
  int _canceledAppointments = 0;

  late Color _surfaceColor;
  late Color _backgroundColor;
  late Color _textColor;
  late Color _textSecondaryColor;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadAppointments();
    _loadDoctors();
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
    _surfaceColor = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    _backgroundColor = isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight;
    _textColor = isDark ? AppTheme.textDark : AppTheme.textLight;
    _textSecondaryColor =
        isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoadingDoctors = true);
    try {
      final doctors = await DoctorListService().getDoctors();
      if (mounted) {
        setState(() {
          _doctors = doctors;
          _isLoadingDoctors = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDoctors = false);
        _showSnackbar('❌ Erreur chargement médecins: $e', AppTheme.error);
      }
    }
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getUserData();
      final userId = userData?['id'] ?? 1;

      final api = ApiService();
      final response = await api.get('/rendezvous?user_id=$userId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['data'] ?? [];
        setState(() {
          _appointments = items.map((i) => Appointment.fromJson(i)).toList();
          _updateStats();
          _applyFilters();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur de chargement';
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
    _totalAppointments = _appointments.length;
    _upcomingAppointments =
        _appointments.where((a) => a.statut == 'à_venir').length;
    _pastAppointments =
        _appointments.where((a) => a.statut == 'passé').length;
    _canceledAppointments =
        _appointments.where((a) => a.statut == 'annulé').length;
  }

  void _applyFilters() {
    setState(() {
      _filteredAppointments = _appointments.where((app) {
        final matchesSearch = _searchQuery.isEmpty ||
            app.titre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (app.medecinNom
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false) ||
            (app.lieu?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                false);

        bool matchesStatus = true;
        switch (_filterStatus) {
          case 'À venir':
            matchesStatus = app.statut == 'à_venir';
            break;
          case 'Passés':
            matchesStatus = app.statut == 'passé';
            break;
          case 'Annulés':
            matchesStatus = app.statut == 'annulé';
            break;
        }
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppTheme.success
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ✅ CORRECTION : accepte un StateSetter optionnel pour synchroniser le modal
  Future<void> _loadSlots({StateSetter? modalSetState}) async {
    if (_selectedDoctor == null || _selectedDate == null) return;

    void update(VoidCallback fn) {
      if (mounted) setState(fn);
      modalSetState?.call(fn);
    }

    update(() {
      _isLoadingSlots = true;
      _availableSlots = [];
      _selectedTime = null;
    });

    try {
      final doctorId = _selectedDoctor!['id'];
      final date = _selectedDate!;

      // 🔍 LOGS DE DEBUG
      debugPrint('════════════════════════════════════');
      debugPrint('🔍 _loadSlots appelé');
      debugPrint('🔍 doctorId: $doctorId (type: ${doctorId.runtimeType})');
      debugPrint('🔍 date: $date');
      debugPrint(
          '🔍 date formatée: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');

      final data = await DoctorListService().getAvailability(
        doctorId is int ? doctorId : int.parse(doctorId.toString()),
        date,
      );

      debugPrint('🔍 Réponse reçue: $data');
      debugPrint('🔍 data["slots"]: ${data['slots']}');
      debugPrint('🔍 data["available"]: ${data['available']}');
      debugPrint('🔍 data["reason"]: ${data['reason']}');
      debugPrint('════════════════════════════════════');

      if (mounted) {
        update(() {
          _availableSlots =
              List<Map<String, dynamic>>.from(data['slots'] ?? []);
          _isLoadingSlots = false;
        });
        debugPrint('🔍 slots stockés: ${_availableSlots.length}');
      }
    } catch (e, st) {
      debugPrint('🔍 ERREUR loadSlots: $e');
      debugPrint('🔍 STACK: $st');
      if (mounted) {
        update(() => _isLoadingSlots = false);
        _showSnackbar('⚠️ Erreur créneaux: $e', AppTheme.error);
      }
    }
  }

  Future<void> _saveAppointment() async {
    if (_titreController.text.isEmpty) {
      _showSnackbar('Veuillez entrer le titre du rendez-vous', AppTheme.error);
      return;
    }
    if (_selectedDoctor == null) {
      _showSnackbar('Veuillez sélectionner un médecin', AppTheme.error);
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      _showSnackbar('Veuillez sélectionner la date et l\'heure', AppTheme.error);
      return;
    }

    final timeStr =
        '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
    final slot = _availableSlots
        .firstWhere((s) => s['time'] == timeStr, orElse: () => {});
    if (slot.isEmpty) {
      _showSnackbar('Créneau invalide, choisissez un horaire proposé',
          AppTheme.warning);
      return;
    }
    if (slot['available'] != true) {
      _showSnackbar('Ce créneau est déjà pris, choisissez-en un autre',
          AppTheme.warning);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getUserData();
      final userId = userData?['id'] ?? 1;

      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final data = {
        'user_id': userId,
        'titre': _titreController.text.trim(),
        'medecin_id': _selectedDoctor!['id'],
        'medecin_nom':
            '${_selectedDoctor!['prenom']} ${_selectedDoctor!['nom']}',
        'specialite': _selectedDoctor!['specialite'],
        'telephone': _selectedDoctor!['cabinet_phone'],
        'adresse': _selectedDoctor!['cabinet_address'],
        'lieu': _selectedDoctor!['cabinet_address'],
        'date_heure': dateTime.toIso8601String(),
        'statut': 'à_venir',
        'type': _selectedType,
        'rappel': _selectedRappel,
        'priority': _selectedPriority,
      };

      if (_notesController.text.trim().isNotEmpty) {
        data['notes'] = _notesController.text.trim();
      }

      final api = ApiService();
      final response = _isEditing
          ? await api.put('/rendezvous/$_editingId', data)
          : await api.post('/rendezvous', data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _clearForm();
        _loadAppointments();
        if (mounted) {
          Navigator.pop(context);
          _showSnackbar(
            _isEditing ? '✅ Rendez-vous modifié' : '✅ Rendez-vous ajouté',
            AppTheme.success,
          );
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error'] ?? 'Erreur ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar(
            '❌ ${e.toString().replaceAll('Exception: ', '')}',
            AppTheme.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _clearForm() {
    _titreController.clear();
    _notesController.clear();
    _selectedDate = null;
    _selectedTime = null;
    _selectedDoctor = null;
    _availableSlots = [];
    _selectedType = 'Consultation';
    _selectedRappel = '15 min avant';
    _selectedPriority = 'Normale';
    _isEditing = false;
    _editingId = null;
  }

  void _editAppointment(Appointment appointment) {
    _isEditing = true;
    _editingId = appointment.id;
    _titreController.text = appointment.titre;
    _notesController.text = appointment.notes ?? '';
    _selectedDate = appointment.dateHeure;
    _selectedTime = TimeOfDay(
        hour: appointment.dateHeure.hour, minute: appointment.dateHeure.minute);

    final validTypes = ['Consultation', 'Examen', 'Urgence', 'Suivi', 'Chirurgie'];
    _selectedType = appointment.type ?? 'Consultation';
    if (!validTypes.contains(_selectedType)) _selectedType = 'Consultation';

    final validRappels = [
      '15 min avant',
      '30 min avant',
      '1h avant',
      '2h avant',
      '1 jour avant'
    ];
    _selectedRappel = appointment.rappel ?? '15 min avant';
    if (!validRappels.contains(_selectedRappel)) _selectedRappel = '15 min avant';

    _selectedPriority = appointment.priority ?? 'Normale';

    try {
      _selectedDoctor = _doctors.firstWhere(
        (d) => '${d['prenom']} ${d['nom']}' == appointment.medecinNom,
      );
    } catch (e) {
      _selectedDoctor = null;
    }

    _showAddAppointmentDialog();
  }

  void _deleteAppointment(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Annuler le rendez-vous',
            style:
                GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text('Voulez-vous vraiment annuler "${appointment.titre}" ?',
            style: GoogleFonts.inter(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Non',
                style:
                    GoogleFonts.inter(color: AppTheme.textSecondaryLight)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final api = ApiService();
                await api.delete('/rendezvous/${appointment.id}');
                _loadAppointments();
                _showSnackbar('🗑️ Rendez-vous annulé', AppTheme.warning);
              } catch (e) {
                _showSnackbar('❌ Erreur: ${e.toString()}', AppTheme.error);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text('Oui',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titreController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
Widget build(BuildContext context) {
  _updateThemeColors(context);
  debugPrint('🔍 BUILD RendezvousScreen — '
      'loading=$_isLoading, '
      'appointments=${_filteredAppointments.length}, '
      'grid=$_isGridView, '
      'screenHeight=${MediaQuery.of(context).size.height}');
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
                    : _filteredAppointments.isEmpty
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

  Widget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/dashboard'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mes Rendez-vous',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('$_totalAppointments rendez-vous',
                    style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.85), fontSize: 13)),
              ],
            ),
          ),
          Row(
            children: [
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
                      size: 22),
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
                      color: Colors.white, size: 22),
                  onPressed: () {
                    _loadAppointments();
                    _loadDoctors();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ CORRECTION : SingleChildScrollView horizontal + chips plus compacts
  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: _surfaceColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatItem(
                label: 'À venir',
                value: _upcomingAppointments,
                color: AppTheme.success,
                icon: Icons.calendar_today_rounded),
            const SizedBox(width: 8),
            _buildStatItem(
                label: 'Passés',
                value: _pastAppointments,
                color: AppTheme.info,
                icon: Icons.history_rounded),
            const SizedBox(width: 8),
            _buildStatItem(
                label: 'Annulés',
                value: _canceledAppointments,
                color: AppTheme.error,
                icon: Icons.cancel_rounded),
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
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text('$value',
              style: GoogleFonts.inter(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  height: 1.0)),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  color: color.withOpacity(0.7),
                  fontSize: 11,
                  height: 1.0)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: _surfaceColor,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppTheme.surfaceDark : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    }),
                    style: GoogleFonts.inter(color: _textColor),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un rendez-vous...',
                      hintStyle: GoogleFonts.inter(
                          color: Colors.grey.shade500, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, size: 22),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tous', 0),
                _buildFilterChip('À venir', 1),
                _buildFilterChip('Passés', 2),
                _buildFilterChip('Annulés', 3),
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
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label,
            style: GoogleFonts.inter(
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            )),
        backgroundColor: isSelected
            ? AppTheme.primaryLight
            : (isDark ? AppTheme.surfaceDark : Colors.grey.shade100),
        onPressed: () {
          setState(() {
            _selectedTab = index;
            _filterStatus = ['Tous', 'À venir', 'Passés', 'Annulés'][index];
            _applyFilters();
          });
        },
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isSelected
              ? BorderSide.none
              : BorderSide(
                  color:
                      isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryLight));
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: AppTheme.error),
          const SizedBox(height: 16),
          Text('Une erreur est survenue',
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textColor)),
          const SizedBox(height: 8),
          Text(_errorMessage ?? '',
              style: GoogleFonts.inter(color: _textSecondaryColor)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAppointments,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_rounded,
                size: 72,
                color: AppTheme.primaryLight.withOpacity(0.6)),
            const SizedBox(height: 20),
            Text('Aucun rendez-vous',
                style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _textColor)),
            const SizedBox(height: 8),
            Text('Ajoutez votre premier rendez-vous',
                style: GoogleFonts.inter(color: _textSecondaryColor)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddAppointmentDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: AppTheme.primaryLight,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _filteredAppointments.length,
          itemBuilder: (context, index) =>
              _buildAppointmentCard(_filteredAppointments[index]),
        ),
      ),
    );
  }

  Widget _buildGridView() {
  return GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.65,   // ← 0.85 → 0.65 (cards ~30% plus hautes)
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    ),
    itemCount: _filteredAppointments.length,
    itemBuilder: (context, index) =>
        _buildAppointmentCard(_filteredAppointments[index]),
  );
}
Widget _buildCompactAppointmentCard(Appointment appointment) {
  final color = appointment.statut == 'à_venir'
      ? AppTheme.primaryLight
      : Colors.grey.shade600;

  return Card(
    margin: EdgeInsets.zero,
    elevation: 3,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    color: _surfaceColor,
    child: InkWell(
      onTap: () => _showAppointmentDetails(appointment),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_getAppointmentIcon(appointment.type),
                      color: color, size: 18),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.statut).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_getStatusLabel(appointment.statut),
                      style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(appointment.statut))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              appointment.titre,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _textColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (appointment.medecinNom != null) ...[
              const SizedBox(height: 4),
              Text(
                appointment.medecinNom!,
                style: GoogleFonts.inter(
                    fontSize: 10, color: _textSecondaryColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Spacer(),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 11, color: AppTheme.warning),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    DateFormat('dd/MM').format(appointment.dateHeure),
                    style: GoogleFonts.inter(
                        fontSize: 10, color: AppTheme.warning),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.access_time_rounded,
                    size: 11, color: AppTheme.primaryLight),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    DateFormat('HH:mm').format(appointment.dateHeure),
                    style: GoogleFonts.inter(
                        fontSize: 10, color: AppTheme.primaryLight),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
    Widget _buildAppointmentCard(Appointment appointment) {
    if (_isGridView) {
      return _buildCompactAppointmentCard(appointment);
    }

    final color = appointment.statut == 'à_venir'
        ? AppTheme.primaryLight
        : Colors.grey.shade600;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: _surfaceColor,
      child: InkWell(
        onTap: () => _showAppointmentDetails(appointment),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_getAppointmentIcon(appointment.type),
                          color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appointment.titre,
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _textColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          if (appointment.medecinNom != null)
                            Text('👨‍⚕️ ${appointment.medecinNom}',
                                style: GoogleFonts.inter(
                                    fontSize: 13, color: _textSecondaryColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(appointment.statut)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_getStatusLabel(appointment.statut),
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(appointment.statut))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 14, color: AppTheme.warning),
                    const SizedBox(width: 4),
                    Text(
                        DateFormat('dd/MM/yyyy')
                            .format(appointment.dateHeure),
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppTheme.warning)),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: AppTheme.primaryLight),
                    const SizedBox(width: 4),
                    Text(DateFormat('HH:mm').format(appointment.dateHeure),
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppTheme.primaryLight)),
                  ],
                ),
                if (appointment.lieu != null &&
                    appointment.lieu!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 14, color: Colors.purple.shade400),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(appointment.lieu!,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.purple.shade400),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAppointmentIcon(String? type) {
    switch (type) {
      case 'Consultation':
        return Icons.medical_services_rounded;
      case 'Examen':
        return Icons.science_rounded;
      case 'Urgence':
        return Icons.local_hospital_rounded;
      case 'Suivi':
        return Icons.repeat_rounded;
      case 'Chirurgie':
        return Icons.healing_rounded;
      default:
        return Icons.calendar_month_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'à_venir':
        return AppTheme.success;
      case 'passé':
        return AppTheme.info;
      case 'annulé':
        return AppTheme.error;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'à_venir':
        return 'À venir';
      case 'passé':
        return 'Passé';
      case 'annulé':
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showAddAppointmentDialog,
      backgroundColor: AppTheme.primaryLight,
      elevation: 8,
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
    );
  }

  Widget _buildDoctorInfoCard(bool isDark) {
    if (_selectedDoctor == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryLight.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            Icons.workspace_premium_rounded,
            'Spécialité',
            (_selectedDoctor!['specialite']?.toString()) ?? '—',
            isDark,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.phone_rounded,
            'Téléphone',
            (_selectedDoctor!['cabinet_phone']?.toString()) ?? '—',
            isDark,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.location_on_rounded,
            'Adresse',
            (_selectedDoctor!['cabinet_address']?.toString()) ?? '—',
            isDark,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DIALOGUE AJOUT / MODIFICATION
  // ═══════════════════════════════════════════════════════════════
  void _showAddAppointmentDialog() {
    if (!_isEditing) _clearForm();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, modalSetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final keyboardOpen =
              MediaQuery.of(context).viewInsets.bottom > 0;

          return DraggableScrollableSheet(
            // ✅ Ajuste la hauteur quand le clavier est ouvert
            initialChildSize: keyboardOpen ? 0.98 : 0.92,
            minChildSize: 0.5,
            maxChildSize: 0.98,
            expand: false,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.surfaceDark : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  // ✅ Poignée réduite
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            _isEditing
                                ? 'Modifier le rendez-vous'
                                : 'Ajouter un rendez-vous',
                            style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark ? Colors.white : Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(
                          24,
                          20,
                          24,
                          MediaQuery.of(context).viewInsets.bottom + 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('Médecin',
                              Icons.person_search_rounded, isDark),
                          const SizedBox(height: 8),
                          if (_isLoadingDoctors)
                            const Center(
                                child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ))
                          else if (_doctors.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: AppTheme.warning),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(
                                          'Aucun médecin disponible',
                                          style: GoogleFonts.inter(
                                              fontSize: 13))),
                                ],
                              ),
                            )
                          else
                            _buildDoctorDropdown(isDark, modalSetState),

                          const SizedBox(height: 16),

                          if (_selectedDoctor != null) ...[
                            _buildDoctorInfoCard(isDark),
                            const SizedBox(height: 16),
                          ],

                          _buildSectionLabel('Informations',
                              Icons.edit_rounded, isDark),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _titreController,
                            label: 'Titre du rendez-vous',
                            icon: Icons.title_rounded,
                            hint: 'Ex: Consultation cardiologue',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Type',
                                  value: _selectedType,
                                  items: [
                                    'Consultation',
                                    'Examen',
                                    'Urgence',
                                    'Suivi',
                                    'Chirurgie'
                                  ],
                                  onChanged: (v) => modalSetState(
                                      () => _selectedType = v!),
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Priorité',
                                  value: _selectedPriority,
                                  items: [
                                    'Basse',
                                    'Normale',
                                    'Moyenne',
                                    'Haute'
                                  ],
                                  onChanged: (v) => modalSetState(
                                      () => _selectedPriority = v!),
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildSectionLabel('Date',
                              Icons.calendar_today_rounded, isDark),
                          const SizedBox(height: 8),
                          _buildDatePicker(context, modalSetState, isDark),
                          const SizedBox(height: 16),

                          if (_selectedDoctor != null &&
                              _selectedDate != null) ...[
                            _buildSectionLabel('Créneaux disponibles',
                                Icons.schedule_rounded, isDark),
                            const SizedBox(height: 8),
                            _buildSlotsSelector(isDark, modalSetState),
                            const SizedBox(height: 16),
                          ],

                          _buildTextField(
                            controller: _notesController,
                            label: 'Notes',
                            icon: Icons.note_rounded,
                            hint: 'Instructions particulières...',
                            maxLines: 3,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),

                          _buildDropdownField(
                            label: 'Rappel',
                            value: _selectedRappel,
                            items: [
                              '15 min avant',
                              '30 min avant',
                              '1h avant',
                              '2h avant',
                              '1 jour avant'
                            ],
                            onChanged: (v) =>
                                modalSetState(() => _selectedRappel = v!),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // ✅ Footer plus compact (48 au lieu de 52, padding 8 au lieu de 12)
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceDark : Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          if (_isEditing) ...[
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    _deleteAppointment(Appointment(
                                      id: _editingId!,
                                      titre: _titreController.text,
                                      dateHeure: DateTime.now(),
                                    ));
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.delete_outline,
                                      color: AppTheme.error, size: 18),
                                  label: Text('Supprimer',
                                      style: GoogleFonts.inter(
                                          color: AppTheme.error, fontSize: 14)),
                                  style: OutlinedButton.styleFrom(
                                    side:
                                        const BorderSide(color: AppTheme.error),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed:
                                    _isSaving ? null : _saveAppointment,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryLight,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : Text(
                                        _isEditing ? 'Modifier' : 'Ajouter',
                                        style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoctorDropdown(bool isDark, StateSetter modalSetState) {
    return DropdownButtonFormField<Map<String, dynamic>>(
      value: _selectedDoctor,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Choisir un médecin',
        prefixIcon: const Icon(Icons.person_search_rounded,
            color: AppTheme.primaryLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      ),
      dropdownColor: isDark ? AppTheme.surfaceDark : Colors.white,
      items: _doctors.map<DropdownMenuItem<Map<String, dynamic>>>((doc) {
        final fullName = (doc['nom_complet'] as String?) ??
            '${doc['prenom'] ?? ''} ${doc['nom'] ?? ''}'.trim();
        return DropdownMenuItem<Map<String, dynamic>>(
          value: doc,
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryLight),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(fullName,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                    Text((doc['specialite'] as String?) ?? '—',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (doctor) {
        modalSetState(() {
          _selectedDoctor = doctor;
          _selectedTime = null;
          _availableSlots = [];
        });
        if (_selectedDate != null && doctor != null) {
          _loadSlots(modalSetState: modalSetState);
        }
      },
    );
  }

  // ✅ CORRECTION : hauteur max + scroll pour éviter tout overflow
  Widget _buildSlotsSelector(bool isDark, StateSetter modalSetState) {
    if (_isLoadingSlots) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_availableSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppTheme.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Le médecin ne travaille pas ce jour-là.',
                style: GoogleFonts.inter(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    // ✅ Constraint la hauteur + scroll pour éviter l'overflow du modal
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableSlots.map((slot) {
            final isAvailable = slot['available'] == true;
            final time = slot['time'] as String;
            final isSelected = _selectedTime != null &&
                '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}' ==
                    time;

            return GestureDetector(
              onTap: isAvailable
                  ? () {
                      final parts = time.split(':');
                      modalSetState(() {
                        _selectedTime = TimeOfDay(
                          hour: int.parse(parts[0]),
                          minute: int.parse(parts[1]),
                        );
                      });
                    }
                  : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: !isAvailable
                      ? Colors.grey.shade200
                      : isSelected
                          ? AppTheme.primaryLight
                          : (isDark ? AppTheme.surfaceDark : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !isAvailable
                        ? Colors.grey.shade300
                        : isSelected
                            ? AppTheme.primaryLight
                            : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  time,
                  style: GoogleFonts.inter(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    color: !isAvailable
                        ? Colors.grey.shade500
                        : isSelected
                            ? Colors.white
                            : _textColor,
                    decoration:
                        !isAvailable ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryLight),
        const SizedBox(width: 8),
        Text(title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade500 : Colors.grey,
              letterSpacing: 1,
            )),
      ],
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.primaryLight),
        const SizedBox(width: 8),
        SizedBox(
            width: 90,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600))),
        Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87),
                overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    required bool isDark,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inter(
          fontSize: 14, color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryLight, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
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
      isExpanded: true,
      onChanged: onChanged,
      dropdownColor: isDark ? AppTheme.surfaceDark : Colors.white,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87),
                    overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDatePicker(
      BuildContext context, StateSetter modalSetState, bool isDark) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate:
              _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          modalSetState(() {
            _selectedDate = date;
            _selectedTime = null;
            _availableSlots = [];
          });
          if (_selectedDoctor != null) {
            _loadSlots(modalSetState: modalSetState);
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                color: AppTheme.primaryLight, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedDate != null
                    ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                    : 'Sélectionner une date',
                style: GoogleFonts.inter(
                  color: _selectedDate != null
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.grey,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DÉTAILS
  // ═══════════════════════════════════════════════════════════════
  void _showAppointmentDetails(Appointment appointment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                )),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_getAppointmentIcon(appointment.type),
                          color: AppTheme.primaryLight, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appointment.titre,
                              style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _textColor),
                              overflow: TextOverflow.ellipsis),
                          if (appointment.medecinNom != null)
                            Text('👨‍⚕️ ${appointment.medecinNom}',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: _textSecondaryColor),
                                overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDetailItem(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value:
                        DateFormat('dd/MM/yyyy').format(appointment.dateHeure),
                    isDark: isDark),
                _buildDetailItem(
                    icon: Icons.access_time_rounded,
                    label: 'Heure',
                    value: DateFormat('HH:mm').format(appointment.dateHeure),
                    isDark: isDark),
                if (appointment.type != null)
                  _buildDetailItem(
                      icon: Icons.category_rounded,
                      label: 'Type',
                      value: appointment.type!,
                      isDark: isDark),
                if (appointment.specialite != null)
                  _buildDetailItem(
                      icon: Icons.medical_services_rounded,
                      label: 'Spécialité',
                      value: appointment.specialite!,
                      isDark: isDark),
                if (appointment.lieu != null)
                  _buildDetailItem(
                      icon: Icons.location_on_rounded,
                      label: 'Lieu',
                      value: appointment.lieu!,
                      isDark: isDark),
                if (appointment.telephone != null)
                  _buildDetailItem(
                      icon: Icons.phone_rounded,
                      label: 'Téléphone',
                      value: appointment.telephone!,
                      isDark: isDark),
                if (appointment.rappel != null)
                  _buildDetailItem(
                      icon: Icons.notifications_rounded,
                      label: 'Rappel',
                      value: appointment.rappel!,
                      isDark: isDark),
                if (appointment.priority != null &&
                    appointment.priority != 'Normale')
                  _buildDetailItem(
                      icon: Icons.flag_rounded,
                      label: 'Priorité',
                      value: appointment.priority!,
                      isDark: isDark),
                if (appointment.notes != null && appointment.notes!.isNotEmpty)
                  _buildDetailItem(
                      icon: Icons.note_rounded,
                      label: 'Notes',
                      value: appointment.notes!,
                      multiline: true,
                      isDark: isDark),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _editAppointment(appointment);
                        },
                        icon: const Icon(Icons.edit_outlined,
                            color: AppTheme.primaryLight, size: 20),
                        label: Text('Modifier',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppTheme.primaryLight)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppTheme.primaryLight, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteAppointment(appointment);
                        },
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 20),
                        label: Text('Supprimer',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
              size: 18,
              color:
                  isDark ? Colors.grey.shade500 : Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
              width: 100,
              child: Text(label,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                    fontSize: 13,
                  ))),
          Expanded(
              child: Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87),
                  maxLines: multiline ? 5 : 1,
                  overflow: multiline
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}