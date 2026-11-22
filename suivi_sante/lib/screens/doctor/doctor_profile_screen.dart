import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user.dart';
import '../../services/doctor_service.dart';

class DoctorProfileScreen extends StatefulWidget {
  final User user;
  const DoctorProfileScreen({super.key, required this.user});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen>
    with SingleTickerProviderStateMixin {
  // ==================== THEME ====================
  static const Color _primary = Color(0xFFD63031);
  static const Color _primaryDark = Color(0xFFB71C1C);
  static const Color _accent = Color(0xFFFF7675);
  static const Color _bg = Color(0xFFF7F8FC);
  static const Color _text = Color(0xFF2D3436);
  static const Color _muted = Color(0xFF636E72);
  static const Color _success = Color(0xFF00B894);

  late Future<Map<String, dynamic>> _future;
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _future = DoctorService().getProfile().whenComplete(
      () => _fadeController.forward(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _fadeController.reset();
      _future = DoctorService().getProfile().whenComplete(
        () => _fadeController.forward(),
      );
    });
  }

  // ==================== HELPERS ====================
  void _showSnack(String msg, {Color bg = _success, IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            if (icon != null) Icon(icon, color: Colors.white, size: 20),
            if (icon != null) const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        color: _bg,
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          color: _primary,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: _primary,
                    strokeWidth: 2.5,
                  ),
                );
              }
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error);
              }
              final d = snapshot.data ?? {};

              return FadeTransition(
                opacity: _fadeController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Column(
                    children: [
                      _buildHeroHeader(d),
                      const SizedBox(height: 20),
                      _buildQuickStats(d),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Informations personnelles'),
                      const SizedBox(height: 12),
                      _buildInfoCard(d),
                      const SizedBox(height: 24),
                      _buildEditButton(d),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ==================== HERO HEADER ====================
  Widget _buildHeroHeader(Map<String, dynamic> d) {
    final nom = d['nom']?.toString() ?? 'Médecin';
    final initiale = nom.isNotEmpty ? nom[0].toUpperCase() : '?';
    final specialite =
        d['specialite']?.toString() ?? 'Médecin généraliste';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Cercles décoratifs
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Contenu
          Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      child: Text(
                        initiale,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Dr. $nom',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  specialite,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                d['email']?.toString() ?? '',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== QUICK STATS ====================
  Widget _buildQuickStats(Map<String, dynamic> d) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.cake_rounded,
              label: 'Âge',
              value: d['age'] != null ? '${d['age']}' : '—',
              suffix: 'ans',
              color: const Color(0xFFE17055),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.person_rounded,
              label: 'Sexe',
              value: d['sexe'] == 'M'
                  ? 'H'
                  : d['sexe'] == 'F'
                      ? 'F'
                      : '—',
              suffix: d['sexe'] == 'M'
                  ? 'Homme'
                  : d['sexe'] == 'F'
                      ? 'Femme'
                      : '',
              color: const Color(0xFF0984E3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.verified_rounded,
              label: 'Statut',
              value: '✓',
              suffix: 'Actif',
              color: _success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String suffix,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            suffix.isNotEmpty ? suffix : label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==================== SECTION TITLE ====================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _text,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== INFO CARD ====================
  Widget _buildInfoCard(Map<String, dynamic> d) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.email_rounded,
              'Adresse email',
              d['email']?.toString() ?? '—',
              const Color(0xFF0984E3),
            ),
            _divider(),
            _buildInfoRow(
              Icons.phone_rounded,
              'Téléphone',
              d['telephone']?.toString() ?? 'Non renseigné',
              const Color(0xFF00B894),
            ),
            _divider(),
            _buildInfoRow(
              Icons.medical_services_rounded,
              'Spécialité',
              d['specialite']?.toString() ?? 'Non renseignée',
              const Color(0xFFE17055),
            ),
            _divider(),
            _buildInfoRow(
              Icons.cake_rounded,
              'Âge',
              d['age'] != null ? '${d['age']} ans' : 'Non renseigné',
              const Color(0xFFD63031),
            ),
            _divider(),
            _buildInfoRow(
              Icons.person_rounded,
              'Sexe',
              d['sexe'] == 'M'
                  ? 'Masculin'
                  : d['sexe'] == 'F'
                      ? 'Féminin'
                      : 'Non renseigné',
              const Color(0xFF6C5CE7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        indent: 56,
        color: Colors.grey.shade100,
      );

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== EDIT BUTTON ====================
  Widget _buildEditButton(Map<String, dynamic> d) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            _showEditSheet(d);
          },
          icon: const Icon(Icons.edit_rounded, size: 20),
          label: const Text(
            'Modifier mes informations',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== EDIT SHEET ====================
  void _showEditSheet(Map<String, dynamic> d) {
    final nomController = TextEditingController(text: d['nom'] ?? '');
    final telephoneController =
        TextEditingController(text: d['telephone'] ?? '');
    final specialiteController =
        TextEditingController(text: d['specialite'] ?? '');
    final ageController =
        TextEditingController(text: d['age']?.toString() ?? '');
    String? sexe = d['sexe'];
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setStateModal) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag indicator
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_primary, _accent],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Modifier mon profil',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: _text,
                                  ),
                                ),
                                Text(
                                  'Mettez à jour vos informations',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Champs
                      _inputLabel('Nom complet'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nomController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration(
                          hint: 'Nom et prénom',
                          icon: Icons.person_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _inputLabel('Téléphone'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: telephoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          hint: '+216 XX XXX XXX',
                          icon: Icons.phone_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _inputLabel('Spécialité'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: specialiteController,
                        decoration: _inputDecoration(
                          hint: 'Ex: Cardiologue',
                          icon: Icons.medical_services_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _inputLabel('Âge'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: ageController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(
                                    hint: 'Ex: 35',
                                    icon: Icons.cake_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _inputLabel('Sexe'),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: sexe,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                  ),
                                  decoration: _inputDecoration(
                                    hint: 'Choisir',
                                    icon: Icons.person_outline_rounded,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'M', child: Text('Masculin')),
                                    DropdownMenuItem(
                                        value: 'F', child: Text('Féminin')),
                                    DropdownMenuItem(
                                        value: 'A', child: Text('Autre')),
                                  ],
                                  onChanged: (v) =>
                                      setStateModal(() => sexe = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: submitting
                                  ? null
                                  : () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                                foregroundColor: Colors.grey.shade700,
                              ),
                              child: const Text(
                                'Annuler',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: submitting
                                  ? null
                                  : () async {
                                      setStateModal(
                                          () => submitting = true);
                                      try {
                                        final data = <String, dynamic>{};
                                        if (nomController.text.trim().isNotEmpty) {
                                          data['nom'] =
                                              nomController.text.trim();
                                        }
                                        if (telephoneController.text
                                            .trim()
                                            .isNotEmpty) {
                                          data['telephone'] =
                                              telephoneController.text.trim();
                                        }
                                        if (specialiteController.text
                                            .trim()
                                            .isNotEmpty) {
                                          data['specialite'] =
                                              specialiteController.text.trim();
                                        }
                                        if (ageController.text.trim().isNotEmpty) {
                                          data['age'] = int.tryParse(
                                              ageController.text.trim());
                                        }
                                        if (sexe != null) data['sexe'] = sexe;

                                        await DoctorService().updateProfile(data);
                                        if (!ctx.mounted) return;
                                        Navigator.pop(ctx);
                                        _refresh();
                                        _showSnack(
                                          'Profil mis à jour avec succès',
                                          icon: Icons.check_circle_rounded,
                                        );
                                      } catch (e) {
                                        if (!ctx.mounted) return;
                                        setStateModal(
                                            () => submitting = false);
                                        _showSnack(
                                          'Erreur: $e',
                                          bg: Colors.red.shade600,
                                          icon: Icons.error_rounded,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_rounded, size: 18),
                                        SizedBox(width: 6),
                                        Text(
                                          'Enregistrer',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _inputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _text,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
      prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
      filled: true,
      fillColor: _bg,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
    );
  }

  // ==================== ERROR STATE ====================
  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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