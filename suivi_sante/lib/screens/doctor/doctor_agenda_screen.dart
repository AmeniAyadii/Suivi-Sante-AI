import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:suivi_sante_pro/screens/doctor/doctor_add_appointment_screen.dart';
import '../../models/doctor_appointment.dart';
import '../../services/doctor_service.dart';

class DoctorAgendaScreen extends StatefulWidget {
  const DoctorAgendaScreen({super.key});

  @override
  State<DoctorAgendaScreen> createState() => _DoctorAgendaScreenState();
}

class _DoctorAgendaScreenState extends State<DoctorAgendaScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  List<DoctorAppointment> _appointments = [];
  String _error = '';
  
  // Horaires d'ouverture
  int _startHour = 8;
  int _endHour = 19;
  final double _hourHeight = 90.0; // Hauteur d'une heure en pixels

  @override
  void initState() {
    super.initState();
    _loadAgenda();
  }

  Future<void> _loadAgenda() async {
  setState(() {
    _isLoading = true;
    _error = '';
  });

  try {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    debugPrint('🔍 Date envoyée à l\'API: $dateStr'); // ✅ LOG

    final data = await DoctorService().getAgenda(dateStr);
    
    debugPrint('🔍 Données reçues: ${data['data']}'); // ✅ LOG

    final list = (data['data'] as List)
        .map((e) => DoctorAppointment.fromJson(e))
        .toList();

    debugPrint('🔍 Nombre de RDV parsés: ${list.length}'); // ✅ LOG

    if (mounted) {
      setState(() {
        _appointments = list;
        _isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
}

  void _changeDay(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadAgenda();
  }

  void _goToToday() {
    setState(() => _selectedDate = DateTime.now());
    _loadAgenda();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final textColor = isDark ? Colors.white : const Color(0xFF2D3436);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Mon Agenda', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
        centerTitle: true,
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (!DateUtils.isSameDay(_selectedDate, DateTime.now()))
            TextButton(
              onPressed: _goToToday,
              child: Text('Aujourd\'hui', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF00B894))),
            ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(isDark, textColor),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00B894)))
                : _error.isNotEmpty
                    ? _buildErrorState(isDark)
                    : _buildTimeline(isDark, textColor),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        //onPressed: () => _showAddAppointmentDialog(null),
        onPressed: () => _showAddAppointmentDialog(null), // ✅ Ouvre le formulaire sans heure pré-définie
        backgroundColor: const Color(0xFF00B894),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Nouveau RDV', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  // ==================== DATE SELECTOR ====================
  Widget _buildDateSelector(bool isDark, Color textColor) {
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () => _changeDay(-1),
            icon: Icon(Icons.arrow_back_ios_rounded, size: 18, color: textColor),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  isToday ? "Aujourd'hui" : DateFormat('EEEE', 'fr_FR').format(_selectedDate).capitalize(),
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
                Text(
                  DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedDate),
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _changeDay(1),
            icon: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: textColor),
          ),
        ],
      ),
    );
  }

  // ==================== TIMELINE ====================
    Widget _buildTimeline(bool isDark, Color textColor) {
    final hours = List.generate(_endHour - _startHour, (i) => _startHour + i);
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(_selectedDate, now);

    // Calcul de la position de la ligne "Maintenant"
    double? currentTimeTop;
    if (isToday && now.hour >= _startHour && now.hour < _endHour) {
      final hourOffset = now.hour - _startHour;
      final minuteOffset = now.minute / 60.0;
      currentTimeTop = (hourOffset + minuteOffset) * _hourHeight;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Stack(
        children: [
          // 1. Colonne de fond avec les lignes d'heures
          Column(
            children: hours.map((hour) => _buildHourRow(hour, isDark, textColor)).toList(),
          ),
          
          // 2. Ligne "Maintenant"
          if (currentTimeTop != null)
            Positioned(
              top: currentTimeTop,
              left: 60,
              right: 10,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD63031),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1.5,
                      color: const Color(0xFFD63031),
                    ),
                  ),
                ],
              ),
            ),

          // 3. Zones cliquables pour ajouter un RDV
          // ✅ CORRECTION : On utilise HitTestBehavior.opaque et on décale légèrement 
          ...hours.map((hour) => Positioned(
            top: (hour - _startHour) * _hourHeight,
            left: 60,
            right: 10,
            height: _hourHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque, // ✅ Opaque au lieu de translucent
              onTap: () {
                final selectedDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, hour);
                _showAddAppointmentDialog(selectedDateTime);
              },
              child: Container(color: Colors.transparent),
            ),
          )),

          // 4. Événements positionnés (placés APRÈS pour passer au-dessus des zones cliquables)
          ..._appointments.map((appt) => _buildAppointmentBlock(appt, isDark)),
        ],
      ),
    );
  }

  Widget _buildHourRow(int hour, bool isDark, Color textColor) {
    final isLunchBreak = hour == 12; // Optionnel : Zone déjeuner

    return Container(
      height: _hourHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heure
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 12),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          // Ligne horizontale + fond déjeuner
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
                ),
                color: isLunchBreak ? (isDark ? Colors.grey[900] : Colors.grey[100]) : Colors.transparent,
              ),
              child: isLunchBreak
                  ? Center(
                      child: Text(
                        'Pause Déjeuner',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildAppointmentBlock(DoctorAppointment appt, bool isDark) {
    final color = _getColor(appt.type);
    
    final hourOffset = appt.dateHeure.hour - _startHour;
    final minuteOffset = appt.dateHeure.minute / 60.0;
    final top = ((hourOffset + minuteOffset) * _hourHeight) + 8;
    
    final height = (appt.duree / 60.0) * _hourHeight;

    return Positioned(
      top: top,
      left: 70,
      right: 16,
      height: height > 40 ? height : 40, // Hauteur minimum
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAppointmentDetails(appt),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // ✅ vertical: 8 → 6
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.25 : 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: color, width: 4)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            // ✅ AJOUTER CE SINGLECHILDSCROLLVIEW POUR ÉVITER L'OVERFLOW
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(), // Empêche l'utilisateur de scroller
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // ✅ Taille minimale
                children: [
                  Row(
                    children: [
                      Icon(_getIcon(appt.type), size: 12, color: color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          appt.titre,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${appt.patientNom} • ${DateFormat('HH:mm').format(appt.dateHeure)}',
                    style: GoogleFonts.inter(fontSize: 11, color: isDark ? Colors.grey[300] : Colors.grey[800]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  // ==================== COULEURS & HELPERS ====================
  Color _getColor(String type) {
    switch (type.toLowerCase()) {
      case 'urgence': return const Color(0xFFD63031);
      case 'examen': return const Color(0xFF0984E3);
      case 'suivi': return const Color(0xFF6C5CE7);
      case 'consultation':
      default: return const Color(0xFF00B894);
    }
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'urgence': return Icons.local_hospital_rounded;
      case 'examen': return Icons.science_rounded;
      case 'suivi': return Icons.repeat_rounded;
      default: return Icons.medical_services_rounded;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadAgenda();
    }
  }

  // ==================== DIALOGS ====================
  void _showAppointmentDetails(DoctorAppointment appt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(3)))),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getColor(appt.type).withOpacity(0.15),
                    child: Icon(Icons.person, color: _getColor(appt.type)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appt.titre, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                        Text(appt.patientNom, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _detailRow(Icons.access_time_rounded, 'Horaire', '${DateFormat('HH:mm').format(appt.dateHeure)} (${appt.duree} min)'),
              _detailRow(Icons.category_rounded, 'Type', appt.type),
              _detailRow(Icons.phone_rounded, 'Téléphone', appt.patientTelephone),
              if (appt.lieu != null) _detailRow(Icons.location_on_rounded, 'Lieu', appt.lieu!),
              if (appt.notes != null && appt.notes!.isNotEmpty) _detailRow(Icons.notes_rounded, 'Notes', appt.notes!),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Text('$label : ', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
          Expanded(child: Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
  

    Future<void> _showAddAppointmentDialog(DateTime? initialDateTime) async {
    // 1. Afficher un loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00B894)),
      ),
    );

    try {
      // 2. Récupérer la liste des patients
      final patientsDynamic = await DoctorService().getPatients();
      final patients = List<Map<String, dynamic>>.from(patientsDynamic);

      if (!mounted) return;
      Navigator.pop(context); // Fermer le loader

      if (patients.isEmpty) {
        _showSnack('Aucun patient disponible pour créer un RDV', isError: true);
        return;
      }

      // 3. Ouvrir le formulaire avec la date pré-remplie
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorAddAppointmentScreen(
            patients: patients,
            initialDate: initialDateTime,
          ),
        ),
      );

      // 4. Si un RDV a été créé, on rafraîchit l'agenda
      if (result == true) {
        _loadAgenda();
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Fermer le loader en cas d'erreur
      _showSnack('Erreur: $e', isError: true);
    }
  }

  // Petite méthode utilitaire pour les messages
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade600 : const Color(0xFF00B894),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text('Erreur: $_error', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadAgenda,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}


extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}