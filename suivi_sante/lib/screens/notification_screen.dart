// lib/screens/notification_screen.dart
// Version: 4.2.0 - Design Ultra Professionnel & UI/UX Premium (Corrigé sans overflow)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:suivi_sante_pro/screens/dashboard_screen.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';
import '../services/logger_service.dart';

// ============================================================
// LOGGER
// ============================================================
class NotificationLogger {
  static const String _tag = '🔔 NOTIFICATIONS';

  static void info(String message) => LoggerService.info('$_tag ℹ️ $message');
  static void success(String message) =>
      LoggerService.success('$_tag ✅ $message');
  static void warning(String message) =>
      LoggerService.warning('$_tag ⚠️ $message');
  static void error(String message, {dynamic error}) =>
      LoggerService.error('$_tag ❌ $message', error: error);
  static void debug(String message) => LoggerService.debug('$_tag 🐛 $message');
  static void navigation(String message) =>
      LoggerService.info('$_tag 🧭 $message');
  static void action(String message) => LoggerService.info('$_tag 🎯 $message');
}

// ============================================================
// NOTIFICATION SCREEN
// ============================================================
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ANIMATIONS
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late AnimationController _pulseController;

  // ÉTATS
  bool _isInitialLoad = true;
  bool _isRefreshing = false;
  int _selectedTab = 0;
  String _searchQuery = '';

  // COULEURS
  late Color _primaryColor;
  late Color _surfaceColor;
  late Color _backgroundColor;
  late Color _textColor;
  late Color _textSecondaryColor;

  // TABS
  final List<Map<String, dynamic>> _tabs = [
    {'label': 'Toutes', 'icon': Iconsax.notification},
    {'label': 'Non lues', 'icon': Iconsax.notification_bing},
    {'label': 'Lues', 'icon': Iconsax.notification_status},
  ];

  @override
  void initState() {
    super.initState();
    NotificationLogger.info('🔔 Page Notifications initialisée');
    _initAnimations();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationLogger.info('🔄 App reprise - Rechargement');
      _loadNotifications();
    }
  }

  void _updateThemeColors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _primaryColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    _surfaceColor = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    _backgroundColor =
        isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight;
    _textColor = isDark ? AppTheme.textDark : AppTheme.textLight;
    _textSecondaryColor =
        isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 0.2, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  // CHARGEMENT
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      NotificationLogger.error('❌ Erreur récupération token: $e');
      return null;
    }
  }

  Future<void> _loadNotifications() async {
    NotificationLogger.info('🔄 Chargement des notifications...');
    final stopwatch = Stopwatch()..start();

    try {
      final token = await _getToken();
      if (token == null) {
        NotificationLogger.warning('⚠️ Token manquant - Redirection login');
        if (mounted) {
          _showSnackbar('Veuillez vous reconnecter', AppTheme.error);
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }
    } catch (e) {
      NotificationLogger.error('❌ Erreur vérification token: $e');
    }

    try {
      final provider =
          Provider.of<NotificationProvider>(context, listen: false);
      await provider.loadNotifications();

      stopwatch.stop();
      NotificationLogger.success(
        '✅ ${provider.notifications.length} notifications en ${stopwatch.elapsedMilliseconds}ms',
      );

      if (_isInitialLoad && mounted) {
        _isInitialLoad = false;
        _animationController.forward();
      }
    } catch (e) {
      NotificationLogger.error('❌ Erreur chargement: $e');
      if (mounted) {
        _showSnackbar('Erreur de chargement: $e', AppTheme.error);
      }
    }
  }

  Future<void> _refreshNotifications() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _loadNotifications();
    if (mounted) setState(() => _isRefreshing = false);
  }

  // ACTIONS
  void _onNotificationTap(
    Map<String, dynamic> notification,
    NotificationProvider provider,
  ) async {
    if (!notification['lu']) {
      await provider.markAsRead(notification['id']);
    }
  }

  Future<void> _markAsRead(
    Map<String, dynamic> notification,
    NotificationProvider provider,
  ) async {
    if (!notification['lu']) {
      await provider.markAsRead(notification['id']);
      _showSnackbar('Notification marquée comme lue', AppTheme.success);
    }
  }

  void _showMarkAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _surfaceColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Iconsax.tick_circle, color: _primaryColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tout marquer comme lu',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Voulez-vous marquer toutes les notifications comme lues ?',
          style: GoogleFonts.inter(fontSize: 15, color: _textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
                style: GoogleFonts.inter(color: _textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider =
                  Provider.of<NotificationProvider>(context, listen: false);
              await provider.markAllAsRead();
              _showSnackbar(
                'Toutes les notifications marquées comme lues',
                AppTheme.success,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Confirmer',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    Map<String, dynamic> notification,
    NotificationProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _surfaceColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Iconsax.trash, color: AppTheme.error, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Supprimer la notification',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Voulez-vous supprimer cette notification ?',
          style: GoogleFonts.inter(fontSize: 15, color: _textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
                style: GoogleFonts.inter(color: _textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteNotification(notification['id']);
              _showSnackbar('Notification supprimée', AppTheme.success);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Supprimer',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppTheme.success ? Iconsax.tick_circle : Iconsax.danger,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        elevation: 6,
      ),
    );
  }

  @override
  void dispose() {
    NotificationLogger.info('🗑️ Page Notifications disposée');
    _animationController.dispose();
    _pulseController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    _updateThemeColors(context);
    final provider = Provider.of<NotificationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(context, isDark, provider),
      body: _buildBody(provider, isDark),
    );
  }

  // APP BAR (CORRIGÉE)
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isDark,
    NotificationProvider provider,
  ) {
    final unreadCount = provider.nonLues;

    return AppBar(
      elevation: 0,
      backgroundColor: _surfaceColor,
      leadingWidth: 56,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(Iconsax.arrow_left, color: _primaryColor),
          onPressed: () {
            NotificationLogger.navigation('🔙 Retour au Dashboard');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          },
          tooltip: 'Retour au Dashboard',
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _primaryColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Iconsax.notification, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            // ✅ Expanded pour éviter le débordement du titre
            child: Text(
              'Notifications',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        if (unreadCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _showMarkAllDialog,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                backgroundColor: _primaryColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.tick_circle, size: 14, color: _primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    'Tout lire',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  // BODY
  Widget _buildBody(NotificationProvider provider, bool isDark) {
    if (provider.isLoading && _isInitialLoad) {
      return _buildLoadingScreen(isDark);
    }

    if (provider.error != null) {
      return _buildErrorScreen(provider.error!, isDark);
    }

    if (provider.notifications.isEmpty) {
      return _buildEmptyScreen(isDark);
    }

    return Column(
      children: [
        _buildStatsHeader(provider, isDark),
        _buildTabBar(isDark),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshNotifications,
            color: _primaryColor,
            backgroundColor: _surfaceColor,
            child: _buildNotificationList(provider, isDark),
          ),
        ),
      ],
    );
  }

  // STATS HEADER
  Widget _buildStatsHeader(NotificationProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: _surfaceColor,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${provider.notifications.length} notifications',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (provider.nonLues > 0)
                  Text(
                    '${provider.nonLues} non lue${provider.nonLues > 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.notification_bing,
                    size: 16, color: _primaryColor),
                const SizedBox(width: 6),
                Text(
                  '${provider.nonLues}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB BAR (CORRIGÉE)
  Widget _buildTabBar(bool isDark) {
    return Container(
      color: _surfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedTab == index;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < _tabs.length - 1 ? 6 : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedTab = index);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? _primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab['icon'],
                        size: 14, // ✅ Réduit
                        color:
                            isSelected ? Colors.white : _textSecondaryColor,
                      ),
                      const SizedBox(width: 4), // ✅ Réduit
                      Flexible(
                        // ✅ Flexible au lieu de laisser déborder
                        child: Text(
                          tab['label'],
                          style: GoogleFonts.inter(
                            fontSize: 11, // ✅ Réduit
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : _textSecondaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // LISTE
  Widget _buildNotificationList(NotificationProvider provider, bool isDark) {
    final filteredNotifications = _getFilteredNotifications(provider);

    if (filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.notification,
              size: 64,
              color: _textSecondaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Aucune notification ${_selectedTab == 0 ? '' : _tabs[_selectedTab]['label'].toLowerCase()}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: _textSecondaryColor,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredNotifications.length,
      itemBuilder: (context, index) {
        final notification = filteredNotifications[index];
        return _buildNotificationItem(notification, isDark, provider, index)
            .animate()
            .fadeIn(duration: 300.ms, delay: (index * 50).ms)
            .slideX(
              begin: 0.2,
              end: 0,
              duration: 300.ms,
              delay: (index * 50).ms,
            );
      },
    );
  }

  List<Map<String, dynamic>> _getFilteredNotifications(
    NotificationProvider provider,
  ) {
    return provider.notifications.where((notif) {
      switch (_selectedTab) {
        case 1:
          return !notif['lu'];
        case 2:
          return notif['lu'];
        default:
          return true;
      }
    }).toList();
  }

  // NOTIFICATION ITEM (CORRIGÉE)
  Widget _buildNotificationItem(
    Map<String, dynamic> notification,
    bool isDark,
    NotificationProvider provider,
    int index,
  ) {
    final isRead = notification['lu'] ?? false;
    final type = notification['type'] ?? 'info';
    final color = _getColorForType(type);

    final date = DateTime.parse(notification['created_at']);
    final formattedDate = _formatDate(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? _surfaceColor : _primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRead
              ? (isDark ? Colors.grey[800]! : Colors.grey[200]!)
              : _primaryColor.withOpacity(0.2),
          width: isRead ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: !isRead
                ? AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.2 + _pulseController.value * 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconForType(type),
                          color: Colors.white,
                          size: 20,
                        ),
                      );
                    },
                  )
                : Icon(_getIconForType(type), color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification['titre'] ?? 'Notification',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (!isRead)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification['message'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _textSecondaryColor,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Iconsax.clock,
                      size: 14,
                      color: _textSecondaryColor.withOpacity(0.5),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _textSecondaryColor.withOpacity(0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isRead)
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            child: IconButton(
                              icon: Icon(
                                Iconsax.tick_circle,
                                size: 18,
                                color: AppTheme.success,
                              ),
                              onPressed: () =>
                                  _markAsRead(notification, provider),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              splashRadius: 18,
                            ),
                          ),
                        IconButton(
                          icon: Icon(
                            Iconsax.close_circle,
                            size: 18,
                            color: _textSecondaryColor.withOpacity(0.3),
                          ),
                          onPressed: () =>
                              _showDeleteDialog(notification, provider),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // UTILITAIRES
  IconData _getIconForType(String? type) {
    switch (type) {
      case 'success':
        return Iconsax.tick_circle;
      case 'warning':
        return Iconsax.danger;
      case 'error':
        return Iconsax.close_circle;
      case 'appointment':
        return Iconsax.calendar;
      case 'medication':
        return Iconsax.health;
      case 'health':
        return Iconsax.health;
      default:
        return Iconsax.info_circle;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'success':
        return AppTheme.success;
      case 'warning':
        return AppTheme.warning;
      case 'error':
        return AppTheme.error;
      case 'appointment':
        return AppTheme.info;
      case 'medication':
        return const Color(0xFF8B5CF6);
      case 'health':
        return const Color(0xFFEC4899);
      default:
        return _primaryColor;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) return 'À l\'instant';
        return 'Il y a ${diff.inMinutes} min';
      }
      return 'Il y a ${diff.inHours} h';
    } else if (diff.inDays == 1) {
      return 'Hier à ${_formatTime(date)}';
    } else if (diff.inDays < 7) {
      final weekdays = [
        'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
      ];
      return '${weekdays[date.weekday - 1]} à ${_formatTime(date)}';
    } else {
      final months = [
        'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year} à ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // LOADING
  Widget _buildLoadingScreen(bool isDark) {
    return Center(
      child: Shimmer.fromColors(
        baseColor: _textSecondaryColor.withOpacity(0.1),
        highlightColor: _textSecondaryColor.withOpacity(0.05),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryColor, _primaryColor.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chargement des notifications...',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // EMPTY
  Widget _buildEmptyScreen(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryColor.withOpacity(0.1),
                    _primaryColor.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.notification,
                size: 72,
                color: _primaryColor.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune notification',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vous serez notifié des événements importants\nconcernant votre santé',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _textSecondaryColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _primaryColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(
                          0.3 + _pulseController.value * 0.2,
                        ),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _refreshNotifications,
                    icon: const Icon(Iconsax.refresh, color: Colors.white),
                    label: Text(
                      'Rafraîchir',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ERROR (CORRIGÉE)
  Widget _buildErrorScreen(String error, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.danger, size: 64, color: AppTheme.error),
            ),
            const SizedBox(height: 24),
            Text(
              'Une erreur est survenue',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _textSecondaryColor,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loadNotifications,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      'Réessayer',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/dashboard'),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: Text(
                      'Dashboard',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
  }
}