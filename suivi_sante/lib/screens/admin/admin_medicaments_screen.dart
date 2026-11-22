// lib/screens/admin/admin_medicaments_screen.dart
// Version 3.0.0 — Design Premium, Dark Mode, Animations, Filtres avancés

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class AdminMedicamentsScreen extends StatefulWidget {
  const AdminMedicamentsScreen({super.key});

  @override
  State<AdminMedicamentsScreen> createState() =>
      _AdminMedicamentsScreenState();
}

class _AdminMedicamentsScreenState extends State<AdminMedicamentsScreen>
    with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<Map<String, dynamic>> _medicamentsFuture;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedStatus = 'all';
  bool _showLowStock = false;
  int? _updatingId;
  int? _deletingId;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<Map<String, dynamic>> _statusFilters = [
    {'key': 'all', 'label': 'Tous', 'icon': Icons.apps_rounded, 'color': const Color(0xFF6C63FF)},
    {'key': 'actif', 'label': 'Actifs', 'icon': Icons.play_circle_rounded, 'color': const Color(0xFF00B894)},
    {'key': 'inactif', 'label': 'Inactifs', 'icon': Icons.pause_circle_rounded, 'color': const Color(0xFFB2BEC3)},
    {'key': 'termine', 'label': 'Terminés', 'icon': Icons.check_circle_rounded, 'color': const Color(0xFF0984E3)},
  ];

  @override
  void initState() {
    super.initState();
    _statsFuture = AdminService().getMedicamentsStats();
    _medicamentsFuture = _loadMedicaments();

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

  Future<Map<String, dynamic>> _loadMedicaments() {
    return AdminService().getMedicaments(
      statut: _selectedStatus == 'all' ? null : _selectedStatus,
      stock: _showLowStock ? 'low' : null,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  void _reload() {
    setState(() {
      _medicamentsFuture = _loadMedicaments();
    });
  }

  Future<void> _refreshAll() async {
    setState(() {
      _statsFuture = AdminService().getMedicamentsStats();
      _medicamentsFuture = _loadMedicaments();
    });
    await Future.wait([_statsFuture, _medicamentsFuture]);
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════
  Future<void> _changeStatus(int id, String newStatus) async {
    setState(() => _updatingId = id);
    try {
      await AdminService().updateMedicamentStatus(id, newStatus);
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

  Future<void> _deleteMedicament(int id, String nom) async {
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
                'Supprimer le médicament',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textDark : AppTheme.textLight,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment supprimer "$nom" ?\nCette action est irréversible.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark
                ? AppTheme.textSecondaryDark
                : AppTheme.textSecondaryLight,
            height: 1.5,
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
      await AdminService().deleteMedicament(id);
      if (!mounted) return;
      _showSnack('Médicament supprimé', isSuccess: true);
      _refreshAll();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erreur : $e', isError: true);
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  void _showSnack(String message,
      {bool isError = false, bool isSuccess = false}) {
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
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                        'Liste des médicaments', Icons.medication_rounded, isDark),
                    const SizedBox(height: 12),
                    _buildMedicamentsList(isDark),
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
  // STATS
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
          _StatItem('Total', '${s['total'] ?? 0}', Icons.medication_rounded,
              const Color(0xFF6C63FF)),
          _StatItem('Actifs', '${s['actifs'] ?? 0}', Icons.play_circle_rounded,
              const Color(0xFF00B894)),
          _StatItem('Inactifs', '${s['inactifs'] ?? 0}',
              Icons.pause_circle_rounded, const Color(0xFFB2BEC3)),
          _StatItem('Terminés', '${s['termines'] ?? 0}',
              Icons.check_circle_rounded, const Color(0xFF0984E3)),
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
        hintText: 'Rechercher par nom, patient...',
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
        children: [
          ..._statusFilters.map((f) {
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
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
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
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
          // Filtre stock faible
          GestureDetector(
            onTap: () {
              setState(() => _showLowStock = !_showLowStock);
              _reload();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _showLowStock
                    ? Colors.orange.withOpacity(0.15)
                    : (isDark
                        ? AppTheme.surfaceDark
                        : AppTheme.surfaceLight),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _showLowStock
                      ? Colors.orange
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: _showLowStock
                        ? Colors.orange.shade900
                        : (isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Stock faible',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: _showLowStock
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: _showLowStock
                          ? Colors.orange.shade900
                          : (isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700),
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
  Widget _buildMedicamentsList(bool isDark) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _medicamentsFuture,
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

        final medicaments = (snapshot.data?['medicaments'] as List?) ?? [];

        if (medicaments.isEmpty) {
          return _buildEmpty(isDark);
        }

        return Column(
          children: medicaments
              .map((m) => _buildMedicamentCard(m, isDark))
              .toList(),
        );
      },
    );
  }

  Widget _buildMedicamentCard(dynamic m, bool isDark) {
    final id = m['id'] as int;
    final statut = m['statut']?.toString();
    final statutColor = _statusColor(statut);
    final isUpdating = _updatingId == id;
    final isDeleting = _deletingId == id;

    final prochaineprise = m['prochaine_prise'] != null
        ? DateTime.tryParse(m['prochaine_prise'].toString())
        : null;

    final stockActuel = m['stock_actuel'];
    final seuilAlerte = m['seuil_alerte_stock'];
    final isLowStock = stockActuel != null && seuilAlerte != null
        ? (stockActuel is int
                ? stockActuel
                : int.tryParse(stockActuel.toString()) ?? 0) <=
            (seuilAlerte is int
                ? seuilAlerte
                : int.tryParse(seuilAlerte.toString()) ?? 0)
        : false;

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
          onTap: () => _showDetailDialog(m, isDark),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statutColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.medication_rounded,
                        size: 20,
                        color: statutColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m['nom']?.toString() ?? 'Sans nom',
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
                          if (m['dosage'] != null &&
                              m['dosage'].toString().isNotEmpty)
                            Text(
                              '${m['dosage']}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
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
                const SizedBox(height: 12),

                // Alerte stock
                if (isLowStock)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 14, color: Colors.orange.shade900),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Stock faible ($stockActuel restants)',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Infos
                _buildInfoLine(Icons.person_rounded,
                    m['user']?['nom']?.toString() ?? 'Patient inconnu', isDark),
                if (m['frequence'] != null &&
                    m['frequence'].toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoLine(Icons.repeat_rounded,
                      m['frequence'].toString(), isDark),
                ],
                if (prochaineprise != null) ...[
                  const SizedBox(height: 6),
                  _buildInfoLine(
                      Icons.access_time_rounded,
                      'Prochaine: ${_formatDateTime(prochaineprise)}',
                      isDark),
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
                        onPressed: () => _showStatusPicker(m, isDark),
                      ),
                      const SizedBox(width: 6),
                      _actionButton(
                        icon: Icons.delete_rounded,
                        tooltip: 'Supprimer',
                        color: AppTheme.error,
                        onPressed: () =>
                            _deleteMedicament(id, m['nom'] ?? ''),
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
  void _showDetailDialog(dynamic m, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final statut = m['statut']?.toString();
        final statutColor = _statusColor(statut);

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
                          m['nom']?.toString() ?? 'Sans nom',
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
                  _buildDetailRow(Icons.person_rounded, 'Patient',
                      m['user']?['nom']?.toString() ?? '—', isDark),
                  _buildDetailRow(Icons.email_rounded, 'Email patient',
                      m['user']?['email']?.toString() ?? '—', isDark),
                  if (m['dosage'] != null)
                    _buildDetailRow(Icons.straighten_rounded, 'Dosage',
                        m['dosage']?.toString() ?? '—', isDark),
                  if (m['frequence'] != null)
                    _buildDetailRow(Icons.repeat_rounded, 'Fréquence',
                        m['frequence']?.toString() ?? '—', isDark),
                  if (m['forme'] != null)
                    _buildDetailRow(Icons.category_rounded, 'Forme',
                        m['forme']?.toString() ?? '—', isDark),
                  if (m['voie_administration'] != null)
                    _buildDetailRow(
                        Icons.route_rounded,
                        'Voie d\'administration',
                        m['voie_administration']?.toString() ?? '—',
                        isDark),
                  if (m['stock_actuel'] != null)
                    _buildDetailRow(
                        Icons.inventory_2_rounded,
                        'Stock',
                        '${m['stock_actuel']} (seuil: ${m['seuil_alerte_stock'] ?? '—'})',
                        isDark),
                  if (m['date_debut'] != null)
                    _buildDetailRow(
                        Icons.play_arrow_rounded,
                        'Début',
                        m['date_debut']?.toString().substring(0, 10) ?? '—',
                        isDark),
                  if (m['date_fin'] != null)
                    _buildDetailRow(
                        Icons.stop_rounded,
                        'Fin',
                        m['date_fin']?.toString().substring(0, 10) ?? '—',
                        isDark),
                  if (m['notes'] != null &&
                      m['notes'].toString().isNotEmpty)
                    _buildDetailRow(Icons.notes_rounded, 'Notes',
                        m['notes']?.toString() ?? '—', isDark),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showStatusPicker(m, isDark);
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
                                color:
                                    AppTheme.primaryLight.withOpacity(0.4)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _deleteMedicament(m['id'], m['nom'] ?? '');
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
            width: 120,
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
  void _showStatusPicker(dynamic m, bool isDark) {
    final currentStatus = m['statut']?.toString();
    final statuses = [
      {
        'key': 'actif',
        'label': 'Actif',
        'color': const Color(0xFF00B894),
        'icon': Icons.play_circle_rounded
      },
      {
        'key': 'inactif',
        'label': 'Inactif',
        'color': const Color(0xFFB2BEC3),
        'icon': Icons.pause_circle_rounded
      },
      {
        'key': 'termine',
        'label': 'Terminé',
        'color': const Color(0xFF0984E3),
        'icon': Icons.check_circle_rounded
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
                            _changeStatus(m['id'], s['key'] as String);
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} à ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String? statut) {
    switch (statut) {
      case 'actif':
        return const Color(0xFF00B894);
      case 'inactif':
        return const Color(0xFFB2BEC3);
      case 'termine':
        return const Color(0xFF0984E3);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? statut) {
    switch (statut) {
      case 'actif':
        return 'Actif';
      case 'inactif':
        return 'Inactif';
      case 'termine':
        return 'Terminé';
      default:
        return statut ?? '—';
    }
  }

  IconData _statusIcon(String? statut) {
    switch (statut) {
      case 'actif':
        return Icons.play_circle_rounded;
      case 'inactif':
        return Icons.pause_circle_rounded;
      case 'termine':
        return Icons.check_circle_rounded;
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
            Icons.medication_liquid_rounded,
            size: 64,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun médicament',
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