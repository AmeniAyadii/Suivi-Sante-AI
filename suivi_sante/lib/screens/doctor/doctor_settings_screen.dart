import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/doctor/settings_service.dart';
import '../login_screen.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

class DoctorSettingsScreen extends StatefulWidget {
  final User? user; // Optionnel : pour afficher le profil en haut
  const DoctorSettingsScreen({super.key, this.user});

  @override
  State<DoctorSettingsScreen> createState() => _DoctorSettingsScreenState();
}

class _DoctorSettingsScreenState extends State<DoctorSettingsScreen> {
  final _settingsService = SettingsService();
  final ScrollController _scrollController = ScrollController();

  // ==================== ÉTATS DES PARAMÈTRES ====================
  bool _isDarkMode = false;
  bool _notifAppointments = true;
  bool _notifPatients = true;
  bool _notifMessages = true;
  bool _biometricLogin = false;
  bool _isLoading = false;
  bool _hasChanges = false;

  String _selectedLanguage = 'fr'; // fr, en, ar
  double _textScale = 1.0; // 0.8 à 1.3

  // ==================== LIFECYCLE ====================
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ==================== CHARGEMENT ====================
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('doctor_dark_mode') ?? false;
      _notifAppointments = prefs.getBool('doctor_notif_appt') ?? true;
      _notifPatients = prefs.getBool('doctor_notif_patients') ?? true;
      _notifMessages = prefs.getBool('doctor_notif_messages') ?? true;
      _biometricLogin = prefs.getBool('doctor_biometric') ?? false;
      _selectedLanguage = prefs.getString('doctor_language') ?? 'fr';
      _textScale = prefs.getDouble('doctor_text_scale') ?? 1.0;
      _hasChanges = false;
    });
  }

  // ==================== SAUVEGARDE ====================
  Future<void> _saveAllSettings() async {
    setState(() => _isLoading = true);

    // 1. Sauvegarde locale
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('doctor_dark_mode', _isDarkMode);
    await prefs.setBool('doctor_notif_appt', _notifAppointments);
    await prefs.setBool('doctor_notif_patients', _notifPatients);
    await prefs.setBool('doctor_notif_messages', _notifMessages);
    await prefs.setBool('doctor_biometric', _biometricLogin);
    await prefs.setString('doctor_language', _selectedLanguage);
    await prefs.setDouble('doctor_text_scale', _textScale);

    // 2. Sauvegarde Backend (API)
    await _settingsService.updateSettings({
      'dark_mode': _isDarkMode,
      'notif_appointments': _notifAppointments,
      'notif_patients': _notifPatients,
      'notif_messages': _notifMessages,
      'biometric_login': _biometricLogin,
      'language': _selectedLanguage,
      'text_scale': _textScale,
    });

    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasChanges = false;
      });
      _showSuccessSnack('Paramètres enregistrés avec succès !');
    }
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  // ==================== DÉCONNEXION ====================
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.red),
            const SizedBox(width: 12),
            Text('Déconnexion', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment vous déconnecter de votre compte médecin ?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Déconnecter', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService().logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Paramètres',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      // FAB (Bouton flottant) de sauvegarde
      floatingActionButton: _hasChanges
          ? FloatingActionButton.extended(
              onPressed: _saveAllSettings,
              backgroundColor: const Color(0xFF00B894),
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: Text(
                'Enregistrer',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack)
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
              children: [
                // ---------------- CARTE PROFIL ----------------
                _buildProfileCard(isDark).animate().fadeIn().slideY(begin: -0.1),
                const SizedBox(height: 30),

                // ---------------- PRÉFÉRENCES GÉNÉRALES ----------------
                _buildSectionTitle('Préférences générales', isDark),
                _buildSettingsGroup(isDark, [
                  _buildThemeSelector(isDark),
                  _buildDivider(isDark),
                  _buildLanguageSelector(isDark),
                  _buildDivider(isDark),
                  _buildTextScaleSlider(isDark),
                ]).animate().fadeIn(delay: 100.ms).slideX(),

                const SizedBox(height: 24),

                // ---------------- NOTIFICATIONS ----------------
                _buildSectionTitle('Notifications', isDark),
                _buildSettingsGroup(isDark, [
                  _buildSwitchTile(
                    isDark: isDark,
                    icon: Icons.calendar_month_rounded,
                    iconColor: const Color(0xFF0984E3),
                    title: 'Rappels de rendez-vous',
                    subtitle: 'Alerte avant un RDV',
                    value: _notifAppointments,
                    onChanged: (v) {
                      setState(() => _notifAppointments = v);
                      _markChanged();
                    },
                  ),
                  _buildDivider(isDark),
                  _buildSwitchTile(
                    isDark: isDark,
                    icon: Icons.people_rounded,
                    iconColor: const Color(0xFF00B894),
                    title: 'Alertes nouveaux patients',
                    subtitle: 'Quand un patient s\'inscrit',
                    value: _notifPatients,
                    onChanged: (v) {
                      setState(() => _notifPatients = v);
                      _markChanged();
                    },
                  ),
                  _buildDivider(isDark),
                  _buildSwitchTile(
                    isDark: isDark,
                    icon: Icons.message_rounded,
                    iconColor: const Color(0xFF6C5CE7),
                    title: 'Messages & Chatbot',
                    subtitle: 'Nouvelles demandes de consultation',
                    value: _notifMessages,
                    onChanged: (v) {
                      setState(() => _notifMessages = v);
                      _markChanged();
                    },
                  ),
                ]).animate().fadeIn(delay: 200.ms).slideX(),

                const SizedBox(height: 24),

                // ---------------- SÉCURITÉ ----------------
                _buildSectionTitle('Sécurité & Confidentialité', isDark),
                _buildSettingsGroup(isDark, [
                  _buildSwitchTile(
                    isDark: isDark,
                    icon: Icons.fingerprint_rounded,
                    iconColor: Colors.orange,
                    title: 'Connexion biométrique',
                    subtitle: 'Face ID / Empreinte digitale',
                    value: _biometricLogin,
                    onChanged: (v) {
                      setState(() => _biometricLogin = v);
                      _markChanged();
                    },
                  ),
                  _buildDivider(isDark),
                  _buildActionTile(
                    isDark: isDark,
                    icon: Icons.lock_reset_rounded,
                    iconColor: Colors.redAccent,
                    title: 'Changer le mot de passe',
                    subtitle: 'Mettre à jour vos identifiants',
                    onTap: () => _showComingSoon('Changement de mot de passe'),
                  ),
                  _buildDivider(isDark),
                  _buildActionTile(
                    isDark: isDark,
                    icon: Icons.privacy_tip_rounded,
                    iconColor: Colors.teal,
                    title: 'Confidentialité des données',
                    subtitle: 'Gérer mes données de santé',
                    onTap: () => _showComingSoon('Gestion de la confidentialité'),
                  ),
                ]).animate().fadeIn(delay: 300.ms).slideX(),

                const SizedBox(height: 24),

                // ---------------- ASSISTANCE ----------------
                _buildSectionTitle('Assistance', isDark),
                _buildSettingsGroup(isDark, [
                  _buildActionTile(
                    isDark: isDark,
                    icon: Icons.help_outline_rounded,
                    iconColor: Colors.purple,
                    title: 'Centre d\'aide (FAQ)',
                    subtitle: 'Questions fréquentes',
                    onTap: () => _showComingSoon('Centre d\'aide'),
                  ),
                  _buildDivider(isDark),
                  _buildActionTile(
                    isDark: isDark,
                    icon: Icons.support_agent_rounded,
                    iconColor: Colors.blue,
                    title: 'Contacter le support',
                    subtitle: 'Besoin d\'assistance technique ?',
                    onTap: () => _showComingSoon('Contact support'),
                  ),
                  _buildDivider(isDark),
                  _buildActionTile(
                    isDark: isDark,
                    icon: Icons.info_outline_rounded,
                    iconColor: Colors.grey,
                    title: 'À propos de Suivi Santé Pro',
                    subtitle: 'Version 3.0.0',
                    onTap: () => _showAboutDialog(isDark),
                  ),
                ]).animate().fadeIn(delay: 400.ms).slideX(),

                const SizedBox(height: 40),

                // ---------------- DÉCONNEXION ----------------
                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    label: Text(
                      'Se déconnecter',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.withOpacity(0.5), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Colors.red.withOpacity(0.05),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Suivi Santé Pro • v3.0.0',
                    style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
    );
  }

  // ==================== WIDGETS DE SECTION ====================
  Widget _buildProfileCard(bool isDark) {
    final name = widget.user?.nom ?? 'Docteur';
    final specialite = widget.user?.specialite ?? 'Médecin';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'D';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2D3436), const Color(0xFF1E1E1E)]
              : [const Color(0xFF00B894), const Color(0xFF55EFC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B894).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white.withOpacity(0.25),
            child: Text(
              initial,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  specialite,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _showComingSoon('Modification du profil'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Modifier le profil',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      indent: 60,
    );
  }

  // ==================== WIDGETS INTERNES ====================
  Widget _buildSwitchTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF2D3436),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: iconColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF2D3436),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.palette_rounded, color: Colors.indigo, size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                'Thème de l\'application',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildThemeOption('Clair', !_isDarkMode, () {
                setState(() => _isDarkMode = false);
                _markChanged();
              }, isDark),
              const SizedBox(width: 10),
              _buildThemeOption('Sombre', _isDarkMode, () {
                setState(() => _isDarkMode = true);
                _markChanged();
              }, isDark),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildThemeOption(String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.indigo
                : (isDark ? Colors.grey[800] : Colors.grey[100]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.indigo : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.language_rounded, color: Colors.blue, size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                'Langue',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLangOption('FR', 'fr', isDark),
              const SizedBox(width: 8),
              _buildLangOption('AR', 'ar', isDark),
              const SizedBox(width: 8),
              _buildLangOption('EN', 'en', isDark),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLangOption(String label, String code, bool isDark) {
    final isSelected = _selectedLanguage == code;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedLanguage = code);
          _markChanged();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue
                : (isDark ? Colors.grey[800] : Colors.grey[100]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextScaleSlider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.format_size_rounded, color: Colors.orange, size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                'Taille du texte',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
              ),
              const Spacer(),
              Text(
                '${(_textScale * 100).toInt()}%',
                style: GoogleFonts.inter(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _textScale,
            min: 0.8,
            max: 1.3,
            divisions: 5,
            activeColor: Colors.orange,
            inactiveColor: isDark ? Colors.grey[700] : Colors.orange.withOpacity(0.2),
            onChanged: (val) {
              setState(() => _textScale = val);
              _markChanged();
            },
          ),
        ],
      ),
    );
  }

  // ==================== DIALOGUES & SNACKBARS ====================
  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(msg, style: GoogleFonts.inter(color: Colors.white)),
          ],
        ),
        backgroundColor: const Color(0xFF00B894),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature : Fonctionnalité en cours de développement', style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showAboutDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.health_and_safety, color: Color(0xFF00B894), size: 30),
            const SizedBox(width: 12),
            Text('Suivi Santé Pro', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 3.0.0', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Application de suivi santé multi-rôles.\nEspace médecin pour gérer vos patients, rendez-vous et prescriptions en toute sécurité.',
              style: GoogleFonts.inter(fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Fermer', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}