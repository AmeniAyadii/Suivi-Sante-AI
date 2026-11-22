import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/doctor_service.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  // ==================== THEME ====================
  static const Color _primary = Color(0xFFE17055);      // Orange signature
  static const Color _primaryDark = Color(0xFFD63031);
  static const Color _bg = Color(0xFFF7F8FC);
  static const Color _text = Color(0xFF2D3436);
  static const Color _muted = Color(0xFF636E72);

  static const Color _blue = Color(0xFF0984E3);
  static const Color _green = Color(0xFF00B894);
  static const Color _orange = Color(0xFFE17055);
  static const Color _grey = Color(0xFFB2BEC3);
  static const Color _red = Color(0xFFD63031);

  late Future<List<dynamic>> _future;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _fadeController;

  String _search = '';
  String _statutFilter = 'all';
  String _periodeFilter = 'all';
  int? _updatingId;
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
      final q = _searchController.text.trim();
      if (q != _search) {
        _search = q;
        _reload();
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
    final visible = _scrollController.offset < 80;
    if (visible != _isSearchVisible) {
      setState(() => _isSearchVisible = visible);
    }
  }

  // ==================== DATA ====================
  Future<List<dynamic>> _load() {
    return DoctorService().getRendezvous(
      statut: _statutFilter == 'all' ? null : _statutFilter,
      periode: _periodeFilter == 'all' ? null : _periodeFilter,
      search: _search.isEmpty ? null : _search,
    );
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  // ==================== STATUT HELPERS ====================
  Color _statutColor(String? s) {
    switch (s) {
      case 'à_venir':
        return _blue;
      case 'confirmé':
        return _green;
      case 'en_cours':
        return _orange;
      case 'passé':
        return _grey;
      case 'annulé':
        return _red;
      default:
        return _grey;
    }
  }

  String _statutLabel(String? s) {
    switch (s) {
      case 'à_venir':
        return 'À venir';
      case 'confirmé':
        return 'Confirmé';
      case 'en_cours':
        return 'En cours';
      case 'passé':
        return 'Passé';
      case 'annulé':
        return 'Annulé';
      default:
        return s ?? '—';
    }
  }

  IconData _statutIcon(String? s) {
    switch (s) {
      case 'à_venir':
        return Icons.schedule_rounded;
      case 'confirmé':
        return Icons.check_circle_rounded;
      case 'en_cours':
        return Icons.play_circle_rounded;
      case 'passé':
        return Icons.history_rounded;
      case 'annulé':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  void _showSnack(String msg, {Color bg = _green, IconData? icon}) {
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

  // ==================== CHANGER STATUT ====================
  Future<void> _changeStatus(int id, String statut) async {
    HapticFeedback.selectionClick();
    setState(() => _updatingId = id);
    try {
      await DoctorService().updateRendezvousStatus(id, statut);
      if (!mounted) return;
      _showSnack(
        'Statut changé en "${_statutLabel(statut)}"',
        bg: _green,
        icon: Icons.check_circle_rounded,
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        'Erreur: $e',
        bg: _red,
        icon: Icons.error_rounded,
      );
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        color: _bg,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: _primary,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildSearchBar()),
                SliverToBoxAdapter(child: _buildStatutFilters()),
                SliverToBoxAdapter(child: _buildPeriodeFilters()),
                SliverToBoxAdapter(child: _buildList()),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
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
                'Rendez-vous',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _text,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Gérez votre agenda de consultations',
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
              Icons.calendar_month_rounded,
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
              child: Container(
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
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un rendez-vous...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: _primary,
                    ),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ==================== FILTRES STATUT ====================
  Widget _buildStatutFilters() {
    final filters = <Map<String, dynamic>>[
      {'key': 'all', 'label': 'Tous', 'icon': Icons.apps_rounded, 'color': _muted},
      {'key': 'à_venir', 'label': 'À venir', 'icon': Icons.schedule_rounded, 'color': _blue},
      {'key': 'confirmé', 'label': 'Confirmés', 'icon': Icons.check_circle_rounded, 'color': _green},
      {'key': 'passé', 'label': 'Passés', 'icon': Icons.history_rounded, 'color': _grey},
      {'key': 'annulé', 'label': 'Annulés', 'icon': Icons.cancel_rounded, 'color': _red},
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
          final color = f['color'] as Color;
          final selected = _statutFilter == key;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _statutFilter = key);
                _reload();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
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
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: selected ? Colors.white : Colors.grey.shade700,
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

  // ==================== FILTRES PÉRIODE ====================
  Widget _buildPeriodeFilters() {
    final filters = <Map<String, String>>[
      {'key': 'all', 'label': 'Toute période'},
      {'key': 'today', 'label': 'Aujourd\'hui'},
      {'key': 'week', 'label': 'Cette semaine'},
      {'key': 'upcoming', 'label': 'À venir'},
      {'key': 'past', 'label': 'Passés'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, i) {
            final f = filters[i];
            final key = f['key']!;
            final label = f['label']!;
            final selected = _periodeFilter == key;

            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _periodeFilter = key);
                _reload();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? _primary.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? _primary : Colors.grey.shade300,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.w500,
                      color:
                          selected ? _primary : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== LISTE ====================
  Widget _buildList() {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(60),
            child: Center(
              child: CircularProgressIndicator(
                color: _primary,
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error);
        }

        final rdvs = snapshot.data ?? [];
        if (rdvs.isEmpty) {
          return _buildEmptyState();
        }

        return FadeTransition(
          opacity: _fadeController,
          child: Column(
            children: [
              // Compteur
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.event_available_rounded,
                        color: _primary,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${rdvs.length} rendez-vous',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _text,
                      ),
                    ),
                  ],
                ),
              ),
              // Cartes
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: List.generate(
                    rdvs.length,
                    (i) => TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 250 + (i * 40)),
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
                      child: _buildAppointmentCard(rdvs[i]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== CARTE RDV ====================
  Widget _buildAppointmentCard(dynamic r) {
    final statut = r['statut']?.toString();
    final statutColor = _statutColor(statut);
    final isUpdating = _updatingId == r['id'];

    final dateHeure = r['date_heure'] != null
        ? DateTime.tryParse(r['date_heure'].toString())
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: BorderSide(color: statutColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statutColor.withOpacity(0.20),
                        statutColor.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _statutIcon(statut),
                    color: statutColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['titre']?.toString() ?? 'Rendez-vous',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _text,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Badge statut
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statutColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: statutColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _statutIcon(statut),
                              size: 10,
                              color: statutColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _statutLabel(statut).toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: statutColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUpdating)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primary,
                    ),
                  )
                else
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: Colors.grey.shade600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (newStatut) {
                      if (newStatut != statut) {
                        _changeStatus(r['id'], newStatut);
                      }
                    },
                    itemBuilder: (_) => [
                      _buildStatutMenuItem('à_venir', statut),
                      _buildStatutMenuItem('confirmé', statut),
                      _buildStatutMenuItem('passé', statut),
                      _buildStatutMenuItem('annulé', statut),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 12),

            // Infos
            if (r['user'] != null)
              _buildInfoRow(
                Icons.person_rounded,
                'Patient',
                r['user']?['nom']?.toString() ?? 'Inconnu',
                _blue,
              ),
            if (dateHeure != null) ...[
              const SizedBox(height: 6),
              _buildInfoRow(
                Icons.schedule_rounded,
                'Date',
                _formatDateTime(dateHeure),
                _orange,
              ),
            ],
            
            if (r['lieu'] != null && r['lieu'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildInfoRow(
                Icons.location_on_rounded,
                'Lieu',
                r['lieu'].toString(),
                _red,
              ),
            ],
            if (r['motif'] != null && r['motif'].toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r['motif'].toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== MENU ITEM STATUT ====================
  PopupMenuItem<String> _buildStatutMenuItem(String value, String? current) {
    final color = _statutColor(value);
    final isCurrent = value == current;
    return PopupMenuItem<String>(
      value: value,
      enabled: !isCurrent,
      child: Row(
        children: [
          Icon(
            _statutIcon(value),
            color: isCurrent ? Colors.grey.shade400 : color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            _statutLabel(value),
            style: TextStyle(
              color: isCurrent ? Colors.grey.shade400 : _text,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          if (isCurrent) ...[
            const Spacer(),
            const Icon(Icons.check_rounded, color: _green, size: 16),
          ],
        ],
      ),
    );
  }

  // ==================== LIGNE INFO ====================
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: _muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              color: _text,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final prefix = isToday
        ? 'Aujourd\'hui'
        : '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    return '$prefix à ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ==================== EMPTY / ERROR ====================
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 56,
              color: _primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucun rendez-vous',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Essayez de modifier vos filtres',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: _red,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _muted),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}