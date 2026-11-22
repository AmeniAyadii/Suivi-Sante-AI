// lib/screens/admin/admin_dashboard_screen.dart
// Version 4.0.0 — Contenu uniquement, compatible AdminHomeScreen

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  /// Callback pour naviguer vers un onglet spécifique de AdminHomeScreen
  final void Function(int index)? onNavigate;

  const AdminDashboardScreen({super.key, this.onNavigate});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<Map<String, dynamic>> _activityFuture;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Indices des onglets (doivent correspondre à AdminHomeScreen._pages)
  static const int TAB_DASHBOARD = 0;
  static const int TAB_USERS = 1;
  static const int TAB_DOCTORS = 2;
  static const int TAB_APPOINTMENTS = 3;
  static const int TAB_MEDICAMENTS = 4;
  static const int TAB_NOTIFICATIONS = 5;

  @override
  void initState() {
    super.initState();
    _statsFuture = AdminService().getStats();
    _activityFuture = AdminService().getRecentActivity();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    setState(() {
      _statsFuture = AdminService().getStats();
      _activityFuture = AdminService().getRecentActivity();
    });
    await Future.wait([_statsFuture, _activityFuture]);
  }

  void _navigateTo(int index) {
    widget.onNavigate?.call(index);
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD — PAS DE SCAFFOLD, PAS D'APPBAR, PAS DE FAB
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.primaryLight,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildHeaderBanner(isDark),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildStatsOverview(isDark),
                    const SizedBox(height: 28),
                    _buildSectionTitle(
                        'Accès rapide', Icons.grid_view_rounded, isDark),
                    const SizedBox(height: 12),
                    _buildQuickAccessGrid(isDark),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Détails de la plateforme',
                        Icons.insights_rounded, isDark),
                    const SizedBox(height: 12),
                    _buildDetailedStats(isDark),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Spécialités médicales',
                        Icons.local_hospital_rounded, isDark),
                    const SizedBox(height: 12),
                    _buildSpecialities(isDark),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Activité récente',
                        Icons.history_rounded, isDark),
                    const SizedBox(height: 12),
                    _buildActivity(isDark),
                    const SizedBox(height: 100), // Espace pour la bottom nav
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
  // HEADER BANNER (sans AppBar, intégré dans le scroll)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeaderBanner(bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF3D4FDB), const Color(0xFF5B6CFF)]
                : [AppTheme.primaryLight, AppTheme.secondaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryLight.withOpacity(0.25),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenue 👋',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Voici l\'état de votre plateforme',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: _statsFuture,
              builder: (context, snapshot) {
                final total = snapshot.data?['total_users'] ?? 0;
                final newUsers = snapshot.data?['new_users_last_30d'] ?? 0;
                return Row(
                  children: [
                    Expanded(
                      child: _buildHeaderBadge(
                        icon: Icons.people_alt_rounded,
                        label: 'Utilisateurs',
                        value: '$total',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildHeaderBadge(
                        icon: Icons.trending_up_rounded,
                        label: 'Nouveaux (30j)',
                        value: '+$newUsers',
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBadge({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 10,
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
  // STATS OVERVIEW
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStatsOverview(bool isDark) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _buildError('Impossible de charger les statistiques', isDark);
        }

        final s = snapshot.data ?? {};

        final cards = [
          _OverviewData(
            label: 'Utilisateurs',
            value: '${s['total_users'] ?? 0}',
            icon: Icons.people_rounded,
            color: const Color(0xFF0984E3),
            trend: '+${s['new_users_last_30d'] ?? 0}',
            onTap: () => _navigateTo(TAB_USERS),
          ),
          _OverviewData(
            label: 'Patients',
            value: '${s['total_patients'] ?? 0}',
            icon: Icons.person_rounded,
            color: const Color(0xFF00B894),
            onTap: () => _navigateTo(TAB_USERS),
          ),
          _OverviewData(
            label: 'Médecins',
            value: '${s['total_doctors'] ?? 0}',
            icon: Icons.medical_services_rounded,
            color: const Color(0xFF00CEC9),
            badge: (s['pending_doctors'] ?? 0) > 0
                ? '${s['pending_doctors']} en attente'
                : null,
            onTap: () => _navigateTo(TAB_DOCTORS),
          ),
          _OverviewData(
            label: 'Admins',
            value: '${s['total_admins'] ?? 0}',
            icon: Icons.admin_panel_settings_rounded,
            color: const Color(0xFF6C63FF),
            onTap: () => _navigateTo(TAB_USERS),
          ),
        ];

        return SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) =>
                _buildOverviewCard(cards[i], isDark),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(_OverviewData data, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: data.color.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: data.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(data.icon, color: data.color, size: 22),
                  ),
                  if (data.trend != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_upward,
                              size: 10, color: Colors.green.shade700),
                          const SizedBox(width: 2),
                          Text(
                            data.trend!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (data.onTap != null)
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: data.color.withOpacity(0.4),
                    ),
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  data.value,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: data.color,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (data.badge != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    data.badge!,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // QUICK ACCESS GRID
  // ═══════════════════════════════════════════════════════════════
  Widget _buildQuickAccessGrid(bool isDark) {
    final items = [
      _QuickAccessData(
        label: 'Utilisateurs',
        icon: Icons.people_rounded,
        color: const Color(0xFF0984E3),
        onTap: () => _navigateTo(TAB_USERS),
      ),
      _QuickAccessData(
        label: 'Validation médecins',
        icon: Icons.verified_user_rounded,
        color: const Color(0xFF00B894),
        onTap: () => _navigateTo(TAB_DOCTORS),
      ),
      _QuickAccessData(
        label: 'Rendez-vous',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFFE17055),
        onTap: () => _navigateTo(TAB_APPOINTMENTS),
      ),
      _QuickAccessData(
        label: 'Médicaments',
        icon: Icons.medication_rounded,
        color: const Color(0xFFD63031),
        onTap: () => _navigateTo(TAB_MEDICAMENTS),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children:
          items.map((item) => _buildQuickAccessCard(item, isDark)).toList(),
    );
  }

  Widget _buildQuickAccessCard(_QuickAccessData data, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: data.color.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: data.color.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: data.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(data.icon, color: data.color, size: 22),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: data.color.withOpacity(0.4),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppTheme.textDark : AppTheme.textLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ouvrir',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: data.color,
                      fontWeight: FontWeight.w600,
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

  // ═══════════════════════════════════════════════════════════════
  // DETAILED STATS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDetailedStats(bool isDark) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final s = snapshot.data!;

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMiniCard(
                    icon: Icons.calendar_today_rounded,
                    label: 'Rendez-vous',
                    value: '${s['total_rendezvous'] ?? 0}',
                    subValue: '${s['upcoming_rendezvous'] ?? 0} à venir',
                    color: const Color(0xFFE17055),
                    onTap: () => _navigateTo(TAB_APPOINTMENTS),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniCard(
                    icon: Icons.medication_rounded,
                    label: 'Médicaments',
                    value: '${s['total_medicaments'] ?? 0}',
                    color: const Color(0xFFD63031),
                    onTap: () => _navigateTo(TAB_MEDICAMENTS),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMiniCard(
                    icon: Icons.check_circle_rounded,
                    label: 'Actifs',
                    value: '${s['active_users'] ?? 0}',
                    color: const Color(0xFF00B894),
                    onTap: () => _navigateTo(TAB_USERS),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniCard(
                    icon: Icons.block_rounded,
                    label: 'Inactifs',
                    value: '${s['inactive_users'] ?? 0}',
                    color: const Color(0xFFB2BEC3),
                    onTap: () => _navigateTo(TAB_USERS),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subValue,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subValue != null)
                      Text(
                        subValue,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: color.withOpacity(0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SPÉCIALITÉS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSpecialities(bool isDark) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final specialities = snapshot.data!['specialities'] as Map?;

        if (specialities == null || specialities.isEmpty) {
          return _buildEmptyCard(
              'Aucune spécialité enregistrée', isDark);
        }

        final entries = specialities.entries.toList()
          ..sort((a, b) => (b.value as int).compareTo(a.value as int));

        final maxValue = entries.isEmpty ? 1 : entries.first.value as int;
        final colors = [
          const Color(0xFF6C63FF),
          const Color(0xFF00B894),
          const Color(0xFF0984E3),
          const Color(0xFFE17055),
          const Color(0xFFFDCB6E),
        ];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: entries.asMap().entries.map((e) {
              final idx = e.key;
              final label = e.value.key.toString();
              final count = e.value.value as int;
              final ratio = count / maxValue;
              final color = colors[idx % colors.length];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTheme.textDark
                                  : AppTheme.textLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.inter(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTIVITÉ
  // ═══════════════════════════════════════════════════════════════
  Widget _buildActivity(bool isDark) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _activityFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final users = (snapshot.data!['recent_users'] as List?) ?? [];
        final rdvs = (snapshot.data!['recent_rendezvous'] as List?) ?? [];

        if (users.isEmpty && rdvs.isEmpty) {
          return _buildEmptyCard('Aucune activité récente', isDark);
        }

        final allItems = [
          ...users.map((u) => _ActivityItem(
                icon: Icons.person_add_rounded,
                color: _roleColor(u['role']),
                title: '${u['nom'] ?? 'Utilisateur'} s\'est inscrit',
                subtitle: 'Rôle: ${u['role'] ?? 'patient'}',
                date: u['date'],
              )),
          ...rdvs.map((r) => _ActivityItem(
                icon: Icons.calendar_today_rounded,
                color: const Color(0xFFE17055),
                title: r['titre'] ?? 'Nouveau rendez-vous',
                subtitle: 'Patient: ${r['user_nom'] ?? 'Inconnu'}',
                date: r['date'],
              )),
        ];

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: allItems.asMap().entries.map((e) {
              final item = e.value;
              final isLast = e.key == allItems.length - 1;
              return _buildActivityTile(item, isLast, isDark);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildActivityTile(_ActivityItem item, bool isLast, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.color, size: 16),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 24,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? AppTheme.textDark : AppTheme.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          if (item.date != null) _formatRelativeDate(item.date!, isDark),
        ],
      ),
    );
  }

  Widget _formatRelativeDate(String date, bool isDark) {
    try {
      final dt = DateTime.parse(date);
      final diff = DateTime.now().difference(dt);
      String label;
      if (diff.inMinutes < 1) {
        label = 'À l\'instant';
      } else if (diff.inHours < 1) {
        label = '${diff.inMinutes}m';
      } else if (diff.inDays < 1) {
        label = '${diff.inHours}h';
      } else if (diff.inDays < 30) {
        label = '${diff.inDays}j';
      } else {
        label = '${(diff.inDays / 30).floor()} mois';
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isDark
                ? AppTheme.textSecondaryDark
                : AppTheme.textSecondaryLight,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } catch (_) {
      return const SizedBox();
    }
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'admin':
        return const Color(0xFF6C63FF);
      case 'doctor':
        return const Color(0xFF00B894);
      default:
        return const Color(0xFF0984E3);
    }
  }

  Widget _buildEmptyCard(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
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
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isDark ? AppTheme.textDark : AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MODELS INTERNES
// ═══════════════════════════════════════════════════════════════
class _OverviewData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final String? badge;
  final VoidCallback? onTap;

  _OverviewData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.badge,
    this.onTap,
  });
}

class _ActivityItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? date;

  _ActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.date,
  });
}

class _QuickAccessData {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickAccessData({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}