// lib/screens/admin/admin_appointments_screen.dart
// Version 3.0.0 — Design Premium, Dark Mode, Animations, Filtres avancés

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen>
    with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<Map<String, dynamic>> _appointmentsFuture;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedPeriod = 'all';
  int? _updatingId;
  int? _deletingId;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<Map<String, dynamic>> _statusFilters = [
    {'key': 'all', 'label': 'Tous', 'icon': Icons.apps_rounded, 'color': const Color(0xFF6C63FF)},
    {'key': 'à_venir', 'label': 'À venir', 'icon': Icons.schedule_rounded, 'color': const Color(0xFF0984E3)},
    {'key': 'passé', 'label': 'Passé', 'icon': Icons.check_circle_rounded, 'color': const Color(0xFF00B894)},
    {'key': 'annulé', 'label': 'Annulé', 'icon': Icons.cancel_rounded, 'color': const Color(0xFFD63031)},
  ];

  final List<Map<String, dynamic>> _periodFilters = [
    {'key': 'all', 'label': 'Tout', 'icon': Icons.all_inclusive_rounded},
    {'key': 'today', 'label': 'Aujourd\'hui', 'icon': Icons.today_rounded},
    {'key': 'week', 'label': 'Cette semaine', 'icon': Icons.date_range_rounded},
    {'key': 'month', 'label': 'Ce mois', 'icon': Icons.calendar_month_rounded},
    {'key': 'upcoming', 'label': 'À venir', 'icon': Icons.upcoming_rounded},
    {'key': 'past', 'label': 'Passés', 'icon': Icons.history_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _statsFuture = AdminService().getAppointmentsStats();
    _appointmentsFuture = _loadAppointments();

    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query != _searchQuery) {
        _searchQuery = query;
        _reload();
      }
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadAppointments() {
    return AdminService().getAppointments(
      statut: _selectedStatus == 'all' ? null : _selectedStatus,
      periode: _selectedPeriod == 'all' ? null : _selectedPeriod,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  void _reload() {
    setState(() {
      _appointmentsFuture = _loadAppointments();
    });
  }

  Future<void> _refreshAll() async {
    setState(() {
      _statsFuture = AdminService().getAppointmentsStats();
      _appointmentsFuture = _loadAppointments();
    });
    await Future.wait([_statsFuture, _appointmentsFuture]);
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════
  Future<void> _changeStatus(int id, String newStatus) async {
    setState(() => _updatingId = id);
    try {
      await AdminService().updateAppointmentStatus(id, newStatus);
      if (!mounted) return;
      _showSnack('Statut mis à jour avec succès', isSuccess: true);
      _refreshAll();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erreur : $e', isError: true);
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  Future<void> _deleteAppointment(int id) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.error, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Supprimer le rendez-vous',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textDark : AppTheme.textLight,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Cette action est irréversible. Confirmer la suppression ?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark
                ? AppTheme.textSecondaryDark
                : AppTheme.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Supprimer',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deletingId = id);
    try {
      await AdminService().deleteAppointment(id);
      if (!mounted) return;
      _showSnack('Rendez-vous supprimé', isSuccess: true);
      _refreshAll();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erreur : $e', isError: true);
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  void _showSnack(String message, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        onRefresh: _refreshAll,
        color: AppTheme.primaryLight,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildStatsRow(isDark),
                    const SizedBox(height: 20),
                    _buildSearchBar(isDark),
                    const SizedBox(height: 12),
                    _buildStatusFilters(isDark),
                    const SizedBox(height: 10),
                    _buildPeriodFilters(isDark),
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                        'Liste des rendez-vous', Icons.list_alt_rounded, isDark),
                    const SizedBox(height: 12),
                    _buildAppointmentsList(isDark),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STATS ROW
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStatsRow(bool isDark) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 96,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final s = snapshot.data ?? {};

        final items = [
          _StatItem('Total', '${s['total'] ?? 0}', Icons.calendar_month_rounded,
              const Color(0xFF6C63FF)),
          _StatItem('Aujourd\'hui', '${s['today'] ?? 0}', Icons.today_rounded,
              const Color(0xFF0984E3)),
          _StatItem('À venir', '${s['upcoming'] ?? 0}', Icons.schedule_rounded,
              const Color(0xFF00B894)),
          _StatItem('Annulés', '${s['cancelled'] ?? 0}', Icons.cancel_rounded,
              const Color(0xFFD63031)),
        ];

        return SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _buildStatChip(items[i], isDark),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(_StatItem item, bool isDark) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(isDark ? 0.15 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(item.icon, color: item.color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: item.color,
                ),
              ),
              Text(
                item.label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSearchBar(bool isDark) {
    return TextField(
      controller: _searchController,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: isDark ? AppTheme.textDark : AppTheme.textLight,
      ),
      decoration: InputDecoration(
        hintText: 'Rechercher par titre, patient, médecin...',
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color:
                      isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                onPressed: () => _searchController.clear(),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTERS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStatusFilters(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _statusFilters.map((f) {
          final isSelected = _selectedStatus == f['key'];
          final color = f['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedStatus = f['key'] as String);
                _reload();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.15)
                      : (isDark
                          ? AppTheme.surfaceDark
                          : AppTheme.surfaceLight),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      f['icon'] as IconData,
                      size: 14,
                      color: isSelected
                          ? color
                          : (isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      f['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? color
                            : (isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPeriodFilters(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _periodFilters.map((f) {
          final isSelected = _selectedPeriod == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedPeriod = f['key'] as String);
                _reload();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryLight.withOpacity(0.15)
                      : (isDark
                          ? AppTheme.surfaceDark
                          : AppTheme.surfaceLight),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryLight
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      f['icon'] as IconData,
                      size: 14,
                      color: isSelected
                          ? AppTheme.primaryLight
                          : (isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      f['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? AppTheme.primaryLight
                            : (isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SECTION TITLE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryLight, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.textDark : AppTheme.textLight,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LIST
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAppointmentsList(bool isDark) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _appointmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _buildError('${snapshot.error}', isDark);
        }

        final appointments = (snapshot.data?['appointments'] as List?) ?? [];

        if (appointments.isEmpty) {
          return _buildEmpty(isDark);
        }

        return Column(
          children:
              appointments.map((a) => _buildAppointmentCard(a, isDark)).toList(),
        );
      },
    );
  }

  Widget _buildAppointmentCard(dynamic a, bool isDark) {
    final id = a['id'] as int;
    final statut = a['statut']?.toString();
    final statutColor = _statusColor(statut);
    final isUpdating = _updatingId == id;
    final isDeleting = _deletingId == id;

    final dateHeure = a['date_heure'] != null
        ? DateTime.tryParse(a['date_heure'].toString())
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetailDialog(a, isDark),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        a['titre']?.toString() ?? 'Sans titre',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.textDark
                              : AppTheme.textLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statutColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(statut),
                              size: 12, color: statutColor),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel(statut),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statutColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Infos
                if (dateHeure != null)
                  _buildInfoLine(Icons.schedule_rounded,
                      _formatDateTime(dateHeure), isDark),
                const SizedBox(height: 6),
                _buildInfoLine(Icons.person_rounded,
                    a['user']?['nom']?.toString() ?? 'Patient inconnu', isDark),
                if (a['medecin_nom'] != null &&
                    a['medecin_nom'].toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoLine(Icons.medical_services_rounded,
                      'Dr. ${a['medecin_nom']}', isDark),
                ],
                if (a['lieu'] != null && a['lieu'].toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoLine(Icons.location_on_rounded,
                      a['lieu'].toString(), isDark),
                ],

                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
                const SizedBox(height: 8),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isUpdating || isDeleting)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else ...[
                      _actionButton(
                        icon: Icons.edit_rounded,
                        tooltip: 'Changer le statut',
                        color: AppTheme.primaryLight,
                        onPressed: () => _showStatusPicker(a, isDark),
                      ),
                      const SizedBox(width: 6),
                      _actionButton(
                        icon: Icons.delete_rounded,
                        tooltip: 'Supprimer',
                        color: AppTheme.error,
                        onPressed: () => _deleteAppointment(id),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoLine(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DETAILS DIALOG
  // ═══════════════════════════════════════════════════════════════
  void _showDetailDialog(dynamic a, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final statut = a['statut']?.toString();
        final statutColor = _statusColor(statut);
        final dateHeure = a['date_heure'] != null
            ? DateTime.tryParse(a['date_heure'].toString())
            : null;

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.surfaceDark : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
              child: Column(
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
                      Expanded(
                        child: Text(
                          a['titre']?.toString() ?? 'Sans titre',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppTheme.textDark
                                : AppTheme.textLight,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statutColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _statusLabel(statut),
                          style: GoogleFonts.inter(
                            color: statutColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(
                    color:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.schedule_rounded, 'Date',
                      dateHeure != null ? _formatDateTime(dateHeure) : '—',
                      isDark),
                  _buildDetailRow(Icons.person_rounded, 'Patient',
                      a['user']?['nom']?.toString() ?? '—', isDark),
                  _buildDetailRow(Icons.email_rounded, 'Email patient',
                      a['user']?['email']?.toString() ?? '—', isDark),
                  if (a['user']?['telephone'] != null)
                    _buildDetailRow(
                        Icons.phone_rounded,
                        'Téléphone',
                        a['user']?['telephone']?.toString() ?? '—',
                        isDark),
                  _buildDetailRow(Icons.medical_services_rounded, 'Médecin',
                      a['medecin_nom']?.toString() ?? '—', isDark),
                  _buildDetailRow(Icons.location_on_rounded, 'Lieu',
                      a['lieu']?.toString() ?? '—', isDark),
                  if (a['notes'] != null && a['notes'].toString().isNotEmpty)
                    _buildDetailRow(Icons.notes_rounded, 'Notes',
                        a['notes']?.toString() ?? '—', isDark),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showStatusPicker(a, isDark);
                          },
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: Text(
                            'Changer statut',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryLight,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                                color: AppTheme.primaryLight.withOpacity(0.4)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _deleteAppointment(a['id']);
                          },
                          icon: const Icon(Icons.delete_rounded, size: 18),
                          label: Text(
                            'Supprimer',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryLight),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.textDark : AppTheme.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STATUS PICKER
  // ═══════════════════════════════════════════════════════════════
  void _showStatusPicker(dynamic a, bool isDark) {
    final currentStatus = a['statut']?.toString();
    final statuses = [
      {
        'key': 'à_venir',
        'label': 'À venir',
        'color': const Color(0xFF0984E3),
        'icon': Icons.schedule_rounded
      },
      {
        'key': 'passé',
        'label': 'Passé',
        'color': const Color(0xFF636E72),
        'icon': Icons.check_circle_rounded
      },
      {
        'key': 'annulé',
        'label': 'Annulé',
        'color': const Color(0xFFD63031),
        'icon': Icons.cancel_rounded
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Changer le statut',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textDark : AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 16),
            ...statuses.map((s) {
              final isCurrent = s['key'] == currentStatus;
              final color = s['color'] as Color;
              final icon = s['icon'] as IconData;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isCurrent
                      ? color.withOpacity(0.1)
                      : (isDark
                          ? AppTheme.surfaceDark
                          : AppTheme.surfaceLight),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isCurrent
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            _changeStatus(a['id'], s['key'] as String);
                          },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrent
                              ? color
                              : (isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200),
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: color, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s['label'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: color,
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Icon(Icons.check_circle,
                                color: color, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // UTILS
  // ═══════════════════════════════════════════════════════════════
  String _formatDateTime(DateTime dt) {
    final months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final prefix =
        isToday ? 'Aujourd\'hui' : '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    return '$prefix à ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String? statut) {
    switch (statut) {
      case 'à_venir':
        return const Color(0xFF0984E3);
      case 'passé':
        return const Color(0xFF636E72);
      case 'annulé':
        return const Color(0xFFD63031);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? statut) {
    switch (statut) {
      case 'à_venir':
        return 'À venir';
      case 'passé':
        return 'Passé';
      case 'annulé':
        return 'Annulé';
      default:
        return statut ?? '—';
    }
  }

  IconData _statusIcon(String? statut) {
    switch (statut) {
      case 'à_venir':
        return Icons.schedule_rounded;
      case 'passé':
        return Icons.check_circle_rounded;
      case 'annulé':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // EMPTY / ERROR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildEmpty(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 64,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun rendez-vous',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textDark : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Essayez de modifier les filtres',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 56, color: AppTheme.error),
          const SizedBox(height: 12),
          Text(
            'Erreur de chargement',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textDark : AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              'Réessayer',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════
class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _StatItem(this.label, this.value, this.icon, this.color);
}