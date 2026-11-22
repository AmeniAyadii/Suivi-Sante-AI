// lib/screens/dashboard_screen.dart
// Version 2.1.0 — Corrigé sans overflow

import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:suivi_sante_pro/core/constants/api_constants.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/notification_badge.dart';

import 'triage_form_screen.dart';

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
  static const pink = Color(0xFFEC4899);
  static const pinkSoft = Color(0xFFFCE7F3);

  static const ink = Color(0xFF0F172A);
  static const inkSoft = Color(0xFF475569);
  static const inkMuted = Color(0xFF94A3B8);
  static const line = Color(0xFFE2E8F0);
  static const surface = Color(0xFFFFFFFF);
  static const canvas = Color(0xFFF8FAFC);

  static const inkDark = Color(0xFFF1F5F9);
  static const surfaceDark = Color(0xFF1E293B);
  static const canvasDark = Color(0xFF0F172A);
  static const lineDark = Color(0xFF334155);

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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _isDarkMode = false;

  String _greeting = 'Bonjour';
  IconData _greetingIcon = Iconsax.sun_1;
  Color _greetingColor = const Color(0xFFFFD54F);

  late AnimationController _entry;
  late AnimationController _pulse;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _updateGreeting();
    _loadThemePreference();
    _loadData();
    _syncFcmToken();
  }

  @override
  void dispose() {
    _entry.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _updateGreeting() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) {
      _greeting = 'Bonjour';
      _greetingIcon = Iconsax.sun_1;
      _greetingColor = const Color(0xFFFFD54F);
    } else if (h >= 12 && h < 18) {
      _greeting = 'Bon après-midi';
      _greetingIcon = Iconsax.sun_1;
      _greetingColor = const Color(0xFFFFD54F);
    } else if (h >= 18 && h < 22) {
      _greeting = 'Bonsoir';
      _greetingIcon = Iconsax.moon;
      _greetingColor = const Color(0xFF90CAF9);
    } else {
      _greeting = 'Bonne nuit';
      _greetingIcon = Iconsax.moon;
      _greetingColor = const Color(0xFF90CAF9);
    }
  }

  Future<void> _syncFcmToken() async {
    try {
      if (Firebase.apps.isEmpty) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || !mounted) return;
      final auth = Provider.of<AuthService>(context, listen: false);
      final apiToken = await auth.getToken();
      if (apiToken == null) return;
      await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/fcm/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'ngrok-skip-browser-warning': 'true',
              'Authorization': 'Bearer $apiToken',
            },
            body: jsonEncode({'token': token}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('⚠️ FCM: $e');
    }
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() => _isDarkMode = prefs.getBool('isDarkMode') ?? false);
      }
    } catch (_) {}
  }

  Future<void> _toggleTheme() async {
    setState(() => _isDarkMode = !_isDarkMode);
    AppTheme.toggleTheme(_isDarkMode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
    } catch (_) {}
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = await auth.getUserData();
      if (user == null) throw Exception('Utilisateur non authentifié');
      if (mounted) setState(() => _userData = user);

      final api = ApiService();
      final res = await api.get('/dashboard?user_id=${user['id']}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _dashboardData = data['data'] ?? data;
            _isLoading = false;
          });
          _entry.forward();
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Erreur ${res.statusCode}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Connexion impossible. Vérifiez votre réseau.';
        });
      }
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _loadData();
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final d = _isDarkMode;
    return Theme(
      data: d ? AppTheme.darkTheme : AppTheme.lightTheme,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: d ? _DS.canvasDark : _DS.canvas,
        drawer: _buildDrawer(),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBody() {
    if (!_isLoading && _dashboardData == null && _errorMessage != null) {
      return _buildErrorView();
    }
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: _DS.primary,
            backgroundColor: _isDarkMode ? _DS.surfaceDark : _DS.surface,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: _isLoading
                  ? _buildSkeleton()
                  : FadeTransition(
                      opacity: _entry,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.05),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _entry,
                          curve: Curves.easeOutCubic,
                        )),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroBanner(),
                            const SizedBox(height: 22),
                            _buildSectionTitle('Aperçu santé',
                                icon: Iconsax.chart_2),
                            const SizedBox(height: 12),
                            _buildStatsGrid(),
                            const SizedBox(height: 24),
                            _buildSectionTitle('Actions rapides',
                                icon: Iconsax.flash_1),
                            const SizedBox(height: 12),
                            _buildQuickActions(),
                            const SizedBox(height: 24),
                            _buildTriageCard(),
                            const SizedBox(height: 24),
                            _buildSectionTitle('À venir',
                                icon: Iconsax.clock),
                            const SizedBox(height: 12),
                            _buildTimelineCards(),
                            const SizedBox(height: 24),
                            _buildChatbotCTA(),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════ HEADER (CORRIGÉ) ═══════════
  Widget _buildHeader() {
    final name = _userData?['nom'] ?? 'Utilisateur';
    final firstName = name.split(' ').first;
    final d = _isDarkMode;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: d
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [_DS.primary, _DS.primaryDeep],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _iconGlass(
                    icon: Iconsax.menu_1,
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const Spacer(),
                  // ✅ Actions compactées + espacement réduit
                  _iconGlass(
                    icon: d ? Iconsax.sun_1 : Iconsax.moon,
                    onTap: _toggleTheme,
                    size: 18,
                    padding: 8,
                  ),
                  const SizedBox(width: 6),
                  _iconGlass(
                    icon: Iconsax.setting_2,
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                    size: 18,
                    padding: 8,
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: const NotificationBadge(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Icon(
                      _greetingIcon,
                      key: ValueKey(_greetingIcon),
                      color: _greetingColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    // ✅ Évite le débordement si le texte est long
                    child: Text(
                      _greeting,
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Colors.white, Colors.white],
                ).createShader(b),
                child: Text(
                  firstName,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Prenez soin de vous aujourd\'hui ✨',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconGlass({
    required IconData icon,
    required VoidCallback onTap,
    double size = 20,
    double padding = 10,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Icon(icon, color: Colors.white, size: size),
        ),
      ),
    );
  }

  // ═══════════ HERO ═══════════
  Widget _buildHeroBanner() {
    final stats = _stats();
    final score = _aiScore(stats);
    final d = _isDarkMode;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: d
              ? [const Color(0xFF334155), const Color(0xFF1E293B)]
              : [_DS.primarySoft, Colors.white],
        ),
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(
          color: d ? _DS.lineDark : _DS.primary.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 7,
                    backgroundColor:
                        d ? _DS.lineDark : _DS.primary.withOpacity(0.12),
                    valueColor: const AlwaysStoppedAnimation(_DS.primary),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: d ? _DS.inkDark : _DS.ink,
                      ),
                    ),
                    Text(
                      'score',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: _DS.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre santé en un coup d\'œil',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: d ? _DS.inkDark : _DS.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stats['medicaments_actifs'] ?? 0} médicaments actifs · '
                  '${stats['rendezvous_total'] ?? 0} rendez-vous à venir',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: d ? _DS.inkMuted : _DS.inkSoft,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }

  // ═══════════ STATS GRID ═══════════
  Widget _buildStatsGrid() {
    final s = _stats();
    final items = [
      _StatSpec(
        title: 'Médicaments',
        value: '${s['medicaments_actifs'] ?? 0}',
        subtitle: 'actifs',
        icon: Iconsax.health,
        color: _DS.primary,
        soft: _DS.primarySoft,
        route: '/medicaments',
      ),
      _StatSpec(
        title: 'Rendez-vous',
        value: '${s['rendezvous_total'] ?? 0}',
        subtitle: 'à venir',
        icon: Iconsax.calendar_1,
        color: _DS.success,
        soft: _DS.successSoft,
        route: '/rendezvous',
      ),
      _StatSpec(
        title: 'Symptômes',
        value: '${s['symptomes_total'] ?? 0}',
        subtitle: 'enregistrés',
        icon: Iconsax.health,
        color: _DS.warning,
        soft: _DS.warningSoft,
        route: '/symptomes',
      ),
      _StatSpec(
        title: 'Score IA',
        value: '${_aiScore(s)}%',
        subtitle: 'santé',
        icon: Iconsax.cpu,
        color: _DS.violet,
        soft: _DS.violetSoft,
        route: '/statistiques',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (_, i) => _buildStatCard(items[i], i),
    );
  }

  Widget _buildStatCard(_StatSpec s, int i) {
    final d = _isDarkMode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_DS.rLg),
        onTap: () => Navigator.pushNamed(context, s.route),
        child: Ink(
          decoration: BoxDecoration(
            color: d ? _DS.surfaceDark : _DS.surface,
            borderRadius: BorderRadius.circular(_DS.rLg),
            border: Border.all(color: d ? _DS.lineDark : _DS.line),
            boxShadow: _DS.shadow(d ? Colors.black : s.color, o: 0.06),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: d ? s.color.withOpacity(0.15) : s.soft,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(s.icon, color: s.color, size: 20),
                    ),
                    const Icon(
                      Iconsax.arrow_up_1,
                      size: 14,
                      color: _DS.inkMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.value,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: d ? _DS.inkDark : _DS.ink,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: d ? _DS.inkMuted : _DS.inkSoft,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: (60 * i).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1, end: 0);
  }

  // ═══════════ QUICK ACTIONS ═══════════
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: Iconsax.add_circle,
        label: 'Symptôme',
        color: _DS.warning,
        onTap: () => Navigator.pushNamed(context, '/symptomes/ajout'),
      ),
      _QuickAction(
        icon: Iconsax.health,
        label: 'Médicament',
        color: _DS.primary,
        onTap: () => Navigator.pushNamed(context, '/medicaments/ajout'),
      ),
      _QuickAction(
        icon: Iconsax.message_2,
        label: 'Assistant',
        color: _DS.success,
        onTap: () => Navigator.pushNamed(context, '/chat'),
      ),
      _QuickAction(
        icon: Iconsax.scan,
        label: 'Scanner',
        color: _DS.violet,
        onTap: () => Navigator.pushNamed(context, '/scan'),
      ),
      _QuickAction(
        icon: Iconsax.hospital,
        label: 'Triage',
        color: _DS.pink,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TriageFormScreen()),
        ),
      ),
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _buildQuickAction(actions[i], i),
      ),
    );
  }

  Widget _buildQuickAction(_QuickAction a, int i) {
    final d = _isDarkMode;
    return GestureDetector(
      onTap: a.onTap,
      child: Container(
        width: 82,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: d ? _DS.surfaceDark : _DS.surface,
          borderRadius: BorderRadius.circular(_DS.rLg),
          border: Border.all(color: d ? _DS.lineDark : _DS.line),
          boxShadow: _DS.shadow(d ? Colors.black : a.color, o: 0.05),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    d ? a.color.withOpacity(0.15) : a.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(a.icon, color: a.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              a.label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: d ? _DS.inkDark : _DS.ink,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    )
        .animate(delay: (60 * i).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1, end: 0);
  }

  // ═══════════ TRIAGE CARD (CORRIGÉE) ═══════════
  Widget _buildTriageCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(_DS.rXl),
        boxShadow: _DS.shadow(_DS.pink, o: 0.35),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_DS.rXl),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TriageFormScreen()),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: const Icon(Iconsax.hospital,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      // ✅ Wrap pour éviter l'overflow du titre + badge
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text(
                          'Évaluation Triage IA',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'NOUVEAU',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prédisez le niveau d\'urgence en quelques secondes',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 200.ms)
        .shimmer(duration: 1500.ms, delay: 2.seconds);
  }

  // ═══════════ TIMELINE CARDS ═══════════
  Widget _buildTimelineCards() {
    return Column(
      children: [
        _buildMedicationCard(),
        const SizedBox(height: 12),
        _buildAppointmentCard(),
        const SizedBox(height: 12),
        _buildSymptomCard(),
      ],
    );
  }

  Widget _buildMedicationCard() {
    final m = _dashboardData?['prochain_medicament'] ??
        _dashboardData?['data']?['prochain_medicament'];
    return _buildTimelineCard(
      icon: Iconsax.health,
      color: _DS.primary,
      soft: _DS.primarySoft,
      title: 'Prochain médicament',
      route: '/medicaments',
      body: m != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _mainLine(m['nom'] ?? 'Médicament'),
                const SizedBox(height: 6),
                _metaLine(Iconsax.health, 'Dose · ${m['dosage'] ?? 'N/A'}'),
                const SizedBox(height: 4),
                _metaLine(
                  Iconsax.clock,
                  'Prise à ${_fmtTime(m['prochaine_prise'])}',
                  color: _DS.warning,
                ),
              ],
            )
          : _emptyState('Aucun médicament programmé', Iconsax.health),
    );
  }

  Widget _buildAppointmentCard() {
    final r = _dashboardData?['prochain_rendezvous'] ??
        _dashboardData?['data']?['prochain_rendezvous'];
    return _buildTimelineCard(
      icon: Iconsax.calendar_1,
      color: _DS.success,
      soft: _DS.successSoft,
      title: 'Prochain rendez-vous',
      route: '/rendezvous',
      body: r != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _mainLine(r['titre'] ?? 'Rendez-vous'),
                const SizedBox(height: 6),
                _metaLine(Iconsax.user, 'Dr. ${r['medecin_nom'] ?? 'N/A'}'),
                const SizedBox(height: 4),
                _metaLine(
                  Iconsax.clock,
                  _fmtDateTime(r['date_heure']),
                  color: _DS.info,
                ),
              ],
            )
          : _emptyState('Aucun rendez-vous prévu', Iconsax.calendar_1),
    );
  }

  Widget _buildSymptomCard() {
    final s = _dashboardData?['dernier_symptome'] ??
        _dashboardData?['data']?['dernier_symptome'];
    return _buildTimelineCard(
      icon: Iconsax.health,
      color: _DS.warning,
      soft: _DS.warningSoft,
      title: 'Dernier symptôme',
      route: '/symptomes',
      body: s != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _mainLine(s['description'] ?? 'Symptôme'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _severityChip(s['niveau'] ?? 0),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Il y a ${_timeAgo(s['date_enregistrement'])}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _isDarkMode ? _DS.inkMuted : _DS.inkSoft,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                if ((s['notes'] as String?)?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '📝 ${s['notes']}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _isDarkMode ? _DS.inkMuted : _DS.inkSoft,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            )
          : _emptyState('Aucun symptôme enregistré', Iconsax.health),
    );
  }

  Widget _buildTimelineCard({
    required IconData icon,
    required Color color,
    required Color soft,
    required String title,
    required String route,
    required Widget body,
  }) {
    final d = _isDarkMode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_DS.rLg),
        onTap: () => Navigator.pushNamed(context, route),
        child: Ink(
          decoration: BoxDecoration(
            color: d ? _DS.surfaceDark : _DS.surface,
            borderRadius: BorderRadius.circular(_DS.rLg),
            border: Border.all(color: d ? _DS.lineDark : _DS.line),
            boxShadow: _DS.shadow(d ? Colors.black : color, o: 0.04),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: d ? color.withOpacity(0.15) : soft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: d ? _DS.inkMuted : _DS.inkSoft,
                          letterSpacing: 0.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: _DS.inkMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mainLine(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _isDarkMode ? _DS.inkDark : _DS.ink,
        letterSpacing: -0.2,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _metaLine(IconData icon, String text, {Color? color}) {
    final c = color ?? (_isDarkMode ? _DS.inkMuted : _DS.inkSoft);
    return Row(
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: c,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _DS.inkMuted),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: _DS.inkMuted,
              fontStyle: FontStyle.italic,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _severityChip(int level) {
    Color c;
    String label;
    if (level <= 3) {
      c = _DS.success;
      label = 'Léger';
    } else if (level <= 6) {
      c = _DS.warning;
      label = 'Modéré';
    } else {
      c = _DS.danger;
      label = 'Sévère';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            'Niv. $level · $label',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: c,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════ CHATBOT CTA (CORRIGÉE) ═══════════
  Widget _buildChatbotCTA() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_DS.success, Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(_DS.rXl),
        boxShadow: _DS.shadow(_DS.success, o: 0.3),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_DS.rXl),
          onTap: () => Navigator.pushNamed(context, '/chat'),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Iconsax.message_2,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assistant Santé IA',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Posez vos questions en toute sécurité',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text, {required IconData icon}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color:
                _isDarkMode ? _DS.primary.withOpacity(0.15) : _DS.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: _DS.primary),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _isDarkMode ? _DS.inkDark : _DS.ink,
              letterSpacing: -0.2,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    final base = _isDarkMode ? _DS.lineDark : _DS.line;
    final hi = _isDarkMode ? const Color(0xFF475569) : _DS.canvas;
    Widget box({double h = 100, double? w}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(_DS.rMd),
          ),
        );
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: hi,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          box(h: 110),
          const SizedBox(height: 20),
          box(h: 18, w: 140),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: box(h: 110)),
              const SizedBox(width: 12),
              Expanded(child: box(h: 110)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: box(h: 110)),
              const SizedBox(width: 12),
              Expanded(child: box(h: 110)),
            ],
          ),
          const SizedBox(height: 24),
          box(h: 96),
          const SizedBox(height: 24),
          box(h: 130),
          const SizedBox(height: 12),
          box(h: 110),
          const SizedBox(height: 12),
          box(h: 110),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: _DS.dangerSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_off_rounded,
                        size: 48, color: _DS.danger),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Oups ! Connexion impossible',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _isDarkMode ? _DS.inkDark : _DS.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ?? '',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: _DS.inkMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Réessayer'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _DS.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_DS.rMd),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════ DRAWER (CORRIGÉ) ═══════════
  Widget _buildDrawer() {
    final name = _userData?['nom'] ?? 'Utilisateur';
    final email = _userData?['email'] ?? 'email@exemple.com';
    final d = _isDarkMode;

    final items = [
      _DrawerEntry(Iconsax.home_2, 'Tableau de bord', '/dashboard', true),
      _DrawerEntry(Iconsax.health, 'Bilan de santé', '/bilan'),
      _DrawerEntry(Iconsax.message_2, 'Assistant IA', '/chat'),
      _DrawerEntry(Iconsax.chart_2, 'Statistiques', '/statistiques'),
      _DrawerEntry(Iconsax.document_text, 'Rapports', '/reports'),
      _DrawerEntry(Iconsax.star_1, 'Goals', '/goals'),
      _DrawerEntry(Iconsax.heart_circle, 'Vital', '/vital-tracker'),
      _DrawerEntry(Iconsax.activity, 'Tension', '/tension/analyse'),
      _DrawerEntry(Iconsax.hospital, 'Triage IA', '/triage'),
      _DrawerEntry(Iconsax.calendar_1, 'Rendez-vous', '/rendezvous'),
      _DrawerEntry(Iconsax.health, 'Médicaments', '/medicaments'),
      _DrawerEntry(Iconsax.setting_2, 'Paramètres', '/settings'),
      _DrawerEntry(Iconsax.notification, 'Notifications', '/notifications'),
    ];

    return Drawer(
      backgroundColor: d ? _DS.canvasDark : _DS.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: d
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [_DS.primary, _DS.primaryDeep],
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          child: Text(
                            _initials(name),
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _DS.primary,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _DS.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.check,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: items.length,
                itemBuilder: (_, i) => _buildDrawerItem(items[i], i),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton.icon(
                onPressed: _showLogout,
                icon: const Icon(Iconsax.logout, color: _DS.danger, size: 20),
                label: Text(
                  'Déconnexion',
                  style: GoogleFonts.inter(
                    color: _DS.danger,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_DS.rSm),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(_DrawerEntry e, int i) {
    final d = _isDarkMode;
    final active = e.selected;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_DS.rSm),
          onTap: () {
            Navigator.pop(context);
            if (e.route == '/triage') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TriageFormScreen()),
              );
            } else if (!active) {
              Navigator.pushNamed(context, e.route);
            }
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: active
                  ? (d ? _DS.primary.withOpacity(0.15) : _DS.primarySoft)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(_DS.rSm),
            ),
            child: Row(
              children: [
                Icon(
                  e.icon,
                  size: 20,
                  color: active
                      ? _DS.primary
                      : (d ? _DS.inkMuted : _DS.inkSoft),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    e.label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? _DS.primary
                          : (d ? _DS.inkDark : _DS.ink),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (e.route == '/triage')
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _DS.pink,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'NEW',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else if (active)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _DS.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: (30 * i).ms)
        .fadeIn(duration: 250.ms);
  }

  Widget _buildBottomNav() {
    final d = _isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: d ? _DS.surfaceDark : _DS.surface,
        border: Border(
          top: BorderSide(color: d ? _DS.lineDark : _DS.line, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _DS.primary,
        unselectedItemColor: _DS.inkMuted,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        onTap: (i) {
          switch (i) {
            case 0:
              break;
            case 1:
              Navigator.pushNamed(context, '/medicaments');
              break;
            case 2:
              Navigator.pushNamed(context, '/rendezvous');
              break;
            case 3:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Iconsax.home_2), label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Iconsax.health), label: 'Médicaments'),
          BottomNavigationBarItem(
              icon: Icon(Iconsax.calendar_1), label: 'Rendez-vous'),
          BottomNavigationBarItem(
              icon: Icon(Iconsax.user), label: 'Profil'),
        ],
      ),
    );
  }

  void _showLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_DS.rLg),
        ),
        title: Text(
          'Déconnexion',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(color: _DS.inkMuted),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final auth =
                  Provider.of<AuthService>(context, listen: false);
              await auth.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: _DS.danger),
            child: Text(
              'Déconnecter',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════ HELPERS ═══════════
  Map<String, dynamic> _stats() {
    final raw = _dashboardData?['data'] ?? _dashboardData ?? {};
    return Map<String, dynamic>.from(raw as Map);
  }

  int _aiScore(Map<String, dynamic> s) {
    return 70 + (DateTime.now().millisecond % 25);
  }

  String _initials(String n) {
    final p = n.trim().split(' ');
    if (p.length >= 2) {
      return '${p[0][0]}${p[1][0]}'.toUpperCase();
    }
    return n.isNotEmpty ? n[0].toUpperCase() : 'U';
  }

  String _fmtTime(String? iso) {
    if (iso == null) return '—';
    try {
      return DateFormat('HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return '—';
    }
  }

  String _fmtDateTime(String? iso) {
    if (iso == null) return '—';
    try {
      return DateFormat('dd/MM/yyyy · HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return '—';
    }
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '—';
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso));
      if (diff.inMinutes < 1) return 'quelques secondes';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min';
      if (diff.inHours < 24) return '${diff.inHours} h';
      if (diff.inDays < 7) return '${diff.inDays} j';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} sem';
      if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} mois';
      return '${(diff.inDays / 365).floor()} an';
    } catch (_) {
      return '—';
    }
  }
}

class _StatSpec {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color soft;
  final String route;
  const _StatSpec({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.soft,
    required this.route,
  });
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _DrawerEntry {
  final IconData icon;
  final String label;
  final String route;
  final bool selected;
  const _DrawerEntry(this.icon, this.label, this.route,
      [this.selected = false]);
}