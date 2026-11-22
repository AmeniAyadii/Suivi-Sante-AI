import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';
import '../login_screen.dart';
import '../register_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // ==================== ANIMATIONS ====================
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _particlesController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  // ==================== ÉTAT ====================
  bool _isLoading = false;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Animation principale
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuint),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );
    
    // Animation de pulsation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Animation de rotation pour les particules
    _particlesController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _particlesController,
        curve: Curves.linear,
      ),
    );
    
    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    return Scaffold(
      body: Stack(
        children: [
          // Fond avec dégradé premium
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF0F0F1A),
                        const Color(0xFF1A1A2E),
                        const Color(0xFF16213E),
                      ]
                    : [
                        const Color(0xFF0D47A1),
                        const Color(0xFF1565C0),
                        const Color(0xFF42A5F5),
                      ],
              ),
            ),
          ),
          
          // Particules animées en arrière-plan
          _buildParticles(isDark),
          
          // Cercles décoratifs
          ..._buildDecorations(isDark, isTablet),
          
          // Contenu principal
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 60 : 24,
                  vertical: isTablet ? 40 : 16,
                ),
                child: isLargeScreen
                    ? _buildLargeScreenLayout(isDark, isTablet)
                    : _buildMobileLayout(isDark, isTablet),
              ),
            ),
          ),
          
          // Badge de version
          Positioned(
            bottom: 16,
            right: 16,
            child: _buildVersionBadge(isDark),
          ),
        ],
      ),
    );
  }

  // ==================== PARTICULES ====================
  Widget _buildParticles(bool isDark) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ParticlesPainter(
            progress: _rotationAnimation.value,
            isDark: isDark,
          ),
        );
      },
    );
  }

  // ==================== DÉCORATIONS ====================
  List<Widget> _buildDecorations(bool isDark, bool isTablet) {
    final size = isTablet ? 500.0 : 350.0;
    final smallSize = isTablet ? 100.0 : 60.0;
    
    return [
      // Grand cercle en haut à droite
      Positioned(
        top: -size * 0.3,
        right: -size * 0.3,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: isDark
                        ? [
                            Colors.white.withOpacity(0.03),
                            Colors.transparent,
                          ]
                        : [
                            Colors.white.withOpacity(0.08),
                            Colors.transparent,
                          ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      ),
      
      // Grand cercle en bas à gauche
      Positioned(
        bottom: -size * 0.25,
        left: -size * 0.25,
        child: Container(
          width: size * 1.2,
          height: size * 1.2,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.02),
                      Colors.transparent,
                    ]
                  : [
                      Colors.white.withOpacity(0.05),
                      Colors.transparent,
                    ],
            ),
            shape: BoxShape.circle,
          ),
        ),
      ),
      
      // Petit cercle décoratif
      Positioned(
        top: isTablet ? 200 : 100,
        right: isTablet ? 80 : 20,
        child: Container(
          width: smallSize,
          height: smallSize,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.03),
                      Colors.transparent,
                    ]
                  : [
                      Colors.white.withOpacity(0.06),
                      Colors.transparent,
                    ],
            ),
            shape: BoxShape.circle,
          ),
        ),
      ),
      
      // Un autre cercle
      Positioned(
        bottom: isTablet ? 300 : 150,
        right: isTablet ? 100 : 30,
        child: Container(
          width: smallSize * 0.7,
          height: smallSize * 0.7,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: isDark
                  ? [
                      Colors.white.withOpacity(0.02),
                      Colors.transparent,
                    ]
                  : [
                      Colors.white.withOpacity(0.04),
                      Colors.transparent,
                    ],
            ),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ];
  }

  // ==================== LAYOUT POUR GRANDS ÉCRANS ====================
  Widget _buildLargeScreenLayout(bool isDark, bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Partie gauche - Contenu
        Expanded(
          flex: 5,
          child: _buildContent(isDark, isTablet),
        ),
        // Partie droite - Illustration/Image
        Expanded(
          flex: 4,
          child: _buildIllustration(isDark),
        ),
      ],
    );
  }

  // ==================== LAYOUT POUR MOBILE ====================
  Widget _buildMobileLayout(bool isDark, bool isTablet) {
    return _buildContent(isDark, isTablet);
  }

  // ==================== CONTENU PRINCIPAL ====================
  Widget _buildContent(bool isDark, bool isTablet) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo avec animation
        _buildLogo(),
        SizedBox(height: isTablet ? 30 : 20),
        
        // Titre
        _buildTitle(),
        SizedBox(height: isTablet ? 8 : 4),
        
        // Sous-titre
        _buildSubtitle(),
        SizedBox(height: isTablet ? 30 : 24),
        
        // Features
        _buildFeatures(),
        SizedBox(height: isTablet ? 32 : 24),
        
        // Boutons
        _buildButtons(),
      ],
    );
  }

  // ==================== ILLUSTRATION ====================
  Widget _buildIllustration(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Carte d'illustration animée
              AnimatedContainer(
                duration: const Duration(seconds: 4),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Statistiques
                    _buildStatCard('92%', 'Analyse santé', Iconsax.chart, Colors.green),
                    const SizedBox(height: 12),
                    _buildStatCard('24/7', 'Assistance IA', Iconsax.messages, Colors.blue),
                    const SizedBox(height: 12),
                    _buildStatCard('100+', 'Médicaments', Iconsax.health, Colors.purple),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Iconsax.arrow_right_3,
            color: Colors.white,
            size: 16,
          ),
        ],
      ),
    );
  }

  // ==================== LOGO ====================
  Widget _buildLogo() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.15),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Iconsax.health,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== TITRE ====================
  Widget _buildTitle() {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth > 600 ? 42.0 : 32.0;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Colors.white,
            Colors.white70,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Text(
          'Suivi Santé AI',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
            height: 1.2,
            shadows: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SOUS-TITRE ====================
  Widget _buildSubtitle() {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth > 600 ? 18.0 : 15.0;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        'Votre santé, simplifiée et intelligente',
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.white.withOpacity(0.85),
          letterSpacing: 0.5,
          fontWeight: FontWeight.w300,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ==================== FEATURES ====================
  Widget _buildFeatures() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isTablet ? 4 : 2;
    final childAspectRatio = isTablet ? 2.4 : 1.9;
    
    final features = [
      {
        'icon': Iconsax.chart,
        'title': 'Suivi intelligent',
        'description': 'Analyse en temps réel',
        'color': const Color(0xFF4CAF50),
      },
      {
        'icon': Iconsax.health,
        'title': 'Traitements',
        'description': 'Rappels personnalisés',
        'color': const Color(0xFF9C27B0),
      },
      {
        'icon': Iconsax.calendar,
        'title': 'Rendez-vous',
        'description': 'Gestion simplifiée',
        'color': const Color(0xFFFF9800),
      },
      {
        'icon': Iconsax.messages,
        'title': 'Assistant IA',
        'description': 'Réponses instantanées',
        'color': const Color(0xFF00BCD4),
      },
    ];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
        )),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 20 : 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: isTablet ? 12 : 8,
              mainAxisSpacing: isTablet ? 12 : 8,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return _buildFeatureItem(
                icon: feature['icon'] as IconData,
                title: feature['title'] as String,
                description: feature['description'] as String,
                color: feature['color'] as Color,
                index: index,
              );
            },
          ),
        ),
      ),
    );
  }

  // ==================== FEATURE ITEM CORRIGÉ ====================
  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required int index,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          // Textes
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BOUTONS ====================
  Widget _buildButtons() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final buttonHeight = isTablet ? 56.0 : 48.0;
    final buttonFontSize = isTablet ? 16.0 : 15.0;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
        )),
        child: Column(
          children: [
            // Bouton Connexion
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: Material(
                elevation: 8,
                shadowColor: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _navigateToLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0D47A1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.login_rounded, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Se connecter',
                        style: TextStyle(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0D47A1),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Bouton Inscription
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _navigateToRegister,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Créer un compte',
                      style: TextStyle(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Lien "Déjà un compte ?"
            TextButton(
              onPressed: _navigateToLogin,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withOpacity(0.5),
              ),
              child: const Text(
                'Déjà un compte ? Se connecter',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== BADGE VERSION ====================
  Widget _buildVersionBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.verify,
            size: 12,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(width: 4),
          Text(
            'v3.0.0',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== NAVIGATION ====================
  void _navigateToLogin() {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  void _navigateToRegister() {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const RegisterScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }
}

// ==================== PARTICLES PAINTER ====================
class _ParticlesPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _ParticlesPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.02 : 0.04)
      ..style = PaintingStyle.fill;

    // Créer des particules animées
    const int count = 20;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * 3.14159 + progress * 2 * 3.14159;
      final radius = size.width * 0.35 + (i % 5) * 20;
      final x = size.width / 2 + radius * 0.6 * (i % 3 + 1) * 0.5 * (i % 2 == 0 ? 1 : -1);
      final y = size.height / 2 + radius * 0.4 * (i % 4 + 1) * 0.5 * (i % 3 == 0 ? 1 : -1);
      
      final particleSize = (i % 5 + 2).toDouble();
      final opacity = 0.02 + (i % 3) * 0.015;
      
      paint.color = Colors.white.withOpacity(opacity);
      
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}