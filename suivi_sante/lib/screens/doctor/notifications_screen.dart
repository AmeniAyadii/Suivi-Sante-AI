import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:suivi_sante_pro/services/doctor/notification_service.dart';
import '../../models/app_notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _error;
  int _selectedFilter = 0; // 0 = Toutes, 1 = Non lues

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.getNotifications(
        lu: _selectedFilter == 1 ? false : null,
      );
      if (!mounted) return;
      setState(() {
        _notifications =
            List<AppNotification>.from(result['notifications'] as List);
        _unreadCount = result['non_lues'] as int;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _markAsRead(AppNotification n) async {
    if (n.lu) return;
    final ok = await _service.markAsRead(n.id);
    if (ok) {
      setState(() {
        final idx = _notifications.indexWhere((x) => x.id == n.id);
        if (idx >= 0) {
          _notifications[idx] = n.copyWith(lu: true);
        }
        _unreadCount = (_unreadCount - 1).clamp(0, 9999);
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final ok = await _service.markAllAsRead();
    if (ok) {
      await _load();
      _showSnackbar('Toutes les notifications sont marquées comme lues');
    }
  }

  Future<void> _delete(AppNotification n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer la notification ?'),
        content: Text(n.titre),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await _service.deleteNotification(n.id);
    if (ok) {
      setState(() {
        _notifications.removeWhere((x) => x.id == n.id);
        if (!n.lu) _unreadCount = (_unreadCount - 1).clamp(0, 9999);
      });
      _showSnackbar('Notification supprimée');
    }
  }

  void _showSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ============ BUILD ============
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
            _buildSegmentedControl(isDark),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError(isDark)
                      : _notifications.isEmpty
                          ? _buildEmpty(isDark)
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: const Color(0xFF0984E3),
                              backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                              child: _buildGroupedList(isDark),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ HEADER ============
  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black87,
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
                  'Notifications',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF2D3436),
                  ),
                ),
                Text(
                  _unreadCount > 0 ? '$_unreadCount non lue${_unreadCount > 1 ? 's' : ''}' : 'Tout est à jour',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _unreadCount > 0 ? const Color(0xFF0984E3) : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_unreadCount > 0)
            IconButton(
              tooltip: 'Tout marquer comme lu',
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF0984E3).withOpacity(0.1),
                foregroundColor: const Color(0xFF0984E3),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Rafraîchir',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
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
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  // ============ SEGMENTED CONTROL ============
  Widget _buildSegmentedControl(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _buildSegmentTab('Toutes', 0, isDark),
            _buildSegmentTab('Non lues', 1, isDark),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSegmentTab(String label, int index, bool isDark) {
    final isSelected = _selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedFilter != index) {
            setState(() => _selectedFilter = index);
            _load();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF2D3436) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF2D3436))
                    : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============ LISTE GROUPÉE ============
  Widget _buildGroupedList(bool isDark) {
    // Grouper les notifications par date (Aujourd'hui, Hier, Plus tôt)
    final Map<String, List<AppNotification>> grouped = {};
    for (var n in _notifications) {
      final date = n.dateEnvoi ?? n.createdAt;
      final now = DateTime.now();
      final diffDays = now.difference(date).inDays;

      String key;
      if (diffDays == 0) {
        key = "Aujourd'hui";
      } else if (diffDays == 1) {
        key = 'Hier';
      } else {
        key = 'Plus tôt';
      }
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(n);
    }

    final List<Widget> listItems = [];
    int globalIndex = 0;

    grouped.forEach((dateLabel, items) {
      listItems.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            dateLabel.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      );
      for (var item in items) {
        listItems.add(
          _buildNotificationTile(item, isDark).animate().fadeIn(
                delay: (globalIndex * 50).ms,
                duration: 400.ms,
              ).slideX(begin: 0.05, end: 0),
        );
        globalIndex++;
      }
    });

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: listItems,
    );
  }

  // ============ TILE ============
  Widget _buildNotificationTile(AppNotification n, bool isDark) {
    final color = _parseColor(n.couleur) ?? _colorFromType(n.type);
    final isUnread = !n.lu;

    // Couleurs de fond conditionnelles
    final cardBg = isUnread
        ? (isDark ? const Color(0xFF1E1E1E) : Colors.white)
        : (isDark ? const Color(0xFF161616) : Colors.white.withOpacity(0.6));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Dismissible(
        key: ValueKey(n.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
        ),
        onDismissed: (_) => _delete(n),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _markAsRead(n),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (isUnread)
                    BoxShadow(
                      color: color.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
                border: Border.all(
                  color: isUnread
                      ? color.withOpacity(0.3)
                      : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône avec cercle coloré
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(isUnread ? 0.15 : 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconFromString(n.icon) ?? Icons.notifications_rounded,
                      color: isUnread ? color : Colors.grey,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Contenu
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                n.titre,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isUnread)
                              Container(
                                margin: const EdgeInsets.only(left: 8, top: 4),
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    )
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          n.message,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.4,
                            color: isUnread
                                ? (isDark ? Colors.grey[300] : Colors.grey[800])
                                : Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(n.dateEnvoi ?? n.createdAt),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============ EMPTY & ERROR ============
  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
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
              Icons.notifications_off_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedFilter == 1 ? 'Aucune notification non lue' : 'Boîte de réception vide',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous êtes à jour !',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ).animate().fadeIn().scale(),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 70, color: Colors.red.shade300),
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
              _error ?? 'Impossible de charger les notifications.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Réessayer', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0984E3),
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

  // ============ HELPERS ============
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return DateFormat('dd/MM/yyyy à HH:mm').format(date);
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final value = hex.replaceAll('#', '');
      return Color(int.parse('FF$value', radix: 16));
    } catch (_) {
      return null;
    }
  }

  Color _colorFromType(String type) {
    switch (type) {
      case 'success':
        return const Color(0xFF00B894);
      case 'warning':
        return const Color(0xFFFDCB6E);
      case 'error':
        return const Color(0xFFD63031);
      case 'appointment':
        return const Color(0xFF0984E3);
      default:
        return const Color(0xFF6C5CE7);
    }
  }

  IconData? _iconFromString(String? name) {
    if (name == null) return null;
    switch (name) {
      case 'calendar_today':
        return Icons.calendar_month_rounded;
      case 'check_circle':
        return Icons.check_circle_rounded;
      case 'warning':
        return Icons.warning_rounded;
      case 'error':
        return Icons.error_rounded;
      case 'info':
        return Icons.info_rounded;
      case 'medication':
        return Icons.medication_rounded;
      case 'person':
        return Icons.person_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}