import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/doctor_service.dart';

class DoctorHistoryScreen extends StatefulWidget {
  const DoctorHistoryScreen({super.key});

  @override
  State<DoctorHistoryScreen> createState() => _DoctorHistoryScreenState();
}

class _DoctorHistoryScreenState extends State<DoctorHistoryScreen> {
  late Future<List<dynamic>> _future;
  String _filter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = DoctorService().getHistorique();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = DoctorService().getHistorique();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildSearchBar(isDark),
            _buildFilters(isDark),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00B894),
                        strokeWidth: 2.5,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error, isDark);
                  }

                  final allEvents = snapshot.data ?? [];
                  
                  // Filtrage combiné (Catégorie + Recherche textuelle)
                  final filteredEvents = allEvents.where((e) {
                    final matchesFilter = _filter == 'all' || e['type'] == _filter;
                    final title = (e['titre'] ?? '').toString().toLowerCase();
                    final desc = (e['description'] ?? '').toString().toLowerCase();
                    final matchesSearch = _searchQuery.isEmpty ||
                        title.contains(_searchQuery) ||
                        desc.contains(_searchQuery);
                    return matchesFilter && matchesSearch;
                  }).toList();

                  if (filteredEvents.isEmpty) {
                    return _buildEmptyState(isDark);
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    color: const Color(0xFF00B894),
                    backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                      itemCount: filteredEvents.length,
                      itemBuilder: (context, i) {
                        return _buildTimelineItem(
                          filteredEvents[i],
                          isFirst: i == 0,
                          isLast: i == filteredEvents.length - 1,
                          isDark: isDark,
                        ).animate().fadeIn(delay: (i * 50).ms).slideX(begin: 0.1);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : const Color(0xFF2D3436),
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.grey[800] : Colors.white,
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              shadowColor: Colors.black.withOpacity(0.05),
              elevation: 1,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historique médical',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF2D3436),
                  ),
                ),
                Text(
                  'Suivi chronologique des événements',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reload,
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.grey[800] : Colors.white,
              foregroundColor: isDark ? Colors.white : Colors.grey[700],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              shadowColor: Colors.black.withOpacity(0.05),
              elevation: 1,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  // ==================== SEARCH BAR ====================
  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.inter(
            fontSize: 14, 
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Rechercher un événement...',
            hintStyle: GoogleFonts.inter(
              fontSize: 14, 
              color: Colors.grey.shade500,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey.shade500,
              size: 22,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade500),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  // ==================== FILTRES ====================
  Widget _buildFilters(bool isDark) {
    final filters = [
      {'key': 'all', 'label': 'Tout', 'icon': Icons.apps_rounded},
      {'key': 'rendez_vous', 'label': 'RDV', 'icon': Icons.calendar_month_rounded},
      {'key': 'prescription', 'label': 'Ordonnances', 'icon': Icons.medication_rounded},
      {'key': 'symptome', 'label': 'Symptômes', 'icon': Icons.warning_rounded},
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
          final selected = _filter == f['key'];

          return GestureDetector(
            onTap: () => setState(() => _filter = f['key'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF00B894)
                    : (isDark ? Colors.grey[800] : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: selected
                    ? null
                    : Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                        width: 1.5,
                      ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00B894).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    f['icon'] as IconData,
                    size: 16,
                    color: selected ? Colors.white : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    f['label'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                      color: selected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  // ==================== TIMELINE ITEM ====================
  Widget _buildTimelineItem(
    dynamic event, {
    required bool isFirst,
    required bool isLast,
    required bool isDark,
  }) {
    final color = _parseColor(event['couleur']);
    final DateTime date;
    
    try {
      date = DateTime.parse(event['date']).toLocal();
    } catch (_) {
      return const SizedBox.shrink();
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Colonne de la timeline (Ligne + Point)
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: isFirst ? 10 : 0,
                  color: isFirst ? Colors.transparent : color.withOpacity(0.2),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Icon(_getIcon(event['icone']), size: 16, color: color),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : color.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
          
          // Carte de l'événement
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ],
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatDate(date),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      if (event['statut'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event['statut'].toString().toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event['titre'] ?? '',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event['description'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== EMPTY & ERROR STATES ====================
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Icon(
              Icons.history_toggle_off_rounded,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun événement trouvé',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos filtres',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ).animate().fadeIn().scale(),
    );
  }

  Widget _buildErrorState(Object? error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 70, color: Colors.red.shade300),
            const SizedBox(height: 20),
            Text(
              'Oups, une erreur est survenue',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Réessayer', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B894),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(),
    );
  }

  // ==================== HELPERS ====================
  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(d.year, d.month, d.day);

    String dayLabel;
    if (dateOnly == today) {
      dayLabel = "Aujourd'hui";
    } else if (dateOnly == yesterday) {
      dayLabel = 'Hier';
    } else {
      dayLabel = DateFormat('dd MMM yyyy', 'fr_FR').format(d);
    }

    return '$dayLabel • ${DateFormat('HH:mm').format(d)}';
  }

  Color _parseColor(String? hex) {
    if (hex == null) return const Color(0xFF00B894);
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFF00B894);
    }
  }

  IconData _getIcon(String? name) {
    switch (name) {
      case 'calendar': return Icons.calendar_today_rounded;
      case 'medication': return Icons.medication_rounded;
      case 'warning': return Icons.warning_rounded;
      default: return Icons.info_rounded;
    }
  }
}