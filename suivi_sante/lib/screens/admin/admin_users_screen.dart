// lib/screens/admin/admin_users_screen.dart
// Version 3.0.0 — Design Premium, Dark Mode, Animations

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with TickerProviderStateMixin {
  late Future<List<dynamic>> _future;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _roleFilter = 'all';
  int? _updatingUserId;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _future = AdminService().getUsers();
    _searchController.addListener(() {
      setState(() =>
          _searchQuery = _searchController.text.trim().toLowerCase());
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

  // ═══════════════════════════════════════════════════════════════
  // CHANGER LE RÔLE
  // ═══════════════════════════════════════════════════════════════
  Future<void> _changeRole(int userId, String role, String nom) async {
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
                color: _roleColor(role).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_roleIcon(role), color: _roleColor(role), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Changer le rôle',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textDark : AppTheme.textLight,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Attribuer le rôle "${_roleLabel(role)}" à $nom ?',
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
              backgroundColor: _roleColor(role),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Confirmer',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _updatingUserId = userId);

    try {
      await AdminService().assignRole(userId, role);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$nom est maintenant "${_roleLabel(role)}"',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

      setState(() => _future = AdminService().getUsers());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _updatingUserId = null);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UTILITAIRES RÔLE
  // ═══════════════════════════════════════════════════════════════
  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFF6C63FF);
      case 'doctor':
        return const Color(0xFF00B894);
      default:
        return const Color(0xFF0984E3);
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'doctor':
        return Icons.medical_services_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'doctor':
        return 'Médecin';
      default:
        return 'Patient';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTRAGE
  // ═══════════════════════════════════════════════════════════════
  List<dynamic> _applyFilters(List<dynamic> users) {
    return users.where((u) {
      final nom = (u['nom'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final role = (u['role'] ?? 'patient').toString();

      final matchesSearch = _searchQuery.isEmpty ||
          nom.contains(_searchQuery) ||
          email.contains(_searchQuery);

      final matchesRole = _roleFilter == 'all' || role == _roleFilter;

      return matchesSearch && matchesRole;
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          _buildSearchBar(isDark),
          _buildRoleFilters(isDark),
          Expanded(child: _buildUsersList(isDark)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BARRE DE RECHERCHE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: isDark ? AppTheme.textDark : AppTheme.textLight,
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher un utilisateur...',
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
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTRES PAR RÔLE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildRoleFilters(bool isDark) {
    final filters = [
      {'key': 'all', 'label': 'Tous', 'color': Colors.grey, 'icon': Icons.apps_rounded},
      {'key': 'patient', 'label': 'Patients', 'color': const Color(0xFF0984E3), 'icon': Icons.person_rounded},
      {'key': 'doctor', 'label': 'Médecins', 'color': const Color(0xFF00B894), 'icon': Icons.medical_services_rounded},
      {'key': 'admin', 'label': 'Admins', 'color': const Color(0xFF6C63FF), 'icon': Icons.admin_panel_settings_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final isSelected = _roleFilter == f['key'];
          final color = f['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () =>
                  setState(() => _roleFilter = f['key'] as String),
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

  // ═══════════════════════════════════════════════════════════════
  // LISTE DES UTILISATEURS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildUsersList(bool isDark) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildError(snapshot.error.toString(), isDark);
        }

        final allUsers = snapshot.data ?? [];
        final users = _applyFilters(allUsers);

        if (allUsers.isEmpty) {
          return _buildEmpty('Aucun utilisateur enregistré', isDark);
        }

        if (users.isEmpty) {
          return _buildEmpty('Aucun résultat pour ce filtre', isDark);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _future = AdminService().getUsers());
            await _future;
          },
          color: AppTheme.primaryLight,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: users.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people_alt_rounded,
                        size: 16,
                        color: AppTheme.primaryLight,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${users.length} utilisateur(s)',
                        style: GoogleFonts.inter(
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final u = users[index - 1];
              final role = (u['role'] ?? 'patient').toString();
              final isUpdating = _updatingUserId == u['id'];

              return _buildUserCard(u, role, isUpdating, isDark);
            },
          ),
        );
      },
    );
  }

  Widget _buildUserCard(
      Map<String, dynamic> u, String role, bool isUpdating, bool isDark) {
    final color = _roleColor(role);
    final isActive = u['is_active'] != false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withOpacity(0.15),
                child: Text(
                  (u['nom'] ?? '?').toString().isNotEmpty
                      ? (u['nom'] as String)[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceDark : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_roleIcon(role), size: 14, color: color),
                ),
              ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  u['nom'] ?? 'Sans nom',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? AppTheme.textDark : AppTheme.textLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Inactif',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u['email'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _roleLabel(role),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (u['specialite'] != null &&
                        u['specialite'].toString().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '• ${u['specialite']}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          trailing: isUpdating
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
                  tooltip: 'Changer le rôle',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  color: isDark ? AppTheme.surfaceDark : Colors.white,
                  onSelected: (newRole) {
                    if (newRole != role) {
                      _changeRole(u['id'], newRole, u['nom'] ?? '');
                    }
                  },
                  itemBuilder: (_) => [
                    _buildRoleMenuItem(
                        'patient', 'Patient', role, isDark),
                    _buildRoleMenuItem(
                        'doctor', 'Médecin', role, isDark),
                    _buildRoleMenuItem('admin', 'Admin', role, isDark),
                  ],
                ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MENU ITEM POUR RÔLE
  // ═══════════════════════════════════════════════════════════════
  PopupMenuItem<String> _buildRoleMenuItem(
    String value,
    String label,
    String currentRole,
    bool isDark,
  ) {
    final isCurrent = value == currentRole;
    final color = _roleColor(value);
    return PopupMenuItem<String>(
      value: value,
      enabled: !isCurrent,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isCurrent
                  ? Colors.grey.withOpacity(0.1)
                  : color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _roleIcon(value),
              color: isCurrent ? Colors.grey : color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isCurrent
                  ? (isDark ? Colors.grey.shade500 : Colors.grey)
                  : (isDark ? AppTheme.textDark : AppTheme.textLight),
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          if (isCurrent) ...[
            const Spacer(),
            Icon(Icons.check_circle_rounded,
                color: AppTheme.success, size: 16),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EMPTY & ERROR
  // ═══════════════════════════════════════════════════════════════
  Widget _buildEmpty(String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 56,
                color: AppTheme.primaryLight.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppTheme.error),
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textDark : AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => setState(() => _future = AdminService().getUsers()),
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
      ),
    );
  }
}