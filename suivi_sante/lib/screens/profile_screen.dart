// lib/screens/profile_screen.dart
// Version 2.1.0 — Design System Premium (Édition corrigée)

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';

// ═══════════════════════════════════════════════════════════════
// DESIGN SYSTEM
// ═══════════════════════════════════════════════════════════════
class _DS {
  static const primary = Color(0xFF5B6CFF);
  static const primaryDeep = Color(0xFF3D4FDB);
  static const primarySoft = Color(0xFFEEF0FF);

  static const success = Color(0xFF10B981);
  static const successSoft = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFEF3C7);
  static const danger = Color(0xFFEF4444);
  static const dangerSoft = Color(0xFFFEE2E2);
  static const info = Color(0xFF3B82F6);
  static const infoSoft = Color(0xFFDBEAFE);
  static const violet = Color(0xFF8B5CF6);
  static const violetSoft = Color(0xFFF3E8FF);
  static const teal = Color(0xFF14B8A6);

  static const ink = Color(0xFF0F172A);
  static const inkSoft = Color(0xFF475569);
  static const inkMuted = Color(0xFF94A3B8);
  static const line = Color(0xFFE2E8F0);
  static const surface = Color(0xFFFFFFFF);
  static const canvas = Color(0xFFF8FAFC);

  static const rSm = 12.0;
  static const rMd = 16.0;
  static const rLg = 20.0;
  static const rXl = 24.0;

  static List<BoxShadow> shadow(Color c, {double o = 0.10}) => [
        BoxShadow(
          color: c.withOpacity(o),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
      ];
}

