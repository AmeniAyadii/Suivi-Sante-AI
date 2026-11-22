import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';
import '../../models/onboarding_item.dart';
import '../../screens/login_screen.dart';
import '../../screens/register_screen.dart';
import 'welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  double _pageOffset = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<OnboardingItem> _onboardingData = [
    OnboardingItem(
      title: 'Bienvenue sur Suivi Santé AI',
      description: 'Votre assistant santé intelligent pour un suivi médical personnalisé et efficace.',
      image: 'assets/images/onboarding/health_1.json',
      color: const Color(0xFF2563EB),
      icon: Iconsax.health,
    ),
    OnboardingItem(
      title: 'Suivez vos symptômes',
      description: 'Enregistrez et analysez vos symptômes en temps réel avec notre IA avancée.',
      image: 'assets/images/onboarding/health_2.json',
      color: const Color(0xFF059669),
      icon: Iconsax.chart,
    ),
    OnboardingItem(
      title: 'Gérez vos traitements',
      description: 'Ne manquez plus jamais une prise de médicament avec nos rappels intelligents.',
      image: 'assets/images/onboarding/health_3.json',
      color: const Color(0xFF7C3AED),
      icon: Iconsax.health,
    ),
    OnboardingItem(
      title: 'Consultations à portée de main',
      description: 'Prenez rendez-vous et consultez vos médecins en toute simplicité.',
      image: 'assets/images/onboarding/health_4.json',
      color: const Color(0xFFEA580C),
      icon: Iconsax.calendar,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    _animationController.forward();

    _pageController.addListener(() {
      setState(() {
        _pageOffset = _pageController.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Colors.grey[900]!,
                        Colors.grey[850]!,
                      ]
                    : [
                        Colors.blue.shade50,
                        Colors.white,
                      ],
              ),
            ),
          ),
          ..._buildDecorations(isDark),
          SafeArea(
            child: Column(
              children: [
                _buildSkipButton(),
                Flexible(
                  flex: 7,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemCount: _onboardingData.length,
                    itemBuilder: (context, index) {
                      final data = _onboardingData[index];
                      final isActive = index == _currentPage;
                      return _buildOnboardingPage(data, index, isActive);
                    },
                  ),
                ),
                _buildFooter(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDecorations(bool isDark) {
    return [
      Positioned(
        top: -50,
        right: -50,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.blue.shade100.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        bottom: -80,
        left: -80,
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            color: Colors.purple.shade100.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ];
  }

  Widget _buildSkipButton() {
    if (_currentPage == _onboardingData.length - 1) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: TextButton(
          onPressed: _navigateToWelcome,
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue.shade700,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Passer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.blue.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingItem data, int index, bool isActive) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = data.color;

    return AnimatedOpacity(
      opacity: isActive ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  data.icon,
                  size: 120,
                  color: color,
                )
                    .animate()
                    // ✅ CORRECTION : Utiliser Offset
                    .scale(
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                    )
                    .fade(
                      duration: 400.ms,
                    ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              data.title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[800],
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fade(duration: 300.ms, delay: 200.ms)
                .slideY(
                  begin: 0.2,
                  end: 0,
                  duration: 300.ms,
                  delay: 200.ms,
                ),
            const SizedBox(height: 16),
            Text(
              data.description,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fade(duration: 300.ms, delay: 400.ms)
                .slideY(
                  begin: 0.2,
                  end: 0,
                  duration: 300.ms,
                  delay: 400.ms,
                ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withOpacity(0.2),
                ),
              ),
              child: Text(
                '${index + 1} / ${_onboardingData.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
                .animate()
                .fade(duration: 300.ms, delay: 600.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(
                  _onboardingData.length,
                  (index) => _buildDotIndicator(index),
                ),
              ),
              _buildNextButton(),
            ],
          ),
          const SizedBox(height: 16),
          if (_currentPage == _onboardingData.length - 1)
            Column(
              children: [
                Row(
                  children: [
                    Flexible(
                      child: OutlinedButton(
                        onPressed: _navigateToLogin,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                          side: BorderSide(color: Colors.blue.shade200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Se connecter',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: ElevatedButton(
                        onPressed: _navigateToRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'S\'inscrire',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
                .animate()
                .fade(duration: 300.ms)
                .slideY(
                  begin: 0.2,
                  end: 0,
                  duration: 300.ms,
                ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = _currentPage == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 6),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: isActive
            ? Colors.blue.shade700
            : isDark
                ? Colors.grey[600]
                : Colors.grey[300],
      ),
    );
  }

  Widget _buildNextButton() {
    final isLast = _currentPage == _onboardingData.length - 1;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLast
              ? [Colors.green.shade600, Colors.green.shade400]
              : [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isLast ? Colors.green : Colors.blue).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _nextPage,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLast ? 'Commencer' : 'Suivant',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isLast ? Icons.check_circle : Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToWelcome();
    }
  }

  void _navigateToWelcome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const WelcomeScreen(),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }
}
