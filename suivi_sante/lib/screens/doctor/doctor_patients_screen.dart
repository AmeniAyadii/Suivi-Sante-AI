import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/doctor_service.dart';

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen>
    with SingleTickerProviderStateMixin {
  // ==================== THEME ====================
  static const Color _primary = Color(0xFF6C5CE7);
  static const Color _primaryDark = Color(0xFF4834D4);
  static const Color _bg = Color(0xFFF7F8FC);
  static const Color _text = Color(0xFF2D3436);
  static const Color _muted = Color(0xFFB2BEC3);

  late Future<List<dynamic>> _future;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _fadeController;

  String _searchQuery = '';
  String _sexeFilter = 'all';
  bool _isSearchVisible = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _future = _load().whenComplete(() => _fadeController.forward());
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (q != _searchQuery) {
        setState(() => _searchQuery = q);
      }
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final visible = _scrollController.offset < 60;
    if (visible != _isSearchVisible) {
      setState(() => _isSearchVisible = visible);
    }
  }

  // ==================== DATA ====================
  Future<List<dynamic>> _load() => DoctorService().getPatients();

  void _reload() {
    setState(() => _future = _load());
  }

  // ==================== HELPERS ====================
  Color _avatarColor(String name) {
    if (name.isEmpty) return _primary;
    final hash = name.codeUnits.fold<int>(0, (a, b) => a + b);
    const palette = [
      Color(0xFF6C5CE7),
      Color(0xFF00B894),
      Color(0xFF0984E3),
      Color(0xFFE17055),
      Color(0xFFD63031),
      Color(0xFF00CEC9),
      Color(0xFFFDCB6E),
      Color(0xFFE84393),
    ];
    return palette[hash % palette.length];
  }

  String _sexeLabel(String? s) {
    switch (s) {
      case 'M':
        return 'Homme';
      case 'F':
        return 'Femme';
      case 'A':
      case 'Autre':
        return 'Autre';
      default:
        return '—';
    }
  }

  void _showSnack(String msg, {Color bg = Colors.green, IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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

  // ==================== FILTRAGE ====================
  List<dynamic> _applyFilters(List<dynamic> patients) {
    return patients.where((p) {
      // Filtre recherche
      if (_searchQuery.isNotEmpty) {
        final nom = (p['nom'] ?? '').toString().toLowerCase();
        final email = (p['email'] ?? '').toString().toLowerCase();
        final tel = (p['telephone'] ?? '').toString().toLowerCase();
        final match = nom.contains(_searchQuery) ||
            email.contains(_searchQuery) ||
            tel.contains(_searchQuery);
        if (!match) return false;
      }
      // Filtre sexe
      if (_sexeFilter != 'all') {
        final sexe = (p['sexe'] ?? '').toString();
        if (sexe != _sexeFilter) return false;
      }
      return true;
    }).toList();
  }

  // ==================== AVATAR ====================
  Widget _buildAvatar(String nom, {double radius = 26, bool showBadge = false}) {
    final initiale = nom.isNotEmpty ? nom[0].toUpperCase() : '?';
    final color = _avatarColor(nom);

    return Stack(
      children: [
        Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initiale,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (showBadge)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.6,
              height: radius * 0.6,
              decoration: BoxDecoration(
                color: const Color(0xFF00B894),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildFilters(),
              const SizedBox(height: 4),
              Expanded(child: _buildPatientsList()),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mes patients',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _text,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Gérez votre liste de patients',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: _text,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SEARCH BAR ====================
  Widget _buildSearchBar() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: _isSearchVisible
          ? Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Rechercher un patient (nom, email, tél)...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: Colors.grey.shade500,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: _primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ==================== FILTERS ====================
  Widget _buildFilters() {
    final filters = <Map<String, dynamic>>[
      {'key': 'all', 'label': 'Tous', 'icon': Icons.apps_rounded},
      {'key': 'M', 'label': 'Hommes', 'icon': Icons.male_rounded},
      {'key': 'F', 'label': 'Femmes', 'icon': Icons.female_rounded},
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final key = f['key'] as String;
          final label = f['label'] as String;
          final icon = f['icon'] as IconData;
          final selected = _sexeFilter == key;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _sexeFilter = key);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? _primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                  border: selected
                      ? null
                      : Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: selected ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== LISTE ====================
  Widget _buildPatientsList() {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
          );
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error);
        }

        final allPatients = snapshot.data ?? [];
        if (allPatients.isEmpty) {
          return _buildEmptyState();
        }

        final patients = _applyFilters(allPatients);
        if (patients.isEmpty) {
          return _buildNoResultState();
        }

        return RefreshIndicator(
          color: _primary,
          onRefresh: () async => _reload(),
          child: FadeTransition(
            opacity: _fadeController,
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              itemCount: patients.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: _primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${patients.length} patient${patients.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final p = patients[index - 1] as Map;
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 250 + (index * 40)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _buildPatientCard(p),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ==================== CARD PATIENT ====================
  Widget _buildPatientCard(Map p) {
    final nom = p['nom']?.toString() ?? 'Inconnu';
    final email = p['email']?.toString() ?? '';
    final age = p['age']?.toString() ?? '?';
    final sexe = p['sexe']?.toString() ?? '';
    final tel = p['telephone']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            _showPatientDetail(Map<String, dynamic>.from(p as Map));
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _buildAvatar(nom, radius: 26, showBadge: true),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              nom,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (sexe.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: (sexe == 'F'
                                        ? const Color(0xFFE84393)
                                        : const Color(0xFF0984E3))
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                sexe == 'M'
                                    ? 'H'
                                    : sexe == 'F'
                                        ? 'F'
                                        : 'A',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: sexe == 'F'
                                      ? const Color(0xFFE84393)
                                      : const Color(0xFF0984E3),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (email.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.mail_outline_rounded,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildTag('$age ans', Icons.cake_rounded,
                              const Color(0xFFE17055)),
                          if (tel.isNotEmpty)
                            _buildTag(tel, Icons.phone_rounded,
                                const Color(0xFF00B894)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== TAG ====================
  Widget _buildTag(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== EMPTY STATE ====================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 48,
              color: _primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucun patient enregistré',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Les patients apparaîtront ici',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun résultat',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Essayez avec un autre terme de recherche',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
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
              onPressed: _reload,
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

  // ==================== DÉTAIL PATIENT ====================
  void _showPatientDetail(Map<String, dynamic> patient) {
    final nom = patient['nom']?.toString() ?? 'Inconnu';
    final email = patient['email']?.toString() ?? '—';
    final age = patient['age']?.toString() ?? '—';
    final sexe = patient['sexe']?.toString();
    final telephone = patient['telephone']?.toString() ?? '—';
    final groupeSanguin = patient['groupe_sanguin']?.toString() ?? '—';
    final allergies = patient['allergies']?.toString() ?? 'Aucune';
    final maladies = patient['maladies_chroniques']?.toString() ?? 'Aucune';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 24),
                    // Header patient
                    Row(
                      children: [
                        _buildAvatar(nom, radius: 36, showBadge: true),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nom,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Tags rapides
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTag('$age ans', Icons.cake_rounded,
                            const Color(0xFFE17055)),
                        _buildTag(_sexeLabel(sexe), Icons.person_rounded,
                            const Color(0xFF0984E3)),
                        if (groupeSanguin != '—')
                          _buildTag(groupeSanguin, Icons.bloodtype_rounded,
                              const Color(0xFFD63031)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Section Infos
                    _sectionTitle('Informations personnelles'),
                    const SizedBox(height: 12),
                    _detailRow(Icons.phone_rounded, 'Téléphone', telephone),
                    _detailRow(
                        Icons.cake_rounded, 'Âge', '$age ans'),
                    _detailRow(Icons.person_rounded, 'Sexe',
                        _sexeLabel(sexe)),
                    const SizedBox(height: 20),
                    // Section Médicale
                    _sectionTitle('Informations médicales'),
                    const SizedBox(height: 12),
                    _detailRow(Icons.bloodtype_rounded, 'Groupe sanguin',
                        groupeSanguin),
                    _detailRow(
                        Icons.warning_amber_rounded, 'Allergies', allergies),
                    _detailRow(Icons.medical_information_rounded,
                        'Maladies chroniques', maladies),
                    const SizedBox(height: 24),
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showSnack(
                                'Fonctionnalité à venir',
                                bg: Colors.orange.shade700,
                                icon: Icons.info_outline_rounded,
                              );
                            },
                            icon: const Icon(Icons.calendar_today_rounded,
                                size: 18),
                            label: const Text('Prendre RDV'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: _primary.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showSnack(
                                'Fonctionnalité à venir',
                                bg: _primary,
                                icon: Icons.info_outline_rounded,
                              );
                            },
                            icon: const Icon(Icons.medication_rounded,
                                size: 18),
                            label: const Text('Prescrire'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
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
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _text,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
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
}