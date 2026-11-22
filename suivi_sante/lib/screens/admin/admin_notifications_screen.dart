// lib/screens/admin/admin_notifications_screen.dart
// Version 3.0.0 — Design Premium, Dark Mode, Animations

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          _buildTabBar(isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _SendNotificationTab(),
                _NotificationsHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor:
            isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.send_rounded, size: 18),
            text: 'Envoyer',
          ),
          Tab(
            icon: Icon(Icons.history_rounded, size: 18),
            text: 'Historique',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB 1 : ENVOYER
// ═══════════════════════════════════════════════════════════════
class _SendNotificationTab extends StatefulWidget {
  const _SendNotificationTab();

  @override
  State<_SendNotificationTab> createState() => _SendNotificationTabState();
}

class _SendNotificationTabState extends State<_SendNotificationTab> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _messageController = TextEditingController();
  final _deepLinkController = TextEditingController();

  String _cible = 'all';
  String? _roleSelectionne;
  int? _userSelectionne;

  bool _isSending = false;
  List<dynamic> _users = [];
  bool _loadingUsers = false;

  final List<Map<String, dynamic>> _roles = [
    {'key': 'patient', 'label': 'Patients', 'icon': Icons.person_rounded, 'color': const Color(0xFF0984E3)},
    {'key': 'doctor', 'label': 'Médecins', 'icon': Icons.medical_services_rounded, 'color': const Color(0xFF00B894)},
    {'key': 'admin', 'label': 'Admins', 'icon': Icons.admin_panel_settings_rounded, 'color': const Color(0xFF6C63FF)},
  ];

  final List<Map<String, String>> _deepLinkSuggestions = [
    {'label': 'Accueil', 'value': '/dashboard'},
    {'label': 'Notifications', 'value': '/notifications'},
    {'label': 'Rendez-vous', 'value': '/rendezvous'},
    {'label': 'Médicaments', 'value': '/medicaments'},
    {'label': 'Profil', 'value': '/profile'},
    {'label': 'Chatbot', 'value': '/chatbot'},
  ];

  @override
  void dispose() {
    _titreController.dispose();
    _messageController.dispose();
    _deepLinkController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (_users.isNotEmpty) return;
    setState(() => _loadingUsers = true);
    try {
      final users = await AdminService().getUsersForSelector();
      if (mounted) {
        setState(() {
          _users = users;
          _loadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingUsers = false);
        _showSnack('Erreur : $e', isError: true);
      }
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    if (_cible == 'role' && _roleSelectionne == null) {
      _showSnack('Veuillez sélectionner un rôle', isWarning: true);
      return;
    }
    if (_cible == 'user' && _userSelectionne == null) {
      _showSnack('Veuillez sélectionner un utilisateur', isWarning: true);
      return;
    }

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
                color: AppTheme.primaryLight.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.send_rounded,
                  color: AppTheme.primaryLight, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Confirmer l\'envoi',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textDark : AppTheme.textLight,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfirmLine('Destinataires', _cibleLabel(), isDark),
            const SizedBox(height: 8),
            _buildConfirmLine('Titre', _titreController.text, isDark),
            const SizedBox(height: 8),
            _buildConfirmLine('Message', _messageController.text, isDark),
          ],
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
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: Text(
              'Envoyer',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSending = true);

    try {
      final result = await AdminService().sendNotification(
        titre: _titreController.text.trim(),
        message: _messageController.text.trim(),
        cible: _cible,
        cibleValeur: _cible == 'role'
            ? _roleSelectionne
            : _cible == 'user'
                ? _userSelectionne?.toString()
                : null,
        deepLink: _deepLinkController.text.trim().isEmpty
            ? null
            : _deepLinkController.text.trim(),
      );

      if (!mounted) return;

      final notif = result['notification'];
      final nbEnvoyes = notif?['nb_envoyes'] ?? 0;
      final nbEchecs = notif?['nb_echecs'] ?? 0;

      _showSuccessDialog(nbEnvoyes, nbEchecs, isDark);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erreur : $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSuccessDialog(int envoyes, int echecs, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppTheme.success, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Notification envoyée !',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textDark : AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatPill(envoyes.toString(), 'Envoyées', AppTheme.success),
                if (echecs > 0) ...[
                  const SizedBox(width: 8),
                  _buildStatPill(echecs.toString(), 'Échecs', AppTheme.error),
                ],
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetForm();
            },
            child: Text(
              'Terminé',
              style: GoogleFonts.inter(
                color: AppTheme.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmLine(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$label :',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _resetForm() {
    _titreController.clear();
    _messageController.clear();
    _deepLinkController.clear();
    setState(() {
      _cible = 'all';
      _roleSelectionne = null;
      _userSelectionne = null;
    });
  }

  String _cibleLabel() {
    switch (_cible) {
      case 'role':
        return _roles
                .firstWhere((r) => r['key'] == _roleSelectionne,
                    orElse: () => {'label': '—'})['label'] ??
            '—';
      case 'user':
        final u = _users.firstWhere(
          (u) => u['id'] == _userSelectionne,
          orElse: () => null,
        );
        return u != null ? '${u['nom']} (${u['email']})' : '—';
      default:
        return 'Tous les utilisateurs';
    }
  }

  void _showSnack(String message,
      {bool isError = false, bool isWarning = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : isWarning
                      ? Icons.warning_amber_rounded
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
        backgroundColor: isError
            ? AppTheme.error
            : isWarning
                ? AppTheme.warning
                : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildInfoBanner(isDark),
              const SizedBox(height: 20),
              _buildSectionLabel('Contenu', isDark),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titreController,
                maxLength: 150,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? AppTheme.textDark : AppTheme.textLight,
                ),
                decoration: _inputDecoration(
                  label: 'Titre',
                  hint: 'Ex: Nouvelle fonctionnalité disponible',
                  icon: Icons.title_rounded,
                  isDark: isDark,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Titre requis'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                maxLength: 1000,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? AppTheme.textDark : AppTheme.textLight,
                ),
                decoration: _inputDecoration(
                  label: 'Message',
                  hint: 'Ex: Découvrez la nouvelle fonctionnalité...',
                  icon: Icons.message_rounded,
                  isDark: isDark,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Message requis'
                    : null,
              ),
              const SizedBox(height: 20),
              _buildSectionLabel('Ciblage', isDark),
              const SizedBox(height: 10),
              _buildCibleSelector(isDark),
              if (_cible == 'role') ...[
                const SizedBox(height: 16),
                _buildSectionLabel('Rôle ciblé', isDark),
                const SizedBox(height: 10),
                _buildRoleChips(isDark),
              ],
              if (_cible == 'user') ...[
                const SizedBox(height: 16),
                _buildSectionLabel('Utilisateur ciblé', isDark),
                const SizedBox(height: 10),
                _buildUserSelector(isDark),
              ],
              const SizedBox(height: 20),
              _buildSectionLabel('Deep link (optionnel)', isDark),
              const SizedBox(height: 10),
              TextFormField(
                controller: _deepLinkController,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? AppTheme.textDark : AppTheme.textLight,
                ),
                decoration: _inputDecoration(
                  label: 'Lien profond',
                  hint: 'Ex: /rendezvous',
                  icon: Icons.link_rounded,
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _deepLinkSuggestions.map((s) {
                  return ActionChip(
                    label: Text(
                      s['label']!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                    backgroundColor: isDark
                        ? AppTheme.surfaceDark
                        : AppTheme.surfaceLight,
                    side: BorderSide(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                    ),
                    onPressed: () {
                      _deepLinkController.text = s['value']!;
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _send,
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _isSending
                        ? 'Envoi en cours...'
                        : 'Envoyer la notification',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryLight.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppTheme.primaryLight, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Les notifications sont envoyées instantanément aux appareils des utilisateurs ciblés.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.grey.shade500 : Colors.grey,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildCibleSelector(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _cibleTile(
            value: 'all',
            icon: Icons.public_rounded,
            color: const Color(0xFF6C63FF),
            title: 'Tous les utilisateurs',
            subtitle: 'Envoyer à tout le monde',
            isDark: isDark,
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
          _cibleTile(
            value: 'role',
            icon: Icons.group_rounded,
            color: const Color(0xFF0984E3),
            title: 'Par rôle',
            subtitle: 'Patients, médecins ou admins',
            isDark: isDark,
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
          _cibleTile(
            value: 'user',
            icon: Icons.person_rounded,
            color: const Color(0xFF00B894),
            title: 'Utilisateur spécifique',
            subtitle: 'Une seule personne',
            onTap: _loadUsers,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _cibleTile({
    required String value,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final selected = _cible == value;
    return InkWell(
      onTap: () {
        setState(() => _cible = value);
        onTap?.call();
      },
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(selected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.w600,
                      color: selected
                          ? color
                          : (isDark
                              ? AppTheme.textDark
                              : AppTheme.textLight),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _cible,
              onChanged: (v) {
                setState(() => _cible = v!);
                onTap?.call();
              },
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChips(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _roles.map((r) {
        final selected = _roleSelectionne == r['key'];
        final color = r['color'] as Color;
        return GestureDetector(
          onTap: () => setState(() => _roleSelectionne = r['key'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? color.withOpacity(0.15)
                  : (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? color : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  r['icon'] as IconData,
                  size: 16,
                  color: selected
                      ? color
                      : (isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight),
                ),
                const SizedBox(width: 8),
                Text(
                  r['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.w500,
                    color: selected
                        ? color
                        : (isDark ? AppTheme.textDark : AppTheme.textLight),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUserSelector(bool isDark) {
    if (_loadingUsers) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_users.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppTheme.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Aucun utilisateur chargé',
                style: GoogleFonts.inter(
                  color: isDark ? AppTheme.textDark : AppTheme.textLight,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(
              onPressed: _loadUsers,
              child: Text(
                'Charger',
                style: GoogleFonts.inter(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _userSelectionne,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Choisir un utilisateur',
        icon: Icons.person_search_rounded,
        isDark: isDark,
      ),
      dropdownColor: isDark ? AppTheme.surfaceDark : Colors.white,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: isDark ? AppTheme.textDark : AppTheme.textLight,
      ),
      items: _users.map<DropdownMenuItem<int>>((u) {
        return DropdownMenuItem<int>(
          value: u['id'],
          child: Text(
            '${u['nom']} • ${u['role']}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (v) => setState(() => _userSelectionne = v),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    required IconData icon,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.inter(
        fontSize: 13,
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 12,
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
      ),
      prefixIcon: Icon(
        icon,
        size: 20,
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
      ),
      filled: true,
      fillColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppTheme.primaryLight,
          width: 2,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB 2 : HISTORIQUE
// ═══════════════════════════════════════════════════════════════
class _NotificationsHistoryTab extends StatefulWidget {
  const _NotificationsHistoryTab();

  @override
  State<_NotificationsHistoryTab> createState() =>
      _NotificationsHistoryTabState();
}

class _NotificationsHistoryTabState extends State<_NotificationsHistoryTab> {
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<Map<String, dynamic>> _notifsFuture;
  final TextEditingController _searchController = TextEditingController();

  String _search = '';
  String _statutFilter = 'all';
  int? _deletingId;

  final List<Map<String, dynamic>> _filters = [
    {'key': 'all', 'label': 'Toutes', 'color': const Color(0xFF6C63FF)},
    {'key': 'envoye', 'label': 'Envoyées', 'color': const Color(0xFF00B894)},
    {'key': 'partiel', 'label': 'Partielles', 'color': const Color(0xFFFDCB6E)},
    {'key': 'echec', 'label': 'Échecs', 'color': const Color(0xFFD63031)},
  ];

  @override
  void initState() {
    super.initState();
    _statsFuture = AdminService().getNotificationsStats();
    _notifsFuture = _load();
    _searchController.addListener(() {
      if (_searchController.text != _search) {
        _search = _searchController.text.trim();
        _reload();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() {
    return AdminService().getNotifications(
      statut: _statutFilter == 'all' ? null : _statutFilter,
      search: _search.isEmpty ? null : _search,
    );
  }

  void _reload() => setState(() => _notifsFuture = _load());

  Future<void> _refreshAll() async {
    setState(() {
      _statsFuture = AdminService().getNotificationsStats();
      _notifsFuture = _load();
    });
    await Future.wait([_statsFuture, _notifsFuture]);
  }

  Future<void> _delete(int id) async {
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
                'Supprimer',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textDark : AppTheme.textLight,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Supprimer cette notification de l\'historique ? Les utilisateurs l\'ayant reçue ne seront pas affectés.',
          style: GoogleFonts.inter(
            fontSize: 13,
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
      await AdminService().deleteNotification(id);
      _refreshAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  Color _statutColor(String? statut) {
    switch (statut) {
      case 'envoye':
        return const Color(0xFF00B894);
      case 'partiel':
        return const Color(0xFFFDCB6E);
      case 'echec':
        return const Color(0xFFD63031);
      default:
        return Colors.grey;
    }
  }

  String _statutLabel(String? statut) {
    switch (statut) {
      case 'envoye':
        return 'Envoyée';
      case 'partiel':
        return 'Partielle';
      case 'echec':
        return 'Échec';
      case 'en_attente':
        return 'En attente';
      default:
        return statut ?? '—';
    }
  }

  IconData _statutIcon(String? statut) {
    switch (statut) {
      case 'envoye':
        return Icons.check_circle_rounded;
      case 'partiel':
        return Icons.warning_rounded;
      case 'echec':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  IconData _cibleIcon(String? cible) {
    switch (cible) {
      case 'all':
        return Icons.public_rounded;
      case 'role':
        return Icons.group_rounded;
      case 'user':
        return Icons.person_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'À l\'instant';
      if (diff.inHours < 1) return '${diff.inMinutes}min';
      if (diff.inDays < 1) return '${diff.inHours}h';
      if (diff.inDays < 30) return '${diff.inDays}j';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _refreshAll,
      color: AppTheme.primaryLight,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: _buildStatsRow(isDark)),
          SliverToBoxAdapter(child: _buildSearchAndFilters(isDark)),
          SliverToBoxAdapter(child: _buildList(isDark)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final s = snapshot.data ?? {};
        final items = [
          _StatData('Total', '${s['total'] ?? 0}',
              Icons.notifications_rounded, const Color(0xFF6C63FF)),
          _StatData('Envoyées', '${s['envoyees'] ?? 0}',
              Icons.check_circle_rounded, const Color(0xFF00B894)),
          _StatData('Partielles', '${s['partielles'] ?? 0}',
              Icons.warning_rounded, const Color(0xFFFDCB6E)),
          _StatData('Échecs', '${s['echecs'] ?? 0}', Icons.cancel_rounded,
              const Color(0xFFD63031)),
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _buildStatChip(items[i], isDark),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(_StatData item, bool isDark) {
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? AppTheme.textDark : AppTheme.textLight,
            ),
            decoration: InputDecoration(
              hintText: 'Rechercher une notification...',
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final isSelected = _statutFilter == f['key'];
                final color = f['color'] as Color;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _statutFilter = f['key'] as String);
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
                      child: Text(
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
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(bool isDark) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _notifsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Erreur : ${snapshot.error}',
                textAlign: TextAlign.center),
          );
        }
        final list = (snapshot.data?['notifications'] as List?) ?? [];
        if (list.isEmpty) {
          return _buildEmpty(isDark);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: list.map((n) => _buildCard(n, isDark)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCard(dynamic n, bool isDark) {
    final statut = n['statut']?.toString();
    final statutColor = _statutColor(statut);
    final isDeleting = _deletingId == n['id'];

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
                    color: statutColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_cibleIcon(n['cible']),
                      size: 18, color: statutColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    n['titre'] ?? '',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? AppTheme.textDark : AppTheme.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statutIcon(statut),
                          size: 11, color: statutColor),
                      const SizedBox(width: 4),
                      Text(
                        _statutLabel(statut),
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
            Text(
              n['message'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _statBadge(
                    '${n['nb_envoyes'] ?? 0}',
                    Icons.check_rounded,
                    AppTheme.success),
                const SizedBox(width: 6),
                if ((n['nb_echecs'] ?? 0) > 0)
                  _statBadge(
                      '${n['nb_echecs']}', Icons.close_rounded, AppTheme.error),
                const Spacer(),
                Text(
                  _formatDate(n['created_at']?.toString()),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
                ),
                const SizedBox(width: 6),
                if (isDeleting)
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else
                  IconButton(
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.error),
                    onPressed: () => _delete(n['id']),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 64,
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune notification',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textDark : Colors.grey.shade600,
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
class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _StatData(this.label, this.value, this.icon, this.color);
}