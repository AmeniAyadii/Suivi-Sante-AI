// lib/screens/auth/register_screen.dart
// Version 2.0.0 — Support multi-rôles (patient / doctor / admin)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:suivi_sante_pro/screens/login_screen.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  // ==================== CONTROLEURS & CLÉS ====================
  final _formKey = GlobalKey<FormState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // Contrôleurs communs
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

  // Contrôleurs patient
  final _dateNaissanceController = TextEditingController();
  final _tailleController = TextEditingController();
  final _poidsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicamentsController = TextEditingController();

  // Contrôleurs médecin
  final _specialiteController = TextEditingController();
  final _numeroOrdreController = TextEditingController();
  final _cabinetPhoneController = TextEditingController();
  final _cabinetAddressController = TextEditingController();

  // Contrôleur admin
  final _adminCodeController = TextEditingController();

  // ==================== ÉTATS ====================
  String _selectedRole = 'patient'; // 'patient' | 'doctor' | 'admin'
  String _selectedSexe = 'M';
  String _selectedGroupeSanguin = 'A+';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  int _currentStep = 0;
  DateTime? _selectedDate;

  // ==================== FOCUS ====================
  final List<FocusNode> _focusNodes = [];

  // ==================== ANIMATIONS ====================
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeFocusNodes();
    _initAnimations();
  }

  void _initializeFocusNodes() {
    for (int i = 0; i < 15; i++) {
      _focusNodes.add(FocusNode());
    }
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _dateNaissanceController.dispose();
    _tailleController.dispose();
    _poidsController.dispose();
    _allergiesController.dispose();
    _medicamentsController.dispose();
    _specialiteController.dispose();
    _numeroOrdreController.dispose();
    _cabinetPhoneController.dispose();
    _cabinetAddressController.dispose();
    _adminCodeController.dispose();
    for (var node in _focusNodes) {
      node.dispose();
    }
    _fadeController.dispose();
    super.dispose();
  }

  // ==================== HELPERS RÔLE ====================
  int get _totalSteps {
    switch (_selectedRole) {
      case 'doctor':
        return 2;
      case 'admin':
        return 1;
      default:
        return 3;
    }
  }

  List<String> get _stepLabels {
    switch (_selectedRole) {
      case 'doctor':
        return ['Profil', 'Sécurité'];
      case 'admin':
        return ['Admin'];
      default:
        return ['Personnel', 'Médical', 'Sécurité'];
    }
  }

  List<IconData> get _stepIcons {
    switch (_selectedRole) {
      case 'doctor':
        return [Iconsax.health, Iconsax.shield_security];
      case 'admin':
        return [Iconsax.shield_security];
      default:
        return [Iconsax.user, Iconsax.health, Iconsax.shield_security];
    }
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldMessengerKey,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.grey[900]!, Colors.grey[850]!, Colors.grey[800]!]
                : [
                    const Color(0xFFE3F2FD),
                    const Color(0xFFBBDEFB),
                    const Color(0xFF90CAF9),
                  ],
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (MediaQuery.of(context).size.width > 900) ...[
                Flexible(flex: 1, child: _buildSidePanel(isDark)),
                Flexible(flex: 2, child: _buildMainContent(isDark)),
              ] else ...[
                Flexible(flex: 1, child: _buildMainContent(isDark)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==================== PANEL LATÉRAL ====================
  Widget _buildSidePanel(bool isDark) {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.blue[900]!, Colors.blue[800]!, Colors.blue[700]!]
              : [Colors.blue[700]!, Colors.blue[600]!, Colors.blue[500]!],
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Iconsax.health, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 32),
            Text(
              'Créez votre compte',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Rejoignez notre communauté et profitez d\'un suivi santé intelligent et personnalisé.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.85),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            _buildFeatureItem('Suivi intelligent', 'Analyse en temps réel', Iconsax.chart),
            const SizedBox(height: 16),
            _buildFeatureItem('Rappels personnalisés', 'Médicaments et rendez-vous', Iconsax.notification),
            const SizedBox(height: 16),
            _buildFeatureItem('Assistant IA', 'Réponses instantanées', Iconsax.messages),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Progression',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${((_currentStep + 1) / _totalSteps * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / _totalSteps,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== CONTENU PRINCIPAL ====================
  Widget _buildMainContent(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(MediaQuery.of(context).size.width > 900 ? 40 : 20),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (MediaQuery.of(context).size.width <= 900) ...[
              _buildMobileHeader(isDark),
              const SizedBox(height: 24),
            ],
            _buildRoleSelector(isDark),
            const SizedBox(height: 20),
            _buildModernStepper(),
            const SizedBox(height: 32),
            Card(
              elevation: isDark ? 0 : 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: isDark ? Colors.grey[850]?.withOpacity(0.9) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildStepContent(),
                      const SizedBox(height: 24),
                      _buildTermsAndConditions(isDark),
                      const SizedBox(height: 16),
                      _buildSubmitButton(isDark),
                      const SizedBox(height: 12),
                      _buildLoginLink(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HEADER MOBILE ====================
  Widget _buildMobileHeader(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Iconsax.health, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inscription',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.blue[800],
              ),
            ),
            Text(
              'Créez votre compte en quelques étapes',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== SÉLECTEUR DE RÔLE ====================
  Widget _buildRoleSelector(bool isDark) {
    final roles = [
      {'value': 'patient', 'label': 'Patient', 'icon': Iconsax.user},
      {'value': 'doctor', 'label': 'Médecin', 'icon': Iconsax.health},
      {'value': 'admin', 'label': 'Admin', 'icon': Iconsax.shield_security},
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: roles.map((role) {
          final isSelected = _selectedRole == role['value'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedRole = role['value'] as String;
                _currentStep = 0;
                _formKey.currentState?.reset();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[600] : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      role['icon'] as IconData,
                      size: 20,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.grey[400] : Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==================== STEPPER ====================
  Widget _buildModernStepper() {
    final steps = _stepLabels;
    final icons = _stepIcons;

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= _currentStep;
        final isLast = index == steps.length - 1;

        return Flexible(
          flex: 1,
          child: Row(
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isActive
                          ? LinearGradient(
                              colors: [Colors.blue[600]!, Colors.blue[400]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isActive ? null : Colors.grey[300],
                      border: isActive
                          ? null
                          : Border.all(color: Colors.grey[400]!, width: 2),
                    ),
                    child: Center(
                      child: isActive
                          ? Icon(icons[index], color: Colors.white, size: 20)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? Colors.blue[700] : Colors.grey[500],
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Flexible(
                  child: Container(
                    height: 2,
                    color:
                        index < _currentStep ? Colors.blue[400] : Colors.grey[300],
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  // ==================== CONTENU DES ÉTAPES ====================
  Widget _buildStepContent() {
    if (_selectedRole == 'doctor') {
      return _currentStep == 0 ? _buildDoctorProfileStep() : _buildSecurityStep();
    }
    if (_selectedRole == 'admin') {
      return _buildAdminStep();
    }
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildMedicalInfoStep();
      case 2:
        return _buildSecurityStep();
      default:
        return const SizedBox();
    }
  }

  // ==================== ÉTAPE PATIENT 1 : INFOS PERSONNELLES ====================
  Widget _buildPersonalInfoStep() {
    return Column(
      children: [
        _buildSectionHeader('Informations personnelles', Iconsax.user),
        const SizedBox(height: 16),
        Row(
          children: [
            Flexible(
              child: _buildModernTextField(
                controller: _nomController,
                label: 'Nom',
                icon: Iconsax.user,
                validator: (value) => _validateRequired(value, 'Nom'),
                focusNode: _focusNodes[0],
                onSubmitted: (_) => _focusNext(0),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: _buildModernTextField(
                controller: _prenomController,
                label: 'Prénom',
                icon: Iconsax.user,
                validator: (value) => _validateRequired(value, 'Prénom'),
                focusNode: _focusNodes[1],
                onSubmitted: (_) => _focusNext(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Flexible(
              flex: 2,
              child: _buildModernTextField(
                controller: _emailController,
                label: 'Email',
                icon: Iconsax.sms,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                focusNode: _focusNodes[2],
                onSubmitted: (_) => _focusNext(2),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              flex: 1,
              child: _buildModernTextField(
                controller: _phoneController,
                label: 'Téléphone',
                icon: Iconsax.call,
                keyboardType: TextInputType.phone,
                validator: (value) => _validatePhone(value),
                focusNode: _focusNodes[3],
                onSubmitted: (_) => _focusNext(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Flexible(flex: 1, child: _buildModernDatePicker()),
            const SizedBox(width: 12),
            Flexible(
              child: _buildModernDropdown(
                value: _selectedSexe,
                items: const ['M', 'F', 'A'],
                label: 'Sexe',
                icon: Iconsax.user_tag,
                onChanged: (value) => setState(() => _selectedSexe = value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Flexible(
              child: _buildModernTextField(
                controller: _tailleController,
                label: 'Taille (cm)',
                icon: Iconsax.ruler,
                keyboardType: TextInputType.number,
                validator: (value) => _validateRequired(value, 'Taille'),
                focusNode: _focusNodes[4],
                onSubmitted: (_) => _focusNext(4),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: _buildModernTextField(
                controller: _poidsController,
                label: 'Poids (kg)',
                icon: Iconsax.weight,
                keyboardType: TextInputType.number,
                validator: (value) => _validateRequired(value, 'Poids'),
                focusNode: _focusNodes[5],
                onSubmitted: (_) => _focusNext(5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: _validatePersonalInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                children: [
                  Text('Suivant'),
                  SizedBox(width: 8),
                  Icon(Iconsax.arrow_right, size: 18),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== ÉTAPE PATIENT 2 : INFOS MÉDICALES ====================
  Widget _buildMedicalInfoStep() {
    return Column(
      children: [
        _buildSectionHeader('Informations médicales', Iconsax.health),
        const SizedBox(height: 16),
        _buildModernDropdown(
          value: _selectedGroupeSanguin,
          items: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
          label: 'Groupe sanguin',
          icon: Iconsax.blend,
          onChanged: (value) => setState(() => _selectedGroupeSanguin = value!),
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _allergiesController,
          label: 'Allergies',
          icon: Iconsax.danger,
          hintText: 'Ex: Arachides, Pollen, Pénicilline',
          focusNode: _focusNodes[6],
          onSubmitted: (_) => _focusNext(6),
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _medicamentsController,
          label: 'Médicaments actuels',
          icon: Iconsax.hospital,
          hintText: 'Ex: Paracétamol, Insuline',
          focusNode: _focusNodes[7],
          onSubmitted: (_) => _focusNext(7),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _goToPreviousStep,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text('Précédent', style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              onPressed: _validateMedicalInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                children: [
                  Text('Suivant'),
                  SizedBox(width: 8),
                  Icon(Iconsax.arrow_right, size: 18),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== ÉTAPE MÉDECIN : PROFIL ====================
  Widget _buildDoctorProfileStep() {
    return Column(
      children: [
        _buildSectionHeader('Profil médical', Iconsax.health),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _nomController,
          label: 'Nom complet',
          icon: Iconsax.user,
          validator: (v) => _validateRequired(v, 'Nom'),
          focusNode: _focusNodes[0],
          onSubmitted: (_) => _focusNext(0),
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _emailController,
          label: 'Email professionnel',
          icon: Iconsax.sms,
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
          focusNode: _focusNodes[1],
          onSubmitted: (_) => _focusNext(1),
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _phoneController,
          label: 'Téléphone',
          icon: Iconsax.call,
          keyboardType: TextInputType.phone,
          validator: (v) => _validatePhone(v),
          focusNode: _focusNodes[2],
          onSubmitted: (_) => _focusNext(2),
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _specialiteController,
          label: 'Spécialité',
          icon: Iconsax.health,
          hintText: 'Ex: Cardiologue, Dermatologue',
          validator: (v) => _validateRequired(v, 'Spécialité'),
          focusNode: _focusNodes[3],
          onSubmitted: (_) => _focusNext(3),
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _numeroOrdreController,
          label: 'Numéro d\'ordre',
          icon: Iconsax.document,
          hintText: 'Ex: MED-2026-042',
          validator: (v) => _validateRequired(v, 'Numéro d\'ordre'),
          focusNode: _focusNodes[4],
          onSubmitted: (_) => _focusNext(4),
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _cabinetPhoneController,
          label: 'Téléphone du cabinet',
          icon: Iconsax.call,
          keyboardType: TextInputType.phone,
          focusNode: _focusNodes[5],
          onSubmitted: (_) => _focusNext(5),
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _cabinetAddressController,
          label: 'Adresse du cabinet',
          icon: Iconsax.location,
          focusNode: _focusNodes[6],
          onSubmitted: (_) => _focusNext(6),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: _validateDoctorProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                children: [
                  Text('Suivant'),
                  SizedBox(width: 8),
                  Icon(Iconsax.arrow_right, size: 18),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== ÉTAPE ADMIN ====================
  Widget _buildAdminStep() {
    return Column(
      children: [
        _buildSectionHeader('Accès administrateur', Iconsax.shield_security),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Iconsax.warning_2, color: Colors.orange[800], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Un code d\'invitation est requis. Contactez le super-administrateur pour l\'obtenir.',
                  style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _nomController,
          label: 'Nom complet',
          icon: Iconsax.user,
          validator: (v) => _validateRequired(v, 'Nom'),
          focusNode: _focusNodes[0],
          onSubmitted: (_) => _focusNext(0),
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _emailController,
          label: 'Email',
          icon: Iconsax.sms,
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
          focusNode: _focusNodes[1],
          onSubmitted: (_) => _focusNext(1),
        ),
        const SizedBox(height: 16),
        _buildModernTextField(
          controller: _adminCodeController,
          label: 'Code d\'invitation admin',
          icon: Iconsax.key,
          hintText: 'Fourni par le super-admin',
          validator: (v) => _validateRequired(v, 'Code'),
          focusNode: _focusNodes[2],
          onSubmitted: (_) => _focusNext(2),
        ),
        const SizedBox(height: 16),
        _buildModernPasswordField(
          controller: _passwordController,
          label: 'Mot de passe',
          obscureText: _obscurePassword,
          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
          validator: _validatePassword,
          focusNode: _focusNodes[3],
          onSubmitted: (_) => _focusNext(3),
        ),
        const SizedBox(height: 16),
        _buildModernPasswordField(
          controller: _passwordConfirmationController,
          label: 'Confirmer le mot de passe',
          obscureText: _obscureConfirmPassword,
          onToggle: () =>
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Confirmation requise';
            }
            if (value != _passwordController.text) {
              return 'Les mots de passe ne correspondent pas';
            }
            return null;
          },
          focusNode: _focusNodes[4],
          onSubmitted: (_) => _focusNext(4),
        ),
        const SizedBox(height: 8),
        _buildPasswordStrengthIndicator(),
      ],
    );
  }

  // ==================== ÉTAPE SÉCURITÉ (patient + médecin) ====================
  Widget _buildSecurityStep() {
    return Column(
      children: [
        _buildSectionHeader('Sécurité du compte', Iconsax.shield_security),
        const SizedBox(height: 8),
        Text(
          'Créez un mot de passe sécurisé pour protéger votre compte',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        _buildModernPasswordField(
          controller: _passwordController,
          label: 'Mot de passe',
          obscureText: _obscurePassword,
          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
          validator: _validatePassword,
          focusNode: _focusNodes[8],
          onSubmitted: (_) => _focusNext(8),
        ),
        const SizedBox(height: 16),
        _buildModernPasswordField(
          controller: _passwordConfirmationController,
          label: 'Confirmer le mot de passe',
          obscureText: _obscureConfirmPassword,
          onToggle: () =>
              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Confirmation requise';
            }
            if (value != _passwordController.text) {
              return 'Les mots de passe ne correspondent pas';
            }
            return null;
          },
          focusNode: _focusNodes[9],
          onSubmitted: (_) => _focusNext(9),
        ),
        const SizedBox(height: 8),
        _buildPasswordStrengthIndicator(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _goToPreviousStep,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text('Précédent', style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      children: [
                        Text('S\'inscrire'),
                        SizedBox(width: 8),
                        Icon(Iconsax.tick_circle, size: 18),
                      ],
                    ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== INDICATEUR MOT DE PASSE ====================
  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    final strengthText = ['Très faible', 'Faible', 'Moyen', 'Fort', 'Très fort'];
    final strengthColor = [
      Colors.red,
      Colors.orange,
      Colors.orange,
      Colors.blue,
      Colors.green
    ];

    if (password.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Force du mot de passe : ',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text(
              strengthText[strength],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: strengthColor[strength],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) {
            return Flexible(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: index < strength
                      ? strengthColor[strength]
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ==================== TERMES ET CONDITIONS ====================
  Widget _buildTermsAndConditions(bool isDark) {
    return Row(
      children: [
        Transform.scale(
          scale: 0.9,
          child: Checkbox(
            value: _acceptTerms,
            onChanged: (value) => setState(() => _acceptTerms = value ?? false),
            activeColor: Colors.blue[600],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        Flexible(
          flex: 1,
          child: GestureDetector(
            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
            child: Text.rich(
              TextSpan(
                text: 'J\'accepte les ',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                  fontSize: 13,
                ),
                children: [
                  TextSpan(
                    text: 'conditions générales',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' et la ',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                  TextSpan(
                    text: 'politique de confidentialité',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontWeight: FontWeight.bold,
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

  // ==================== BOUTON DE SOUMISSION ====================
  Widget _buildSubmitButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _acceptTerms ? _submitForm : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _acceptTerms ? Colors.blue[600] : Colors.grey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: _acceptTerms ? 4 : 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Créer mon compte',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  // ==================== LIEN DE CONNEXION ====================
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Déjà un compte ?',
            style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        TextButton(
          onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        },
          child: Text(
            'Se connecter',
            style: TextStyle(
              color: Colors.blue[600],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== COMPOSANTS ====================
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: textInputAction ?? TextInputAction.next,
      keyboardType: keyboardType,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, size: 20, color: Colors.blue[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
    );
  }

  Widget _buildModernPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?)? validator,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Iconsax.lock, size: 20, color: Colors.blue[400]),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Iconsax.eye_slash : Iconsax.eye,
            size: 20,
            color: Colors.grey[500],
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildModernDropdown({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.blue[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildModernDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: Colors.blue[600]!),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
            _dateNaissanceController.text =
                '${date.day}/${date.month}/${date.year}';
          });
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: _dateNaissanceController,
          decoration: InputDecoration(
            labelText: 'Date de naissance',
            prefixIcon: Icon(Iconsax.calendar, size: 20, color: Colors.blue[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintText: 'JJ/MM/AAAA',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Date requise';
            }
            return null;
          },
        ),
      ),
    );
  }

  // ==================== VALIDATEURS ====================
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName requis';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email requis';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email invalide';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Téléphone requis';
    }
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value.trim().replaceAll(' ', ''))) {
      return 'Numéro invalide';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mot de passe requis';
    }
    if (value.length < 8) {
      return 'Minimum 8 caractères';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Doit contenir une majuscule';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Doit contenir une minuscule';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Doit contenir un chiffre';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Doit contenir un caractère spécial';
    }
    return null;
  }

  // ==================== NAVIGATION ====================
  void _focusNext(int index) {
    if (index < _focusNodes.length - 1 && _focusNodes[index + 1] != null) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _validatePersonalInfo() {
    if (_formKey.currentState!.validate()) {
      setState(() => _currentStep = 1);
    }
  }

  void _validateMedicalInfo() {
    if (_formKey.currentState!.validate()) {
      setState(() => _currentStep = 2);
    }
  }

  void _validateDoctorProfile() {
    if (_formKey.currentState!.validate()) {
      setState(() => _currentStep = 1);
    }
  }

  // ==================== SOUMISSION ====================
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> userData = {
        'role': _selectedRole,
        'nom': _nomController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'password_confirmation': _passwordConfirmationController.text,
      };

      if (_phoneController.text.trim().isNotEmpty) {
        userData['telephone'] = _phoneController.text.trim();
      }

      if (_selectedRole == 'patient') {
        final age = _selectedDate != null
            ? DateTime.now().year - _selectedDate!.year
            : 0;
        userData['age'] = age;
        userData['sexe'] = _selectedSexe;
        userData['taille'] = double.tryParse(_tailleController.text.trim()) ?? 0;
        userData['poids'] = double.tryParse(_poidsController.text.trim()) ?? 0;
        userData['groupe_sanguin'] = _selectedGroupeSanguin;

        if (_allergiesController.text.trim().isNotEmpty) {
          userData['allergies'] = _allergiesController.text.trim();
        }
        if (_medicamentsController.text.trim().isNotEmpty) {
          userData['maladies_chroniques'] = _medicamentsController.text.trim();
        }
      }

      if (_selectedRole == 'doctor') {
        userData['specialite'] = _specialiteController.text.trim();
        userData['numero_ordre'] = _numeroOrdreController.text.trim();
        if (_cabinetPhoneController.text.trim().isNotEmpty) {
          userData['cabinet_phone'] = _cabinetPhoneController.text.trim();
        }
        if (_cabinetAddressController.text.trim().isNotEmpty) {
          userData['cabinet_address'] = _cabinetAddressController.text.trim();
        }
      }

      if (_selectedRole == 'admin') {
        userData['admin_code'] = _adminCodeController.text.trim();
      }

      userData.removeWhere((key, value) => value == null || value.toString().isEmpty);

      debugPrint('📤 Envoi inscription ($_selectedRole): $userData');

      final authService = context.read<AuthService>();
      final result = await authService.register(userData);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        _showSuccessDialog();
      } else {
        String errorMessage = 'Erreur d\'inscription';
        if (result['errors'] != null) {
          final errors = result['errors'] as Map<String, dynamic>;
          errorMessage = errors.values.first.first.toString();
        } else if (result['error'] != null) {
          errorMessage = result['error'].toString();
        }
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur: $e');
    }
  }

  // ==================== DIALOGUES ====================
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.tick_circle, color: Colors.green[600], size: 64),
              ),
              const SizedBox(height: 16),
              Text(
                'Inscription réussie !',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre compte $_selectedRole a été créé avec succès.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                'Vous pouvez maintenant vous connecter.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.warning_2, color: Colors.white),
            const SizedBox(width: 12),
            Flexible(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 6,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}