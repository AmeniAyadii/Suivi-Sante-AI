// lib/screens/admin/admin_settings_screen.dart
// Version 1.0.0 — Design Premium, Dark Mode, Animations

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_settings_service.dart';
import '../../theme/app_theme.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen>
    with TickerProviderStateMixin {
  final AdminSettingsService _service = AdminSettingsService();

  Map<String, dynamic>? _settings;
  bool _isLoading = true;
  String? _error;
  bool _isSaving = false;
  bool _hasChanges = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadSettings();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _service.getSettings();
      if (!mounted) return;
      setState(() {
        _settings = data;
        _isLoading = false;
        _hasChanges = false;
      });
      _animController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_settings == null) return;

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
              child: const Icon(Icons.save_rounded,
                  color: AppTheme.primaryLight, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Enregistrer les paramètres',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textDark : AppTheme.textLight,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Voulez-vous appliquer les modifications ?',
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
              backgroundColor: AppTheme.primaryLight,
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

    setState(() => _isSaving = true);

    try {
      final allSettings = <Map<String, dynamic>>[];
      for (final group in _settings!.values) {
        for (final s in group as List) {
          allSettings.add({'key': s['key'], 'value': s['value']});
        }
      }
      await _service.updateSettings(allSettings);
      if (!mounted) return;
      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });
      _showSnack('Paramètres enregistrés', isSuccess: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('Erreur : $e', isError: true);
    }
  }

  Future<void> _reset() async {
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
                color: AppTheme.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.restart_alt_rounded,
                  color: AppTheme.warning, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Réinitialiser',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textDark : AppTheme.textLight,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Tous les paramètres seront remis à leurs valeurs par défaut. Confirmer ?',
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
              backgroundColor: AppTheme.warning,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Réinitialiser',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.resetSettings();
      await _loadSettings();
      _showSnack('Paramètres réinitialisés', isSuccess: true);
    } catch (e) {
      _showSnack('Erreur : $e', isError: true);
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

  void _updateSetting(String groupKey, String settingKey, dynamic newValue) {
    final group = _settings![groupKey] as List;
    final index = group.indexWhere((s) => s['key'] == settingKey);
    if (index != -1) {
      setState(() {
        group[index]['value'] = newValue;
        _hasChanges = true;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildError(isDark);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadSettings,
              color: AppTheme.primaryLight,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHeaderBanner(isDark),
                    const SizedBox(height: 20),
                    if (_settings!['general'] != null)
                      _buildSection(
                        title: 'Général',
                        icon: Icons.settings_rounded,
                        color: const Color(0xFF6C63FF),
                        settings: _settings!['general'] as List,
                        groupKey: 'general',
                        isDark: isDark,
                      ),
                    const SizedBox(height: 16),
                    if (_settings!['notifications'] != null)
                      _buildSection(
                        title: 'Notifications',
                        icon: Icons.notifications_active_rounded,
                        color: const Color(0xFF0984E3),
                        settings: _settings!['notifications'] as List,
                        groupKey: 'notifications',
                        isDark: isDark,
                      ),
                    const SizedBox(height: 16),
                    if (_settings!['security'] != null)
                      _buildSection(
                        title: 'Sécurité',
                        icon: Icons.security_rounded,
                        color: const Color(0xFF00B894),
                        settings: _settings!['security'] as List,
                        groupKey: 'security',
                        isDark: isDark,
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomBar(isDark),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner(bool isDark) {
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.tune_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paramètres',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Configurez votre plateforme',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded,
                color: Colors.white),
            tooltip: 'Réinitialiser',
            onPressed: _reset,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List settings,
    required String groupKey,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textDark : AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
          // Settings
          ...settings.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            final isLast = idx == settings.length - 1;
            return Column(
              children: [
                _buildSettingTile(s, groupKey, isDark),
                if (!isLast)
                  Divider(
                    height: 1,
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
      Map<String, dynamic> s, String groupKey, bool isDark) {
    final type = s['type'] as String;
    final key = s['key'] as String;
    final value = s['value'];
    final label = s['label'] as String;
    final description = s['description'] as String?;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.textDark : AppTheme.textLight,
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildSettingControl(
              type, key, value, groupKey, isDark),
        ],
      ),
    );
  }

  Widget _buildSettingControl(String type, String key, dynamic value,
      String groupKey, bool isDark) {
    switch (type) {
      case 'boolean':
        return Switch(
          value: value == true || value == '1' || value == 1,
          onChanged: (v) => _updateSetting(groupKey, key, v),
          activeColor: AppTheme.primaryLight,
        );
      case 'integer':
        return SizedBox(
          width: 80,
          child: TextFormField(
            initialValue: value?.toString() ?? '',
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textDark : AppTheme.textLight,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 10),
              filled: true,
              fillColor: isDark
                  ? Colors.grey.shade800
                  : AppTheme.primaryLight.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => _updateSetting(
                groupKey, key, int.tryParse(v) ?? 0),
          ),
        );
      default:
        return SizedBox(
          width: 180,
          child: TextFormField(
            initialValue: value?.toString() ?? '',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? AppTheme.textDark : AppTheme.textLight,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 10),
              filled: true,
              fillColor: isDark
                  ? Colors.grey.shade800
                  : AppTheme.primaryLight.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => _updateSetting(groupKey, key, v),
          ),
        );
    }
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_hasChanges)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle,
                        size: 8, color: AppTheme.warning),
                    const SizedBox(width: 6),
                    Text(
                      'Non enregistré',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: !_hasChanges || _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  _isSaving ? 'Enregistrement...' : 'Enregistrer',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(bool isDark) {
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
              _error ?? '',
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
              onPressed: _loadSettings,
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