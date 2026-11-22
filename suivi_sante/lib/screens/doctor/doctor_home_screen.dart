// lib/screens/doctor/doctor_home_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:suivi_sante_pro/screens/doctor/doctor_settings_screen.dart';
import 'package:suivi_sante_pro/services/doctor/notification_service.dart';
import '../../models/user.dart';
import 'doctor_dashboard_tab.dart';
import 'doctor_patients_screen.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_prescriptions_screen.dart';
import 'doctor_profile_screen.dart';
import 'notifications_screen.dart';
import '../../services/auth_service.dart';

import '../login_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  final User user;
  const DoctorHomeScreen({super.key, required this.user});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _currentIndex = 0;

  // ==================== NOTIFICATIONS ====================
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  Timer? _pollingTimer;

  // ==================== LISTE DES PAGES ====================
  static const List<_DoctorPage> _pages = [
    _DoctorPage(
      label: 'Tableau de bord',
      shortLabel: 'Accueil',
      icon: Icons.dashboard_rounded,
      color: Color(0xFF00B894),
    ),
    _DoctorPage(
      label: 'Mes patients',
      shortLabel: 'Patients',
      icon: Icons.people_rounded,
      color: Color(0xFF0984E3),
    ),
    _DoctorPage(
      label: 'Rendez-vous',
      shortLabel: 'RDV',
      icon: Icons.calendar_month_rounded,
      color: Color(0xFFE17055),
    ),
    _DoctorPage(
      label: 'Ordonnances',
      shortLabel: 'Ordonnances',
      icon: Icons.medication_rounded,
      color: Color(0xFF6C5CE7),
    ),
    _DoctorPage(
      label: 'Mon profil',
      shortLabel: 'Profil',
      icon: Icons.person_rounded,
      color: Color(0xFFD63031),
    ),
  ];

  // ==================== LIFECYCLE ====================
  @override
  void initState() {
    super.initState();
    _refreshUnreadCount();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // ==================== NOTIFICATIONS HELPERS ====================
  Future<void> _refreshUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (!mounted) return;
      setState(() => _unreadCount = count);
    } catch (_) {
      // Silencieux : pas de badge si erreur réseau
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshUnreadCount(),
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
    // Au retour, on rafraîchit le badge
    if (!mounted) return;
    _refreshUnreadCount();
  }

  // ==================== HELPERS ====================
  /// Retourne le nom complet avec "Dr." seulement si le nom ne contient pas déjà "Dr"
  String get _doctorDisplayName {
    final nom = widget.user.nom.trim();
    if (nom.isEmpty) return 'Docteur';

    final lowerNom = nom.toLowerCase();
    if (lowerNom.startsWith('dr ') ||
        lowerNom.startsWith('dr.') ||
        lowerNom.startsWith('docteur ') ||
        lowerNom.contains(' dr ') ||
        lowerNom.contains(' dr. ')) {
      return nom;
    }

    return 'Dr. $nom';
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final pages = [
      const DoctorDashboardTab(),
      const DoctorPatientsScreen(),
      const DoctorAppointmentsScreen(),
      const DoctorPrescriptionsScreen(), // ✅ Page intégrée
      DoctorProfileScreen(user: widget.user),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      drawer: _buildDrawer(),
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ==================== APPBAR ====================
  PreferredSizeWidget _buildAppBar() {
    final currentPage = _pages[_currentIndex];
    return AppBar(
      backgroundColor: currentPage.color,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(currentPage.icon, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              currentPage.label,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        // ⚙️ Icône Paramètres
        IconButton(
          tooltip: 'Paramètres',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DoctorSettingsScreen(user: widget.user)),
            );
          },
        ),
        // 🔔 Icône notifications avec badge
        _buildNotificationBell(),
        // 🚪 Icône déconnexion
        IconButton(
          tooltip: 'Déconnexion',
          icon: const Icon(Icons.logout_rounded),
          onPressed: _logout,
        ),
      ],
    );
  }

  // ==================== NOTIFICATION BELL ====================
  Widget _buildNotificationBell() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: _openNotifications,
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : '$_unreadCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ==================== DRAWER ====================
  Widget _buildDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // ---------- EN-TÊTE ----------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00B894), Color(0xFF55EFC4)],
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
                          Icons.medical_services_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Espace Médecin',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Suivi Santé Pro',
                              style: TextStyle(
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
                          radius: 20,
                          child: Text(
                            widget.user.nom.isNotEmpty
                                ? widget.user.nom[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
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
                                _doctorDisplayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                widget.user.specialite ?? widget.user.email,
                                style: const TextStyle(
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

            // ---------- MENU ----------
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'NAVIGATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  ..._pages.asMap().entries.map((e) {
                    final idx = e.key;
                    final page = e.value;
                    final isSelected = idx == _currentIndex;
                    return _buildDrawerItem(idx, page, isSelected);
                  }),
                  const Divider(height: 32),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'ACTIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  // 🔔 Notifications
                  ListTile(
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          color: Color(0xFFE17055),
                        ),
                        if (_unreadCount > 0)
                          Positioned(
                            right: -6,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _unreadCount > 99 ? '99+' : '$_unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: const Text('Notifications'),
                    onTap: () {
                      Navigator.pop(context);
                      _openNotifications();
                    },
                  ),
                  
                  // ⚙️ Paramètres
                  ListTile(
                    leading: const Icon(
                      Icons.settings_outlined,
                      color: Color(0xFFCF5DB3),
                    ),
                    title: const Text('Paramètres'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DoctorSettingsScreen(user: widget.user)),
                      );
                    },
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF0984E3),
                    ),
                    title: const Text('À propos'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog();
                    },
                  ),
                ],
              ),
            ),

            // ---------- DÉCONNEXION ----------
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFD63031),
              ),
              title: const Text(
                'Déconnexion',
                style: TextStyle(
                  color: Color(0xFFD63031),
                  fontWeight: FontWeight.w600,
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

  Widget _buildDrawerItem(int idx, _DoctorPage page, bool isSelected) {
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
                        : Colors.grey.shade100,
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color:
                          isSelected ? page.color : const Color(0xFF2D3436),
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

  // ==================== BOTTOM NAV ====================
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _changeTab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _pages[_currentIndex].color,
        unselectedItemColor: Colors.grey.shade500,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        elevation: 0,
        items: _pages.map((page) {
          return BottomNavigationBarItem(
            icon: Icon(page.icon),
            label: page.shortLabel,
          );
        }).toList(),
      ),
    );
  }

  // ==================== ACTIONS ====================
  void _changeTab(int index) {
    if (index < 0 || index >= _pages.length) return;
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.health_and_safety, color: Color(0xFF00B894)),
            SizedBox(width: 10),
            Text('Suivi Santé Pro'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 3.0.0'),
            SizedBox(height: 8),
            Text(
              'Application de suivi santé multi-rôles. '
              'Espace médecin pour gérer vos patients, '
              'rendez-vous et prescriptions.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFD63031)),
            SizedBox(width: 10),
            Text('Déconnexion'),
          ],
        ),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
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
            child: const Text('Déconnecter'),
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

// ==================== MODEL PAGE ====================
class _DoctorPage {
  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;

  const _DoctorPage({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.color,
  });
}