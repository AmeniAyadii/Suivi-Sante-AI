import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  // ==================== ÉTATS ====================
  bool _isLoading = false;
  String _userName = 'Utilisateur';
  String _userEmail = 'email@exemple.com';
  
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _medicationReminders = true;
  bool _appointmentReminders = true;
  bool _healthTipsEnabled = true;
  bool _dataSyncEnabled = true;
  bool _biometricEnabled = false;
  String _selectedLanguage = 'Français';
  String _selectedTheme = 'Système';
  String _selectedFontSize = 'Moyen';
  double _fontSizeValue = 1.0;

  // ==================== ANIMATIONS ====================
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadSettings();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _animationController.forward();
  }

  // ==================== CHARGEMENT DES PARAMÈTRES ====================
  Future<void> _loadSettings() async {
    try {
      setState(() => _isLoading = true);
      
      try {
        final settingsService = SettingsService();
        final data = await settingsService.getSettings();
        
        if (data != null) {
          final user = data['user'];
          final settings = data['settings'];
          
          setState(() {
            if (user != null) {
              _userName = user['nom'] ?? 'Utilisateur';
              _userEmail = user['email'] ?? 'email@exemple.com';
            }
            
            if (settings != null) {
              _notificationsEnabled = settings['notifications_enabled'] ?? true;
              _medicationReminders = settings['medication_reminders'] ?? true;
              _appointmentReminders = settings['appointment_reminders'] ?? true;
              _healthTipsEnabled = settings['health_tips_enabled'] ?? true;
              _dataSyncEnabled = settings['data_sync_enabled'] ?? true;
              _biometricEnabled = settings['biometric_enabled'] ?? false;
              _selectedLanguage = settings['language'] ?? 'Français';
              _selectedTheme = settings['theme'] ?? 'Système';
              _selectedFontSize = settings['font_size'] ?? 'Moyen';
              _fontSizeValue = settings['font_size_value'] ?? 1.0;
              
              if (_selectedTheme == 'Sombre') {
                _isDarkMode = true;
              } else if (_selectedTheme == 'Clair') {
                _isDarkMode = false;
              }
            }
          });
        }
      } catch (e) {
        print('⚠️ Erreur chargement settings serveur: $e');
        await _loadLocalSettings();
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Erreur chargement: $e');
      setState(() => _isLoading = false);
      await _loadLocalSettings();
    }
  }

  Future<void> _loadLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDarkMode = prefs.getBool('isDarkMode') ?? false;
        _notificationsEnabled = prefs.getBool('notifications') ?? true;
        _medicationReminders = prefs.getBool('medicationReminders') ?? true;
        _appointmentReminders = prefs.getBool('appointmentReminders') ?? true;
        _healthTipsEnabled = prefs.getBool('healthTips') ?? true;
        _dataSyncEnabled = prefs.getBool('dataSync') ?? true;
        _biometricEnabled = prefs.getBool('biometric') ?? false;
        _selectedLanguage = prefs.getString('language') ?? 'Français';
        _selectedTheme = prefs.getString('theme') ?? 'Système';
        _selectedFontSize = prefs.getString('fontSize') ?? 'Moyen';
        _fontSizeValue = prefs.getDouble('fontSizeValue') ?? 1.0;
      });
    } catch (e) {
      // Ignorer
    }
  }

  // ==================== SAUVEGARDE DES PARAMÈTRES ====================
  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
      
      try {
        final settingsService = SettingsService();
        final allSettings = {
          'notifications_enabled': _notificationsEnabled,
          'medication_reminders': _medicationReminders,
          'appointment_reminders': _appointmentReminders,
          'health_tips_enabled': _healthTipsEnabled,
          'data_sync_enabled': _dataSyncEnabled,
          'biometric_enabled': _biometricEnabled,
          'language': _selectedLanguage,
          'theme': _selectedTheme,
          'font_size': _selectedFontSize,
          'font_size_value': _fontSizeValue,
        };
        await settingsService.updateSettings(allSettings);
      } catch (e) {
        print('⚠️ Erreur sauvegarde serveur: $e');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde: $e');
    }
  }

  void _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
    });
    _saveSetting('isDarkMode', value);
    AppTheme.toggleTheme(value);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFF5F7FA),
        appBar: _buildAppBar(),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ===== SECTION PROFIL =====
                _buildProfileSection(),
                const SizedBox(height: 24),

                // ===== SECTION PRÉFÉRENCES =====
                _buildPreferencesSection(),
                const SizedBox(height: 24),

                // ===== SECTION NOTIFICATIONS =====
                _buildNotificationsSection(),
                const SizedBox(height: 24),

                // ===== SECTION SÉCURITÉ =====
                _buildSecuritySection(),
                const SizedBox(height: 24),

                // ===== SECTION DONNÉES =====
                _buildDataSection(),
                const SizedBox(height: 24),

                // ===== SECTION À PROPOS =====
                _buildAboutSection(),
                const SizedBox(height: 24),

                // ===== BOUTON DÉCONNEXION =====
                _buildLogoutButton(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== BARRE D'APPLICATION MODERNISÉE ====================
  PreferredSizeWidget _buildAppBar() {
    final isDark = _isDarkMode;

    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.grey[850]!, Colors.grey[800]!]
                : [const Color(0xFF6C63FF), const Color(0xFF8B83FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black26 : const Color(0xFF6C63FF).withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Bouton retour
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context, 
                        '/dashboard',
                        arguments: {'section': 'stats_grid'},
                      );
                    },
                    tooltip: 'Retour au tableau de bord',
                  ),
                ),
                const SizedBox(width: 12),
                // Titre
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Paramètres',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Gestion de votre compte',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => _showAboutDialog(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== SECTION PROFIL MODERNISÉE ====================
  Widget _buildProfileSection() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userData = authService.userData;
    final userName = userData?['nom'] ?? _userName;
    final userEmail = userData?['email'] ?? _userEmail;
    final isDark = _isDarkMode;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.grey[850]!, Colors.grey[800]!]
              : [const Color(0xFF6C63FF), const Color(0xFF8B83FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : const Color(0xFF6C63FF).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar avec effet de glow
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(userName),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6C63FF),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Vérifié',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
  icon: const Icon(
    Icons.edit_rounded,
    color: Colors.white,
    size: 22,
  ),
  onPressed: _showEditCredentialsDialog, // ✅ Ouvre le dialogue de modification
),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  // ==================== SECTION PRÉFÉRENCES ====================
  Widget _buildPreferencesSection() {
    return _buildSection(
      title: 'Préférences',
      icon: Icons.tune_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF6C63FF), Color(0xFF8B83FF)],
      ),
      children: [
        _buildSettingsTile(
          icon: Icons.language_rounded,
          title: 'Langue',
          subtitle: _selectedLanguage,
          trailing: _buildDropdownButton(
            value: _selectedLanguage,
            items: ['Français', 'English', 'العربية', 'Español'],
            onChanged: (value) {
              setState(() => _selectedLanguage = value!);
              _saveSetting('language', value!);
            },
          ),
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.palette_rounded,
          title: 'Thème',
          subtitle: _selectedTheme,
          trailing: _buildDropdownButton(
            value: _selectedTheme,
            items: ['Clair', 'Sombre', 'Système'],
            onChanged: (value) {
              setState(() => _selectedTheme = value!);
              _saveSetting('theme', value!);
              if (value == 'Sombre') {
                _toggleTheme(true);
              } else if (value == 'Clair') {
                _toggleTheme(false);
              }
            },
          ),
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.text_fields_rounded,
          title: 'Taille du texte',
          subtitle: _selectedFontSize,
          trailing: _buildDropdownButton(
            value: _selectedFontSize,
            items: ['Petit', 'Moyen', 'Grand', 'Très grand'],
            onChanged: (value) {
              setState(() {
                _selectedFontSize = value!;
                switch (value) {
                  case 'Petit':
                    _fontSizeValue = 0.8;
                    break;
                  case 'Moyen':
                    _fontSizeValue = 1.0;
                    break;
                  case 'Grand':
                    _fontSizeValue = 1.2;
                    break;
                  case 'Très grand':
                    _fontSizeValue = 1.4;
                    break;
                }
              });
              _saveSetting('fontSize', _selectedFontSize);
              _saveSetting('fontSizeValue', _fontSizeValue);
            },
          ),
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.devices_rounded,
          title: 'Appareils connectés',
          subtitle: '2 appareils',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '2',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF6C63FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== SECTION NOTIFICATIONS ====================
  Widget _buildNotificationsSection() {
    return _buildSection(
      title: 'Notifications',
      icon: Icons.notifications_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF00B4D8), Color(0xFF48CAE4)],
      ),
      children: [
        _buildSettingsTile(
          icon: Icons.notifications_active_rounded,
          title: 'Activer les notifications',
          subtitle: 'Recevoir des alertes sur votre santé',
          trailing: _buildSwitch(
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _saveSetting('notifications', value);
            },
          ),
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.medication_rounded,
          title: 'Rappels de médicaments',
          subtitle: 'Notifications pour les prises',
          trailing: _buildSwitch(
            value: _medicationReminders,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() => _medicationReminders = value);
                    _saveSetting('medicationReminders', value);
                  }
                : null,
          ),
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.calendar_month_rounded,
          title: 'Rappels de rendez-vous',
          subtitle: 'Notifications avant vos RDV',
          trailing: _buildSwitch(
            value: _appointmentReminders,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() => _appointmentReminders = value);
                    _saveSetting('appointmentReminders', value);
                  }
                : null,
          ),
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.health_and_safety_rounded,
          title: 'Conseils santé',
          subtitle: 'Recevoir des conseils personnalisés',
          trailing: _buildSwitch(
            value: _healthTipsEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() => _healthTipsEnabled = value);
                    _saveSetting('healthTips', value);
                  }
                : null,
          ),
        ),
      ],
    );
  }

  // ==================== SECTION SÉCURITÉ ====================
  Widget _buildSecuritySection() {
    return _buildSection(
      title: 'Sécurité',
      icon: Icons.security_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFFE63946), Color(0xFFF08080)],
      ),
      children: [
        _buildSettingsTile(
          icon: Icons.fingerprint_rounded,
          title: 'Authentification biométrique',
          subtitle: 'Utiliser votre empreinte ou Face ID',
          trailing: _buildSwitch(
            value: _biometricEnabled,
            onChanged: (value) async {
              if (value) {
                final result = await _showBiometricDialog();
                if (result) {
                  setState(() => _biometricEnabled = value);
                  _saveSetting('biometric', value);
                }
              } else {
                setState(() => _biometricEnabled = value);
                _saveSetting('biometric', value);
              }
            },
          ),
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.lock_rounded,
          title: 'Changer le mot de passe',
          subtitle: 'Mettre à jour votre mot de passe',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Modifier',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.shield_rounded,
          title: 'Confidentialité',
          subtitle: 'Gérer vos données personnelles',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00B4D8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Voir',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF00B4D8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.devices_rounded,
          title: 'Appareils connectés',
          subtitle: 'Gérer vos sessions actives',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE63946).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '2 actifs',
              style: TextStyle(
                fontSize: 11,
                color: const Color(0xFFE63946),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== SECTION DONNÉES ====================
  Widget _buildDataSection() {
    return _buildSection(
      title: 'Données',
      icon: Icons.data_usage_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
      ),
      children: [
        _buildSettingsTile(
          icon: Icons.sync_rounded,
          title: 'Synchronisation automatique',
          subtitle: 'Synchroniser les données en temps réel',
          trailing: _buildSwitch(
            value: _dataSyncEnabled,
            onChanged: (value) {
              setState(() => _dataSyncEnabled = value);
              _saveSetting('dataSync', value);
            },
          ),
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.cloud_download_rounded,
          title: 'Exporter les données',
          subtitle: 'Télécharger vos données médicales',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2D6A4F).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Export',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF2D6A4F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.delete_rounded,
          title: 'Supprimer les données',
          subtitle: 'Effacer toutes vos données',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE63946).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Effacer',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFE63946),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== SECTION À PROPOS ====================
  Widget _buildAboutSection() {
    return _buildSection(
      title: 'À propos',
      icon: Icons.info_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF6C63FF), Color(0xFF8B83FF)],
      ),
      children: [
        _buildSettingsTile(
          icon: Icons.apps_rounded,
          title: 'Version',
          subtitle: '3.0.0 (Build 2026)',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 12,
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 4),
                Text(
                  'Dernière version',
                  style: TextStyle(
                    fontSize: 10,
                    color: const Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.privacy_tip_rounded,
          title: 'Politique de confidentialité',
          subtitle: 'Comment nous protégeons vos données',
          trailing: IconButton(
            icon: Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
            ),
            onPressed: () => _launchURL('https://example.com/privacy'),
          ),
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.description_rounded,
          title: 'Conditions d\'utilisation',
          subtitle: 'CGU de l\'application',
          trailing: IconButton(
            icon: Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
            ),
            onPressed: () => _launchURL('https://example.com/terms'),
          ),
        ),
        _buildDivider(),
        _buildSettingsTile(
          icon: Icons.feedback_rounded,
          title: 'Nous contacter',
          subtitle: 'Support technique et suggestions',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Contacter',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== BOUTON DÉCONNEXION ====================
  Widget _buildLogoutButton() {
    final isDark = _isDarkMode;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.1),
            Colors.red.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade400,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Déconnexion',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== COMPOSANTS RÉUTILISABLES ====================

  Widget _buildSection({
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required List<Widget> children,
  }) {
    final isDark = _isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[100]!,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    final isDark = _isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.grey[800]!, Colors.grey[700]!]
                    : [const Color(0xFFF0EFFF), const Color(0xFFE8E5FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isDark ? Colors.grey[400] : const Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    final isDark = _isDarkMode;
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: isDark ? Colors.grey[800] : Colors.grey[100],
    );
  }

  Widget _buildSwitch({
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF6C63FF),
      activeTrackColor: const Color(0xFF6C63FF).withOpacity(0.3),
      inactiveThumbColor: _isDarkMode ? Colors.grey[400] : Colors.grey[300],
      inactiveTrackColor: _isDarkMode ? Colors.grey[700] : Colors.grey[200],
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildDropdownButton<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    final isDark = _isDarkMode;

    return DropdownButton<T>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            item.toString(),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      isDense: true,
      underline: const SizedBox.shrink(),
      icon: Icon(
        Icons.arrow_drop_down_rounded,
        color: isDark ? Colors.grey[400] : const Color(0xFF6C63FF),
      ),
      dropdownColor: isDark ? Colors.grey[850] : Colors.white,
      borderRadius: BorderRadius.circular(12),
    );
  }

  // ==================== DIALOGUES ====================

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Colors.red.shade400,
            ),
            const SizedBox(width: 12),
            const Text('Déconnexion'),
          ],
        ),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter de votre compte ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              await authService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showBiometricDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.fingerprint_rounded,
                  color: const Color(0xFF6C63FF),
                ),
                const SizedBox(width: 12),
                const Text('Authentification biométrique'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.fingerprint_rounded,
                  size: 80,
                  color: Color(0xFF6C63FF),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Placez votre doigt sur le capteur',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'ou utilisez Face ID',
                  style: TextStyle(
                    fontSize: 13,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor:
                      _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Vérifier'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Exporter les données'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choisissez le format d\'exportation :',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildExportOption(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'PDF',
                  color: const Color(0xFFE63946),
                ),
                _buildExportOption(
                  icon: Icons.insert_drive_file_rounded,
                  label: 'CSV',
                  color: const Color(0xFF2D6A4F),
                ),
                _buildExportOption(
                  icon: Icons.cloud_upload_rounded,
                  label: 'Cloud',
                  color: const Color(0xFF6C63FF),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessDialog('Exportation en cours...');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Exporter'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade400,
            ),
            const SizedBox(width: 12),
            const Text('Supprimer les données'),
          ],
        ),
        content: const Text(
          'Cette action est irréversible. Toutes vos données médicales seront définitivement supprimées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessDialog('Données supprimées avec succès');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Nous contacter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email_rounded, color: Color(0xFF6C63FF)),
              title: const Text('support@santesuite.com'),
              onTap: () {
                Navigator.pop(context);
                _launchURL('mailto:support@santesuite.com');
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_rounded, color: Color(0xFF2D6A4F)),
              title: const Text('+33 1 23 45 67 89'),
              onTap: () {
                Navigator.pop(context);
                _launchURL('tel:+33123456789');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_rounded, color: Color(0xFF00B4D8)),
              title: const Text('Chat en direct'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/chatbot');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Colors.green.shade400,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('À propos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF8B83FF)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.health_and_safety_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Suivi Santé AI',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Version 3.0.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Application de suivi santé avec intelligence artificielle',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '© 2026 Tous droits réservés',
              style: TextStyle(
                fontSize: 12,
                color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // ==================== UTILITAIRES ====================

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Impossible d\'ouvrir $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir le lien: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEditCredentialsDialog() async {
  final authService = Provider.of<AuthService>(context, listen: false);
  
  // ✅ 1. Récupérer l'email de manière fiable (mémoire ou SharedPreferences)
  Map<String, dynamic>? userData = authService.userData;
  userData ??= await authService.getUserData(); // Si null en mémoire, on lit le stockage
  
  final emailActuel = userData?['email'] ?? '';

  if (!mounted) return;

  final emailController = TextEditingController(text: emailActuel);
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  bool isPasswordVisible = false;
  bool isLoading = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setStateDialog) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Modifier mes identifiants'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Champ Email
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Nouvel email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),
                
                // Section mot de passe
                const Text(
                  'Changer de mot de passe',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Laissez vide si vous ne voulez pas le modifier.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                
                // Champ Ancien Mot de passe
                TextField(
                  controller: currentPasswordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe actuel',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setStateDialog(() => isPasswordVisible = !isPasswordVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Champ Nouveau Mot de passe
                TextField(
                  controller: newPasswordController,
                  obscureText: !isPasswordVisible,
                  decoration: const InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Validation basique côté client
                      if (newPasswordController.text.isNotEmpty && currentPasswordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Veuillez saisir votre mot de passe actuel'), backgroundColor: Colors.orange),
                        );
                        return;
                      }

                      setStateDialog(() => isLoading = true);
                      try {
                        await authService.updateCredentials(
                          email: emailController.text.trim(),
                          currentPassword: currentPasswordController.text,
                          newPassword: newPasswordController.text,
                        );
                        if (context.mounted) {
                          Navigator.pop(context); // Ferme le dialogue
                          _showSuccessDialog('Identifiants mis à jour avec succès !');
                          setState(() {}); // Rafraîchit l'écran des paramètres
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        setStateDialog(() => isLoading = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
              ),
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Enregistrer'),
            ),
          ],
        );
      },
    ),
  );
}
}