// ═══════════════════════════════════════════════════════════════
// SCREEN
// ═══════════════════════════════════════════════════════════════
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isEditing = false;
  String? _errorMessage;

  final _scrollController = ScrollController(); // ✅ Nouveau
  final _nomController = TextEditingController();
  final _ageController = TextEditingController();
  final _tailleController = TextEditingController();
  final _poidsController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _maladiesController = TextEditingController();

  String _selectedSexe = 'Homme';
  String _selectedGroupeSanguin = 'A+';
  File? _selectedImage;
  bool _isSaving = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initAnimations();
    _loadUserData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _scrollController.dispose(); // ✅
    _nomController.dispose();
    _ageController.dispose();
    _tailleController.dispose();
    _poidsController.dispose();
    _telephoneController.dispose();
    _allergiesController.dispose();
    _maladiesController.dispose();
    super.dispose();
  }

  // ═══════════ DATA ═══════════
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final data = await authService.getUserData();
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        _userData = data;
        _isLoading = false;
        _populateForm();
      });
      _fadeController.forward(from: 0);
      _scaleController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible de charger les données';
      });
    }
  }

  String _getSexeLabel(String value) {
    if (value == 'M' || value == 'Homme') return 'Homme';
    if (value == 'F' || value == 'Femme') return 'Femme';
    if (value == 'A' || value == 'Autre') return 'Autre';
    return 'Homme';
  }

  String _getSexeValue(String label) {
    switch (label) {
      case 'Homme':
        return 'Homme';
      case 'Femme':
        return 'Femme';
      case 'Autre':
        return 'Autre';
      default:
        return 'Homme';
    }
  }

  void _populateForm() {
    if (_userData == null) return;
    _nomController.text = _userData?['nom'] ?? '';
    _ageController.text = _userData?['age']?.toString() ?? '';
    _tailleController.text = _userData?['taille']?.toString() ?? '';
    _poidsController.text = _userData?['poids']?.toString() ?? '';
    _telephoneController.text = _userData?['telephone'] ?? '';
    _allergiesController.text = _userData?['allergies'] ?? '';
    _maladiesController.text = _userData?['maladies_chroniques'] ?? '';
    _selectedSexe = _getSexeLabel(_userData?['sexe'] ?? 'Homme');
    _selectedGroupeSanguin = _userData?['groupe_sanguin'] ?? 'A+';
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadUserData();
    if (mounted) setState(() => _isRefreshing = false);
  }

  // ═══════════ MODE ÉDITION ═══════════
  /// ✅ Fonction centralisée pour activer le mode édition
  void _enableEditMode() {
    setState(() {
      _isEditing = true;
      _tabController.index = 0; // ✅ On revient sur l'onglet "Personnel"
    });
    // Scroll en haut pour voir le formulaire
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // ═══════════ SAVE ═══════════
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final profileService = ProfileService();
      final data = {
        'nom': _nomController.text,
        'age': int.tryParse(_ageController.text) ?? 0,
        'sexe': _getSexeValue(_selectedSexe),
        'taille': double.tryParse(_tailleController.text) ?? 0,
        'poids': double.tryParse(_poidsController.text) ?? 0,
        'groupe_sanguin': _selectedGroupeSanguin,
        'allergies':
            _allergiesController.text.isEmpty ? null : _allergiesController.text,
        'maladies_chroniques': _maladiesController.text.isEmpty
            ? null
            : _maladiesController.text,
      };
      if (_telephoneController.text.isNotEmpty) {
        data['telephone'] = _telephoneController.text;
      }

      await profileService.updateProfile(data);

      if (_selectedImage != null) {
        final result = await profileService.uploadPhoto(_selectedImage!);
        if (result['success'] == true) {
          final updatedPhotoUrl = result['photo_url'];
          if (mounted) {
            setState(() {
              if (_userData != null) _userData!['photo_url'] = updatedPhotoUrl;
            });
          }
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('photo_url', updatedPhotoUrl ?? '');
        }
      }

      if (mounted) setState(() => _isEditing = false);
      _snack('Profil mis à jour avec succès', _DS.success,
          icon: Iconsax.tick_circle);
      await _loadUserData();
    } catch (e) {
      _snack('Erreur : $e', _DS.danger, icon: Iconsax.warning_2);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _snack(String msg, Color color, {IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                msg,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500, fontSize: 13.5),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.rSm)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ═══════════ BUILD ═══════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DS.canvas,
      body: _isLoading
          ? _buildLoading()
          : _errorMessage != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  color: _DS.primary,
                  backgroundColor: _DS.surface,
                  child: CustomScrollView(
                    controller: _scrollController, // ✅
                    slivers: [
                      _buildAppBar(),
                      if (!_isEditing) _buildStatsStrip(),
                      _buildTabBar(),
                      SliverFillRemaining(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Onglet 1 : Personnel (avec édition)
                            _isEditing
                                ? _buildEditForm()
                                : _PersonalTab(userData: _userData),
                            // Onglet 2 : Médical (avec bouton modifier)
                            _MedicalTab(
                              userData: _userData,
                              onEdit: _enableEditMode, // ✅ Appel centralisé
                            ),
                            // Onglet 3 : Sécurité
                            _SecurityTab(
                              userData: _userData,
                              onLogout: _logout,
                              onDelete: _showDeleteDialog,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // ═══════════ APP BAR ═══════════
  Widget _buildAppBar() {
    final name = _userData?['nom'] ?? 'Utilisateur';
    final email = _userData?['email'] ?? 'Email non disponible';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    String? photoUrl = _userData?['photo_url'];
    if (photoUrl != null && photoUrl.isNotEmpty && !photoUrl.startsWith('http')) {
      photoUrl = photoUrl.startsWith('/storage')
          ? 'http://192.168.1.5:8001/api/$photoUrl'
          : 'http://192.168.1.5:8001/api//storage/$photoUrl';
    }

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: _DS.primary,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      leading: _glassIcon(
        icon: Iconsax.arrow_left_2,
        onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
      ),
      actions: [
        _glassIcon(icon: Iconsax.refresh, onTap: _refreshData),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.more, color: Colors.white, size: 18),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.rLg)),
          color: _DS.surface,
          onSelected: (v) {
            if (v == 'edit') {
              _enableEditMode(); // ✅
            } else if (v == 'settings') {
              Navigator.pushNamed(context, '/settings');
            } else if (v == 'logout') {
              _logout();
            }
          },
          itemBuilder: (_) => [
            _menuItem('edit', Iconsax.edit_2, 'Modifier', _DS.primary),
            _menuItem('settings', Iconsax.setting_2, 'Paramètres', _DS.inkSoft),
            _menuItem('logout', Iconsax.logout, 'Déconnexion', _DS.danger),
          ],
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_DS.primary, _DS.primaryDeep, _DS.violet],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.5),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 58,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        child: _selectedImage != null
                            ? ClipOval(
                                child: Image.file(
                                  _selectedImage!,
                                  width: 116,
                                  height: 116,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : photoUrl != null && photoUrl.isNotEmpty
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: photoUrl,
                                      width: 116,
                                      height: 116,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => Text(
                                        initial,
                                        style: GoogleFonts.inter(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    initial,
                                    style: GoogleFonts.inter(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: _DS.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _pickImage,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Iconsax.camera,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: _DS.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Compte vérifié',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                              ),
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
        ),
      ),
    );
  }

  Widget _glassIcon({required IconData icon, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label, Color color) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: _DS.ink,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════ STATS STRIP ═══════════
  Widget _buildStatsStrip() {
    final items = [
      _StatSpec('Points', '${_userData?['points'] ?? 0}', Iconsax.medal,
          _DS.warning),
      _StatSpec('Médicaments', '${_userData?['medicaments'] ?? 0}',
          Iconsax.health, _DS.primary),
      _StatSpec('Rendez-vous', '${_userData?['rendez_vous'] ?? 0}',
          Iconsax.calendar_1, _DS.info),
      _StatSpec('Score santé', '${_userData?['sante_score'] ?? 0}%',
          Iconsax.cpu, _DS.success),
    ];

    return SliverToBoxAdapter(
      child: Transform.translate(
        offset: const Offset(0, -18),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: BorderRadius.circular(_DS.rLg),
            boxShadow: _DS.shadow(_DS.ink, o: 0.06),
            border: Border.all(color: _DS.line),
          ),
          child: Row(
            children: items.map((s) {
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: s.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(s.icon, color: s.color, size: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.value,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _DS.ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      s.label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: _DS.inkMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ═══════════ TAB BAR ═══════════
  Widget _buildTabBar() {
    return SliverToBoxAdapter(
      child: Container(
        color: _DS.canvas,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 50,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: BorderRadius.circular(_DS.rMd),
            border: Border.all(color: _DS.line),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_DS.primary, _DS.primaryDeep],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: _DS.inkSoft,
            labelStyle:
                GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 12.5, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Personnel'),
              Tab(text: 'Médical'),
              Tab(text: 'Sécurité'),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════ EDIT FORM ═══════════
  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: BorderRadius.circular(_DS.rLg),
              border: Border.all(color: _DS.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _DS.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Iconsax.edit_2,
                          color: _DS.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Modifier le profil',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _DS.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _field(_nomController, 'Nom complet', Iconsax.user,
                    'Votre nom'),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _field(_ageController, 'Âge',
                          Iconsax.calendar_1, '25',
                          type: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dropdown('Sexe', _selectedSexe,
                          ['Homme', 'Femme', 'Autre'],
                          (v) => setState(() => _selectedSexe = v!)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _field(_tailleController, 'Taille (cm)',
                          Iconsax.ruler, '175',
                          type: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(_poidsController, 'Poids (kg)',
                          Iconsax.weight, '70',
                          type: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _dropdown(
                    'Groupe sanguin',
                    _selectedGroupeSanguin,
                    ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                    (v) => setState(() => _selectedGroupeSanguin = v!)),
                const SizedBox(height: 14),
                _field(_telephoneController, 'Téléphone', Iconsax.call,
                    '06 12 34 56 78',
                    type: TextInputType.phone),
                const SizedBox(height: 14),
                _field(_allergiesController, 'Allergies', Iconsax.danger,
                    'Arachides, Pollen...',
                    maxLines: 2),
                const SizedBox(height: 14),
                _field(_maladiesController, 'Maladies chroniques',
                    Iconsax.health, 'Asthme, Diabète...',
                    maxLines: 2),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _populateForm();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _DS.inkSoft,
                          side: const BorderSide(color: _DS.line),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(_DS.rMd),
                          ),
                        ),
                        child: Text(
                          'Annuler',
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: FilledButton.styleFrom(
                            backgroundColor: _DS.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_DS.rMd),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Enregistrer',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDangerZone(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _DS.dangerSoft,
        borderRadius: BorderRadius.circular(_DS.rLg),
        border: Border.all(color: _DS.danger.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.warning_2, color: _DS.danger, size: 20),
              const SizedBox(width: 10),
              Text(
                'Zone sensible',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _DS.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'La suppression de votre compte est irréversible.',
            style: GoogleFonts.inter(fontSize: 12.5, color: _DS.inkSoft),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showDeleteDialog,
              icon: const Icon(Iconsax.trash, color: _DS.danger, size: 16),
              label: Text(
                'Supprimer le compte',
                style: GoogleFonts.inter(
                  color: _DS.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _DS.danger,
                side: const BorderSide(color: _DS.danger),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_DS.rSm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════ FORM HELPERS ═══════════
  Widget _field(TextEditingController controller, String label, IconData icon,
      String hint,
      {TextInputType? type, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 14, color: _DS.ink),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _DS.primary, size: 18),
        labelStyle: GoogleFonts.inter(
            fontSize: 12.5, color: _DS.inkSoft, fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.inter(fontSize: 13, color: _DS.inkMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DS.rSm),
          borderSide: const BorderSide(color: _DS.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DS.rSm),
          borderSide: const BorderSide(color: _DS.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DS.rSm),
          borderSide: const BorderSide(color: _DS.primary, width: 1.5),
        ),
        filled: true,
        fillColor: _DS.canvas,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : items.first,
      onChanged: onChanged,
      items: items
          .map((i) => DropdownMenuItem(
                value: i,
                child: Text(i, style: GoogleFonts.inter(fontSize: 14)),
              ))
          .toList(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
            fontSize: 12.5, color: _DS.inkSoft, fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DS.rSm),
          borderSide: const BorderSide(color: _DS.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DS.rSm),
          borderSide: const BorderSide(color: _DS.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_DS.rSm),
          borderSide: const BorderSide(color: _DS.primary, width: 1.5),
        ),
        filled: true,
        fillColor: _DS.canvas,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),
    );
  }

  // ═══════════ DIALOGS ═══════════
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_DS.rXl)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: _DS.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.logout, color: _DS.danger, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Déconnexion',
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
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
              style: GoogleFonts.inter(
                  color: _DS.inkSoft, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: _DS.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_DS.rSm)),
            ),
            child: Text(
              'Se déconnecter',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      _snack('Déconnecté avec succès', _DS.success,
          icon: Iconsax.tick_circle);
    } catch (_) {
      _snack('Erreur lors de la déconnexion', _DS.danger);
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_DS.rXl)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: _DS.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.trash, color: _DS.danger, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Supprimer le compte',
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          'Cette action est irréversible. Toutes vos données seront définitivement supprimées.',
          style: GoogleFonts.inter(
              fontSize: 13.5, color: _DS.inkSoft, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                  color: _DS.inkSoft, fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _snack('Fonctionnalité à venir', _DS.warning);
            },
            style: FilledButton.styleFrom(
              backgroundColor: _DS.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_DS.rSm)),
            ),
            child: Text(
              'Supprimer',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════ LOADING / ERROR ═══════════
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(colors: [_DS.primary, _DS.primaryDeep]),
              shape: BoxShape.circle,
              boxShadow: _DS.shadow(_DS.primary, o: 0.35),
            ),
            child: const Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child:
                    CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Shimmer.fromColors(
            baseColor: _DS.line,
            highlightColor: _DS.canvas,
            child: Text(
              'Chargement du profil...',
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _DS.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: _DS.dangerSoft, shape: BoxShape.circle),
              child: const Icon(Iconsax.cloud_minus, size: 48, color: _DS.danger),
            ),
            const SizedBox(height: 20),
            Text(
              'Oups ! Une erreur est survenue',
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w800, color: _DS.ink),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 13.5, color: _DS.inkMuted, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadUserData,
              icon: const Icon(Iconsax.refresh, size: 18),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(
                backgroundColor: _DS.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_DS.rMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STAT SPEC
// ═══════════════════════════════════════════════════════════════
class _StatSpec {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatSpec(this.label, this.value, this.icon, this.color);
}

// ═══════════════════════════════════════════════════════════════
// TAB — PERSONNEL
// ═══════════════════════════════════════════════════════════════
class _PersonalTab extends StatelessWidget {
  final Map<String, dynamic>? userData;
  const _PersonalTab({this.userData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          _InfoCard(
            title: 'Informations personnelles',
            icon: Iconsax.user,
            gradient: const [_DS.primary, _DS.primaryDeep],
            children: [
              _InfoRow(Iconsax.calendar_1, 'Âge',
                  userData?['age']?.toString() ?? 'Non renseigné', _DS.primary),
              const _Divider(),
              _InfoRow(Iconsax.user, 'Sexe',
                  userData?['sexe'] ?? 'Non renseigné', _DS.info),
              const _Divider(),
              _InfoRow(
                  Iconsax.ruler,
                  'Taille',
                  userData?['taille'] != null
                      ? '${userData!['taille']} cm'
                      : 'Non renseigné',
                  _DS.success),
              const _Divider(),
              _InfoRow(
                  Iconsax.weight,
                  'Poids',
                  userData?['poids'] != null
                      ? '${userData!['poids']} kg'
                      : 'Non renseigné',
                  _DS.warning),
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Contact',
            icon: Iconsax.sms,
            gradient: const [_DS.info, Color(0xFF2563EB)],
            children: [
              _InfoRow(Iconsax.sms, 'Email',
                  userData?['email'] ?? 'Non renseigné', _DS.info),
              const _Divider(),
              _InfoRow(Iconsax.call, 'Téléphone',
                  userData?['telephone'] ?? 'Non renseigné', _DS.success),
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Membre depuis',
            icon: Iconsax.calendar_2,
            gradient: const [_DS.warning, Color(0xFFD97706)],
            children: [
              _InfoRow(
                  Iconsax.calendar_2,
                  'Inscription',
                  userData?['created_at'] != null
                      ? DateFormat('dd MMMM yyyy', 'fr')
                          .format(DateTime.parse(userData!['created_at']))
                      : 'Non disponible',
                  _DS.warning),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB — MÉDICAL
// ═══════════════════════════════════════════════════════════════
class _MedicalTab extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback onEdit;

  const _MedicalTab({this.userData, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          Stack(
            children: [
              _InfoCard(
                title: 'Informations médicales',
                icon: Iconsax.health,
                gradient: const [_DS.danger, Color(0xFFDC2626)],
                children: [
                  _InfoRow(Iconsax.drop, 'Groupe sanguin',
                      userData?['groupe_sanguin'] ?? 'Non renseigné',
                      _DS.danger),
                  const _Divider(),
                  _InfoRow(
                      Iconsax.danger,
                      'Allergies',
                      (userData?['allergies']?.toString().isNotEmpty ?? false)
                          ? userData!['allergies']
                          : 'Aucune allergie',
                      _DS.warning),
                  const _Divider(),
                  _InfoRow(
                      Iconsax.health,
                      'Maladies chroniques',
                      (userData?['maladies_chroniques']
                                  ?.toString()
                                  .isNotEmpty ??
                              false)
                          ? userData!['maladies_chroniques']
                          : 'Aucune maladie',
                      _DS.violet),
                ],
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Iconsax.edit_2,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Modifier',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _EmptyInfoCard(
            title: 'Traitements en cours',
            icon: Iconsax.health,
            gradient: const [_DS.violet, _DS.primary],
            emptyTitle: 'Aucun traitement actif',
            emptySubtitle: 'Consultez votre médecin pour un suivi',
          ),
          const SizedBox(height: 16),
          _EmptyInfoCard(
            title: 'Dernier rendez-vous',
            icon: Iconsax.calendar_1,
            gradient: const [_DS.teal, Color(0xFF0D9488)],
            emptyTitle: 'Aucun rendez-vous récent',
            emptySubtitle: 'Planifiez votre prochain rendez-vous',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TAB — SÉCURITÉ
// ═══════════════════════════════════════════════════════════════
class _SecurityTab extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback onLogout;
  final VoidCallback onDelete;

  const _SecurityTab({
    this.userData,
    required this.onLogout,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          _InfoCard(
            title: 'Sécurité du compte',
            icon: Iconsax.shield_tick,
            gradient: const [_DS.primary, _DS.primaryDeep],
            children: [
              _InfoRow(Iconsax.lock, 'Mot de passe', '••••••••', _DS.primary),
              const _Divider(),
              _InfoRow(
                  Iconsax.verify,
                  'Email vérifié',
                  userData?['email_verified_at'] != null ? 'Oui' : 'Non',
                  userData?['email_verified_at'] != null
                      ? _DS.success
                      : _DS.danger),
              const _Divider(),
              _InfoRow(Iconsax.call, 'Téléphone vérifié', 'Non', _DS.danger),
            ],
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Actions rapides',
            icon: Iconsax.setting_2,
            gradient: const [_DS.info, Color(0xFF2563EB)],
            children: [
              _ActionTile(Iconsax.lock, 'Changer le mot de passe',
                  'Mettez à jour votre mot de passe', _DS.primary,
                  onTap: () => _toast(context, 'Fonctionnalité à venir')),
              const _Divider(),
              _ActionTile(Iconsax.notification, 'Notifications',
                  'Gérer vos préférences', _DS.warning,
                  onTap: () => _toast(context, 'Fonctionnalité à venir')),
              const _Divider(),
              _ActionTile(Iconsax.export_1, 'Exporter les données',
                  'Télécharger vos données médicales', _DS.success,
                  onTap: () => _toast(context, 'Fonctionnalité à venir')),
              const _Divider(),
              _ActionTile(Iconsax.trash, 'Supprimer le compte',
                  'Supprimer définitivement vos données', _DS.danger,
                  onTap: onDelete),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: onLogout,
              icon: const Icon(Iconsax.logout, color: Colors.white, size: 18),
              label: Text(
                'Se déconnecter',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _DS.danger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_DS.rMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
        backgroundColor: _DS.success,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.rSm)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.rLg),
        border: Border.all(color: _DS.line),
        boxShadow: _DS.shadow(_DS.ink, o: 0.04),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_DS.rLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final String emptyTitle;
  final String emptySubtitle;

  const _EmptyInfoCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: title,
      icon: icon,
      gradient: gradient,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _DS.canvas,
            borderRadius: BorderRadius.circular(_DS.rSm),
            border: Border.all(color: _DS.line),
          ),
          child: Row(
            children: [
              Icon(Iconsax.info_circle, color: _DS.inkMuted, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emptyTitle,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _DS.inkSoft,
                      ),
                    ),
                    Text(
                      emptySubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: _DS.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final isEmpty = value.contains('Aucune') || value.contains('Non renseigné');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _DS.inkSoft,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isEmpty ? _DS.inkMuted : _DS.ink,
                fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile(this.icon, this.title, this.subtitle, this.color,
      {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: _DS.ink,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          color: _DS.inkMuted,
        ),
      ),
      trailing: const Icon(Iconsax.arrow_right_3, color: _DS.inkMuted, size: 14),
      onTap: onTap,
      dense: true,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(color: _DS.line, height: 1, thickness: 1);
  }
}