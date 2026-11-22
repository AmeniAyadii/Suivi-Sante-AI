// lib/screens/admin/admin_home_screen.dart
// Version 5.0.0 — Lazy Loading + Bottom Bar Custom

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_doctors_screen.dart';
import 'admin_appointments_screen.dart';
import 'admin_medicaments_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_settings_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final User user;
  const AdminHomeScreen({super.key, required this.user});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  /// Cache des pages déjà visitées (lazy loading)
  final Map<int, Widget> _cachedPages = {};

  late PageController _pageController;
  late AnimationController _pulseController;
  late ScrollController _navScrollController;

  static const List<_AdminPage> _pages = [
    _AdminPage(
      label: 'Tableau de bord',
      shortLabel: 'Dashboard',
      icon: Icons.dashboard_rounded,
      color: Color(0xFF6C63FF),
    ),
    _AdminPage(
      label: 'Utilisateurs',
      shortLabel: 'Users',
      icon: Icons.people_rounded,
      color: Color(0xFF0984E3),
    ),
    _AdminPage(
      label: 'Médecins',
      shortLabel: 'Médecins',
      icon: Icons.verified_user_rounded,
      color: Color(0xFF00B894),
    ),
    _AdminPage(
      label: 'Rendez-vous',
      shortLabel: 'RDV',
      icon: Icons.calendar_month_rounded,
      color: Color(0xFFE17055),
    ),
    _AdminPage(
      label: 'Médicaments',
      shortLabel: 'Médocs',
      icon: Icons.medication_rounded,
      color: Color(0xFFD63031),
    ),
    _AdminPage(
      label: 'Notifications',
      shortLabel: 'Notifs',
      icon: Icons.notifications_active_rounded,
      color: Color(0xFF00CEC9),
    ),
    _AdminPage(
      label: 'Paramètres',
      shortLabel: 'Config',
      icon: Icons.tune_rounded,
      color: Color(0xFF636E72),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _navScrollController = ScrollController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // ✅ Charger uniquement le dashboard au démarrage
    _buildPage(0);
  }

  /// Construit une page UNIQUEMENT si elle n'est pas déjà en cache
  Widget _buildPage(int index) {
    if (_cachedPages.containsKey(index)) {
      return _cachedPages[index]!;
    }

    final Widget page;
    switch (index) {
      case 0:
        page = AdminDashboardScreen(onNavigate: _changeTab);
        break;
      case 1:
        page = const AdminUsersScreen();
        break;
      case 2:
        page = const AdminDoctorsScreen();
        break;
      case 3:
        page = const AdminAppointmentsScreen();
        break;
      case 4:
        page = const AdminMedicamentsScreen();
        break;
      case 5:
        page = const AdminNotificationsScreen();
        break;
      case 6:
        page = const AdminSettingsScreen();
        break;
      default:
        page = const SizedBox.shrink();
    }

    _cachedPages[index] = page;
    return page;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navScrollController.dispose();
    _pulseController.dispose();
    _cachedPages.clear();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      drawer: _buildDrawer(isDark),
      appBar: _buildAppBar(isDark),
      // ✅ PageView avec lazy loading
      body: PageView.builder(
        controller: _pageController,
        itemCount: _pages.length,
        // Permet le swipe mais on construit seulement les pages visitées
        allowImplicitScrolling: false,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          _scrollToActiveTab(index);
          // Forcer la construction de la page si pas encore faite
          _buildPage(index);
        },
        itemBuilder: (context, index) {
          return _buildPage(index);
        },
      ),
      bottomNavigationBar: _buildCustomBottomBar(isDark),
      floatingActionButton: _currentIndex == 0 ? _buildFAB() : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════
  PreferredSizeWidget _buildAppBar(bool isDark) {
    final currentPage = _pages[_currentIndex];

    return AppBar(
      backgroundColor: isDark ? AppTheme.surfaceDark : currentPage.color,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: 'Menu',
        ),
      ),
      title: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(currentPage.icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentPage.label,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Espace administrateur',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.75),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notifications',
              onPressed: () => _changeTab(5),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        IconButton(
          tooltip: 'Déconnexion',
          icon: const Icon(Icons.logout_rounded),
          onPressed: _logout,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BOTTOM NAV CUSTOM
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCustomBottomBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: SingleChildScrollView(
            controller: _navScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: _pages.asMap().entries.map((entry) {
                final idx = entry.key;
                final page = entry.value;
                final isSelected = idx == _currentIndex;
                return _buildNavItem(idx, page, isSelected, isDark);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int idx, _AdminPage page, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () => _changeTab(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? page.color.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: page.color.withOpacity(0.3), width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              child: Icon(
                page.icon,
                size: 22,
                color: isSelected
                    ? page.color
                    : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                page.shortLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: page.color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _scrollToActiveTab(int index) {
    if (!_navScrollController.hasClients) return;
    final itemWidth = 80.0;
    final targetOffset = (index * itemWidth) - 100;
    _navScrollController.animateTo(
      targetOffset.clamp(0, _navScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DRAWER
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDrawer(bool isDark) {
    return Drawer(
      backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF3D4FDB), const Color(0xFF5B6CFF)]
                      : [AppTheme.primaryLight, AppTheme.secondaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Administration',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Suivi Santé Pro',
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
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.3),
                          radius: 22,
                          child: Text(
                            widget.user.nom.isNotEmpty
                                ? widget.user.nom[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user.nom,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                widget.user.email,
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'NAVIGATION',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade500 : Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  ..._pages.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final page = entry.value;
                    final isSelected = idx == _currentIndex;
                    return _buildDrawerItem(idx, page, isSelected, isDark);
                  }),
                  Divider(
                    height: 32,
                    color:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'ACTIONS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade500 : Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF0984E3),
                    ),
                    title: Text(
                      'À propos',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog(isDark);
                    },
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFD63031),
              ),
              title: Text(
                'Déconnexion',
                style: GoogleFonts.inter(
                  color: const Color(0xFFD63031),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      int idx, _AdminPage page, bool isSelected, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? page.color.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context);
            _changeTab(idx);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? page.color.withOpacity(0.2)
                        : (isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    page.icon,
                    color: isSelected ? page.color : Colors.grey.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    page.label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? page.color
                          : (isDark
                              ? AppTheme.textDark
                              : const Color(0xFF2D3436)),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: page.color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FAB & ACTIONS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildFAB() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryLight.withOpacity(
                  0.3 + _pulseController.value * 0.2,
                ),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _refreshDashboard,
            backgroundColor: AppTheme.primaryLight,
            elevation: 0,
            tooltip: 'Actualiser le tableau de bord',
            child: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        );
      },
    );
  }

  void _refreshDashboard() {
    // Force le rebuild du dashboard
    setState(() {
      _cachedPages.remove(0);
    });
  }

  void _changeTab(int index) {
    if (index < 0 || index >= _pages.length) return;
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
    _scrollToActiveTab(index);
  }

  void _showAboutDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.health_and_safety, color: AppTheme.primaryLight),
            const SizedBox(width: 10),
            Text(
              'Suivi Santé Pro',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textDark : AppTheme.textLight,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 5.0.0',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.textDark : AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Application de suivi santé multi-rôles. '
              'Espace administrateur pour gérer les utilisateurs, '
              'médecins, rendez-vous et médicaments.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Fermer',
              style: GoogleFonts.inter(
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFD63031)),
            const SizedBox(width: 10),
            Text(
              'Déconnexion',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD63031),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Oui, déconnecter',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService().logout();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }
}

class _AdminPage {
  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;

  const _AdminPage({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.color,
  });
}