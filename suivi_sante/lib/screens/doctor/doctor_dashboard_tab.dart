import 'package:flutter/material.dart';
import 'package:suivi_sante_pro/screens/doctor/doctor_add_appointment_screen.dart';
import 'package:suivi_sante_pro/screens/doctor/doctor_agenda_screen.dart';
import 'package:suivi_sante_pro/screens/doctor/doctor_history_screen.dart';
import 'package:suivi_sante_pro/screens/doctor/doctor_prescription_form.dart';
import 'package:suivi_sante_pro/services/auth_service.dart';
import '../../services/doctor_service.dart';

class DoctorDashboardTab extends StatefulWidget {
  const DoctorDashboardTab({super.key});

  @override
  State<DoctorDashboardTab> createState() => _DoctorDashboardTabState();
}

class _DoctorDashboardTabState extends State<DoctorDashboardTab>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _future;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ==================== PALETTE DE COULEURS ====================
  static const Color _primaryGreen = Color(0xFF00B894);
  static const Color _primaryBlue = Color(0xFF0984E3);
  static const Color _primaryPurple = Color(0xFF6C5CE7);
  static const Color _primaryOrange = Color(0xFFE17055);
  static const Color _primaryRed = Color(0xFFD63031);
  static const Color _bgColor = Color(0xFFF8F9FC);
  static const Color _textDark = Color(0xFF2D3436);
  static const Color _textGrey = Color(0xFF636E72);

  @override
  void initState() {
    super.initState();
    _future = DoctorService().getDashboard();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _future = DoctorService().getDashboard());
    await _future;
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgColor,
      child: RefreshIndicator(
        onRefresh: _refresh,
        color: _primaryGreen,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: _primaryGreen),
                );
              }
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error);
              }

              final s = snapshot.data ?? {};

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(s),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Vue d\'ensemble', Icons.insights_rounded),
                    const SizedBox(height: 14),
                    _buildStatsGrid(s),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Actions rapides', Icons.flash_on_rounded),
                    const SizedBox(height: 14),
                    _buildShortcuts(),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Aujourd\'hui', Icons.today_rounded),
                    const SizedBox(height: 14),
                    _buildTodaySummary(s),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader(Map<String, dynamic> s) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryGreen, Color(0xFF55EFC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bonjour Docteur 👋',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTodayDate(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildHeaderStat(
                  icon: Icons.event_available_rounded,
                  value: '${s['rdv_aujourdhui'] ?? 0}',
                  label: 'RDV du jour',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeaderStat(
                  icon: Icons.people_alt_rounded,
                  value: '${s['total_patients'] ?? 0}',
                  label: 'Patients',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTodayDate() {
    final now = DateTime.now();
    const days = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi',
      'Vendredi', 'Samedi', 'Dimanche'
    ];
    const months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return '${days[now.weekday - 1]} ${now.day} ${months[now.month - 1]}';
  }

  Widget _buildHeaderStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SECTION TITLE ====================
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryGreen.withOpacity(0.15),
                  _primaryGreen.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _primaryGreen, size: 16),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _textDark,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== STATS GRID (CORRIGÉ) ====================
  Widget _buildStatsGrid(Map<String, dynamic> s) {
    final items = [
      _StatData(
        'Patients',
        '${s['total_patients'] ?? 0}',
        Icons.people_rounded,
        _primaryBlue,
        subtitle: 'Total',
      ),
      _StatData(
        'Nouveaux',
        '${s['nouveaux_patients_30j'] ?? 0}',
        Icons.person_add_rounded,
        _primaryPurple,
        subtitle: '30 derniers jours',
      ),
      _StatData(
        'RDV à venir',
        '${s['rdv_a_venir'] ?? 0}',
        Icons.schedule_rounded,
        _primaryOrange,
        subtitle: 'Planifiés',
      ),
      _StatData(
        'Médicaments',
        '${s['medicaments_actifs'] ?? 0}',
        Icons.medication_rounded,
        _primaryGreen,
        subtitle: 'Actifs',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        // ✅ CORRECTION : aspect ratio plus généreux
        childAspectRatio: 1.15,
        children: items.map((item) => _buildStatCard(item)).toList(),
      ),
    );
  }

  Widget _buildStatCard(_StatData item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icône colorée
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  item.color.withOpacity(0.20),
                  item.color.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          // Valeur + label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: item.color,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (item.subtitle != null)
                Text(
                  item.subtitle!,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SHORTCUTS ====================
  Widget _buildShortcuts() {
    final shortcuts = [
      _ShortcutData(
        'Ajouter RDV',
        Icons.add_circle_outline_rounded,
        _primaryOrange,
      ),
      _ShortcutData(
        'Prescrire',
        Icons.edit_note_rounded,
        _primaryPurple,
      ),
      // ✅ MODIFICATION ICI
      _ShortcutData(
        'Agenda',
        Icons.calendar_month_rounded,
        _primaryBlue,
      ),
      _ShortcutData(
        'Historique',
        Icons.history_rounded,
        _primaryGreen,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: shortcuts.map((s) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onShortcutTap(s.label),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: s.color.withOpacity(0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                s.color.withOpacity(0.20),
                                s.color.withOpacity(0.08),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(s.icon, color: s.color, size: 22),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            s.label,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

    // ==================== ACTIONS RAPIDES ====================
  Future<void> _onShortcutTap(String label) async {

    // ✅ GESTION AJOUTER RDV
  if (label == 'Ajouter RDV') {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: _primaryGreen),
      ),
    );

    try {
      final patientsDynamic = await DoctorService().getPatients();
      final patients = List<Map<String, dynamic>>.from(patientsDynamic);

      if (!mounted) return;
      Navigator.pop(context);

      if (patients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Aucun patient disponible'),
            backgroundColor: _primaryRed,
          ),
        );
        return;
      }

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorAddAppointmentScreen(patients: patients),
        ),
      );

      // Si un RDV a été créé, on rafraîchit le dashboard
      if (result == true) {
        _refresh();
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: _primaryRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return;
  }
    if (label == 'Prescrire') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: _primaryGreen),
        ),
      );

      try {
        final currentUser = await AuthService().getCurrentUser();

        // ✅ CORRECTION : On cast la liste pour qu'elle corresponde au type attendu
        final List<dynamic> patientsDynamic = await DoctorService().getPatients();
        final List<Map<String, dynamic>> patients = List<Map<String, dynamic>>.from(patientsDynamic);

        if (!mounted) return;
        Navigator.pop(context); // Fermer le loader

        if (currentUser == null) {
          throw Exception("Impossible de récupérer les informations du médecin.");
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorPrescriptionForm(
              patients: patients, // ✅ Maintenant c'est le bon type
              doctorName: currentUser.nom,
              doctorSpecialty: currentUser.specialite ?? 'Médecin Généraliste',
            ),
          ),
        );

      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); 
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: _primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    // ✅ AJOUT : Redirection vers la page Agenda
    if (label == 'Agenda') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DoctorAgendaScreen()),
      );
      return;
    }

    // ✅ AJOUT : Redirection vers la page d'historique
  if (label == 'Historique') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DoctorHistoryScreen()),
    );
    return;
  }

    // Autres boutons...
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label (à venir)'),
          ],
        ),
        backgroundColor: _primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ==================== TODAY SUMMARY ====================
  Widget _buildTodaySummary(Map<String, dynamic> s) {
    final rdvToday = s['rdv_aujourdhui'] ?? 0;
    final rdvUpcoming = s['rdv_a_venir'] ?? 0;
    final rdvPast = s['rdv_passes'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildSummaryRow(
              icon: Icons.today_rounded,
              color: _primaryGreen,
              label: 'Rendez-vous aujourd\'hui',
              value: '$rdvToday',
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              icon: Icons.schedule_rounded,
              color: _primaryOrange,
              label: 'À venir',
              value: '$rdvUpcoming',
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              icon: Icons.history_rounded,
              color: _primaryGrey(),
              label: 'Passés',
              value: '$rdvPast',
            ),
          ],
        ),
      ),
    );
  }

  Color _primaryGrey() => const Color(0xFFB2BEC3);

  Widget _buildSummaryRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textDark,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== ERROR STATE ====================
  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: _primaryRed,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _textGrey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
}

// ==================== MODELS ====================
class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  _StatData(
    this.label,
    this.value,
    this.icon,
    this.color, {
    this.subtitle,
  });
}

class _ShortcutData {
  final String label;
  final IconData icon;
  final Color color;

  _ShortcutData(this.label, this.icon, this.color);
}