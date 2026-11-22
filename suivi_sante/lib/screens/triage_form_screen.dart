// lib/screens/triage_form_screen.dart
// Écran de saisie des données du patient pour la prédiction du triage

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../models/patient.dart';
import '../services/triage_api_service.dart';
import 'triage_result_screen.dart';

class TriageFormScreen extends StatefulWidget {
  const TriageFormScreen({super.key});

  @override
  State<TriageFormScreen> createState() => _TriageFormScreenState();
}

class _TriageFormScreenState extends State<TriageFormScreen> {
  // ==================== CLÉS ET SERVICES ====================
  final _formKey = GlobalKey<FormState>();
  final _apiService = TriageApiService();

  // ==================== CONTRÔLEURS ====================
  // Données démographiques
  final _ageController = TextEditingController(text: '45');

  // Signes vitaux
  final _systolicBpController = TextEditingController(text: '120');
  final _diastolicBpController = TextEditingController(text: '80');
  final _heartRateController = TextEditingController(text: '80');
  final _respiratoryRateController = TextEditingController(text: '16');
  final _temperatureController = TextEditingController(text: '37.0');
  final _spo2Controller = TextEditingController(text: '98');

  // Évaluation clinique
  final _painScoreController = TextEditingController(text: '3');
  final _news2Controller = TextEditingController(text: '2');
  final _gcsController = TextEditingController(text: '15');
  final _weightController = TextEditingController(text: '75');
  final _heightController = TextEditingController(text: '175');

  // ==================== ANTÉCÉDENTS (CHECKBOXES) ====================
  bool _hasHypertension = false;
  bool _hasDiabetes2 = false;
  bool _hasDiabetes1 = false;
  bool _hasAsthma = false;
  bool _hasCopd = false;
  bool _hasHeartFailure = false;
  bool _hasAtrialFibrillation = false;
  bool _hasCkd = false;
  bool _hasLiverDisease = false;
  bool _hasMalignancy = false;
  bool _hasObesity = false;
  bool _hasDepression = false;
  bool _hasAnxiety = false;
  bool _hasDementia = false;
  bool _hasEpilepsy = false;
  bool _hasHypothyroidism = false;
  bool _hasHyperthyroidism = false;
  bool _hasHiv = false;
  bool _hasCoagulopathy = false;
  bool _hasImmunosuppressed = false;
  bool _hasPregnant = false;
  bool _hasSubstanceUseDisorder = false;
  bool _hasCoronaryArteryDisease = false;
  bool _hasStrokePrior = false;
  bool _hasPeripheralVascularDisease = false;

  // ==================== ÉTATS ====================
  bool _isLoading = false;
  bool _showAdvancedHx = false; // Pour afficher/masquer les antécédents avancés

  // ==================== COULEURS ====================
  static const Color primaryColor = Color(0xFF4A6CF7);
  static const Color secondaryColor = Color(0xFF6B4DE6);
  static const Color dangerColor = Color(0xFFE91E63);

  @override
  void dispose() {
    _ageController.dispose();
    _systolicBpController.dispose();
    _diastolicBpController.dispose();
    _heartRateController.dispose();
    _respiratoryRateController.dispose();
    _temperatureController.dispose();
    _spo2Controller.dispose();
    _painScoreController.dispose();
    _news2Controller.dispose();
    _gcsController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // ==================== PRÉDICTION ====================
  Future<void> _predict() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez corriger les erreurs dans le formulaire',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ----- Récupérer les valeurs saisies -----
      final systolicBp = double.parse(_systolicBpController.text);
      final diastolicBp = double.parse(_diastolicBpController.text);
      final heartRate = double.parse(_heartRateController.text);
      final weight = double.parse(_weightController.text);
      final height = double.parse(_heightController.text);

      // ----- Calculer les valeurs dérivées -----
      final map = (systolicBp + 2 * diastolicBp) / 3;
      final pulsePressure = systolicBp - diastolicBp;
      final bmi = weight / ((height / 100) * (height / 100));
      final shockIndex = heartRate / systolicBp;

      // ----- Créer l'objet Patient -----
      final patient = Patient(
        age: int.parse(_ageController.text),
        arrivalHour: DateTime.now().hour,
        arrivalMonth: DateTime.now().month,
        numPriorEdVisits12m: 0,
        numPriorAdmissions12m: 0,
        numActiveMedications: 0,
        numComorbidities: _countComorbidities(),
        systolicBp: systolicBp,
        diastolicBp: diastolicBp,
        meanArterialPressure: map,
        pulsePressure: pulsePressure,
        heartRate: heartRate,
        respiratoryRate: double.parse(_respiratoryRateController.text),
        temperatureC: double.parse(_temperatureController.text),
        spo2: double.parse(_spo2Controller.text),
        gcsTotal: int.parse(_gcsController.text),
        painScore: double.parse(_painScoreController.text),
        weightKg: weight,
        heightCm: height,
        bmi: bmi,
        shockIndex: shockIndex,
        news2Score: int.parse(_news2Controller.text),
        hxHypertension: _hasHypertension ? 1 : 0,
        hxDiabetesType2: _hasDiabetes2 ? 1 : 0,
        hxDiabetesType1: _hasDiabetes1 ? 1 : 0,
        hxAsthma: _hasAsthma ? 1 : 0,
        hxCopd: _hasCopd ? 1 : 0,
        hxHeartFailure: _hasHeartFailure ? 1 : 0,
        hxAtrialFibrillation: _hasAtrialFibrillation ? 1 : 0,
        hxCkd: _hasCkd ? 1 : 0,
        hxLiverDisease: _hasLiverDisease ? 1 : 0,
        hxMalignancy: _hasMalignancy ? 1 : 0,
        hxObesity: _hasObesity ? 1 : 0,
        hxDepression: _hasDepression ? 1 : 0,
        hxAnxiety: _hasAnxiety ? 1 : 0,
        hxDementia: _hasDementia ? 1 : 0,
        hxEpilepsy: _hasEpilepsy ? 1 : 0,
        hxHypothyroidism: _hasHypothyroidism ? 1 : 0,
        hxHyperthyroidism: _hasHyperthyroidism ? 1 : 0,
        hxHiv: _hasHiv ? 1 : 0,
        hxCoagulopathy: _hasCoagulopathy ? 1 : 0,
        hxImmunosuppressed: _hasImmunosuppressed ? 1 : 0,
        hxPregnant: _hasPregnant ? 1 : 0,
        hxSubstanceUseDisorder: _hasSubstanceUseDisorder ? 1 : 0,
        hxCoronaryArteryDisease: _hasCoronaryArteryDisease ? 1 : 0,
        hxStrokePrior: _hasStrokePrior ? 1 : 0,
        hxPeripheralVascularDisease: _hasPeripheralVascularDisease ? 1 : 0,
      );

      // ----- Appel API -----
      final result = await _apiService.predictTriage(patient);

      if (!mounted) return;

      // ----- Naviguer vers l'écran de résultat -----
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TriageResultScreen(result: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red.shade400),
              const SizedBox(width: 8),
              Text(
                'Erreur',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.inter(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'OK',
                style: GoogleFonts.inter(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _countComorbidities() {
    int count = 0;
    if (_hasHypertension) count++;
    if (_hasDiabetes2) count++;
    if (_hasDiabetes1) count++;
    if (_hasAsthma) count++;
    if (_hasCopd) count++;
    if (_hasHeartFailure) count++;
    if (_hasAtrialFibrillation) count++;
    if (_hasCkd) count++;
    if (_hasLiverDisease) count++;
    if (_hasMalignancy) count++;
    if (_hasObesity) count++;
    if (_hasDepression) count++;
    if (_hasAnxiety) count++;
    if (_hasDementia) count++;
    if (_hasEpilepsy) count++;
    if (_hasHypothyroidism) count++;
    if (_hasHyperthyroidism) count++;
    if (_hasHiv) count++;
    if (_hasCoagulopathy) count++;
    if (_hasImmunosuppressed) count++;
    if (_hasSubstanceUseDisorder) count++;
    if (_hasCoronaryArteryDisease) count++;
    if (_hasStrokePrior) count++;
    if (_hasPeripheralVascularDisease) count++;
    return count;
  }

  // ==================== RESET FORMULAIRE ====================
  void _resetForm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Réinitialiser',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Voulez-vous réinitialiser tous les champs ?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _ageController.text = '45';
                _systolicBpController.text = '120';
                _diastolicBpController.text = '80';
                _heartRateController.text = '80';
                _respiratoryRateController.text = '16';
                _temperatureController.text = '37.0';
                _spo2Controller.text = '98';
                _painScoreController.text = '3';
                _news2Controller.text = '2';
                _gcsController.text = '15';
                _weightController.text = '75';
                _heightController.text = '175';
                _hasHypertension = false;
                _hasDiabetes2 = false;
                _hasDiabetes1 = false;
                _hasAsthma = false;
                _hasCopd = false;
                _hasHeartFailure = false;
                _hasAtrialFibrillation = false;
                _hasCkd = false;
                _hasLiverDisease = false;
                _hasMalignancy = false;
                _hasObesity = false;
                _hasDepression = false;
                _hasAnxiety = false;
                _hasDementia = false;
                _hasEpilepsy = false;
                _hasHypothyroidism = false;
                _hasHyperthyroidism = false;
                _hasHiv = false;
                _hasCoagulopathy = false;
                _hasImmunosuppressed = false;
                _hasPregnant = false;
                _hasSubstanceUseDisorder = false;
                _hasCoronaryArteryDisease = false;
                _hasStrokePrior = false;
                _hasPeripheralVascularDisease = false;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: Text(
              'Réinitialiser',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: dangerColor,
        foregroundColor: Colors.white,
        title: Text(
          'Évaluation Triage IA',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _resetForm,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Réinitialiser',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== BANNIÈRE D'INFORMATION =====
              _buildInfoBanner(),
              const SizedBox(height: 20),

              // ===== SECTION 1 : DÉMOGRAPHIQUES =====
              _buildSection(
                title: 'Données démographiques',
                icon: Iconsax.user,
                color: primaryColor,
                children: [
                  _buildNumberField(
                    label: 'Âge',
                    controller: _ageController,
                    suffix: 'ans',
                    icon: Iconsax.cake,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== SECTION 2 : SIGNES VITAUX =====
              _buildSection(
                title: 'Signes vitaux',
                icon: Iconsax.heart,
                color: const Color(0xFFE74C3C),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: 'TA systolique',
                          controller: _systolicBpController,
                          suffix: 'mmHg',
                          icon: Iconsax.activity,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildNumberField(
                          label: 'TA diastolique',
                          controller: _diastolicBpController,
                          suffix: 'mmHg',
                          icon: Iconsax.activity,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: 'Fréquence cardiaque',
                          controller: _heartRateController,
                          suffix: 'bpm',
                          icon: Iconsax.heart,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildNumberField(
                          label: 'Fréquence resp.',
                          controller: _respiratoryRateController,
                          suffix: '/min',
                          icon: Iconsax.wind,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: 'Température',
                          controller: _temperatureController,
                          suffix: '°C',
                          icon: Iconsax.sun,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildNumberField(
                          label: 'SpO₂',
                          controller: _spo2Controller,
                          suffix: '%',
                          icon: Iconsax.drop,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== SECTION 3 : ÉVALUATION CLINIQUE =====
              _buildSection(
                title: 'Évaluation clinique',
                icon: Iconsax.health,
                color: const Color(0xFFF39C12),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: 'Score de Glasgow',
                          controller: _gcsController,
                          suffix: '/15',
                          icon: Iconsax.eye,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildNumberField(
                          label: 'Score douleur',
                          controller: _painScoreController,
                          suffix: '/10',
                          icon: Iconsax.emoji_sad,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          label: 'NEWS2',
                          controller: _news2Controller,
                          suffix: '/20',
                          icon: Iconsax.chart_2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildNumberField(
                          label: 'Poids',
                          controller: _weightController,
                          suffix: 'kg',
                          icon: Iconsax.weight,
                        ),
                      ),
                    ],
                  ),
                  _buildNumberField(
                    label: 'Taille',
                    controller: _heightController,
                    suffix: 'cm',
                    icon: Iconsax.ruler,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ===== SECTION 4 : ANTÉCÉDENTS =====
              _buildSection(
                title: 'Antécédents médicaux',
                icon: Iconsax.document_text,
                color: const Color(0xFF9B59B6),
                children: [
                  // Antécédents principaux
                  _buildCheckbox(
                    'Hypertension',
                    _hasHypertension,
                    (v) => setState(() => _hasHypertension = v!),
                  ),
                  _buildCheckbox(
                    'Diabète type 2',
                    _hasDiabetes2,
                    (v) => setState(() => _hasDiabetes2 = v!),
                  ),
                  _buildCheckbox(
                    'Diabète type 1',
                    _hasDiabetes1,
                    (v) => setState(() => _hasDiabetes1 = v!),
                  ),
                  _buildCheckbox(
                    'Asthme',
                    _hasAsthma,
                    (v) => setState(() => _hasAsthma = v!),
                  ),
                  _buildCheckbox(
                    'BPCO',
                    _hasCopd,
                    (v) => setState(() => _hasCopd = v!),
                  ),
                  _buildCheckbox(
                    'Insuffisance cardiaque',
                    _hasHeartFailure,
                    (v) => setState(() => _hasHeartFailure = v!),
                  ),
                  _buildCheckbox(
                    'Fibrillation auriculaire',
                    _hasAtrialFibrillation,
                    (v) => setState(() => _hasAtrialFibrillation = v!),
                  ),
                  _buildCheckbox(
                    'Maladie rénale chronique',
                    _hasCkd,
                    (v) => setState(() => _hasCkd = v!),
                  ),
                  _buildCheckbox(
                    'Maladie coronarienne',
                    _hasCoronaryArteryDisease,
                    (v) => setState(() => _hasCoronaryArteryDisease = v!),
                  ),
                  _buildCheckbox(
                    'AVC antérieur',
                    _hasStrokePrior,
                    (v) => setState(() => _hasStrokePrior = v!),
                  ),

                  // Bouton "Plus d'antécédents"
                  if (!_showAdvancedHx)
                    TextButton.icon(
                      onPressed: () => setState(() => _showAdvancedHx = true),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: Text(
                        'Plus d\'antécédents',
                        style: GoogleFonts.inter(
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  // Antécédents avancés
                  if (_showAdvancedHx) ...[
                    const Divider(height: 24),
                    _buildCheckbox(
                      'Maladie hépatique',
                      _hasLiverDisease,
                      (v) => setState(() => _hasLiverDisease = v!),
                    ),
                    _buildCheckbox(
                      'Cancer',
                      _hasMalignancy,
                      (v) => setState(() => _hasMalignancy = v!),
                    ),
                    _buildCheckbox(
                      'Obésité',
                      _hasObesity,
                      (v) => setState(() => _hasObesity = v!),
                    ),
                    _buildCheckbox(
                      'Dépression',
                      _hasDepression,
                      (v) => setState(() => _hasDepression = v!),
                    ),
                    _buildCheckbox(
                      'Anxiété',
                      _hasAnxiety,
                      (v) => setState(() => _hasAnxiety = v!),
                    ),
                    _buildCheckbox(
                      'Démence',
                      _hasDementia,
                      (v) => setState(() => _hasDementia = v!),
                    ),
                    _buildCheckbox(
                      'Épilepsie',
                      _hasEpilepsy,
                      (v) => setState(() => _hasEpilepsy = v!),
                    ),
                    _buildCheckbox(
                      'Hypothyroïdie',
                      _hasHypothyroidism,
                      (v) => setState(() => _hasHypothyroidism = v!),
                    ),
                    _buildCheckbox(
                      'Hyperthyroïdie',
                      _hasHyperthyroidism,
                      (v) => setState(() => _hasHyperthyroidism = v!),
                    ),
                    _buildCheckbox(
                      'VIH',
                      _hasHiv,
                      (v) => setState(() => _hasHiv = v!),
                    ),
                    _buildCheckbox(
                      'Coagulopathie',
                      _hasCoagulopathy,
                      (v) => setState(() => _hasCoagulopathy = v!),
                    ),
                    _buildCheckbox(
                      'Immunodéprimé',
                      _hasImmunosuppressed,
                      (v) => setState(() => _hasImmunosuppressed = v!),
                    ),
                    _buildCheckbox(
                      'Grossesse',
                      _hasPregnant,
                      (v) => setState(() => _hasPregnant = v!),
                    ),
                    _buildCheckbox(
                      'Trouble lié aux substances',
                      _hasSubstanceUseDisorder,
                      (v) => setState(() => _hasSubstanceUseDisorder = v!),
                    ),
                    _buildCheckbox(
                      'Artériopathie périphérique',
                      _hasPeripheralVascularDisease,
                      (v) => setState(() => _hasPeripheralVascularDisease = v!),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() => _showAdvancedHx = false),
                      icon: const Icon(Icons.expand_less, size: 18),
                      label: Text(
                        'Réduire',
                        style: GoogleFonts.inter(
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // ===== BOUTON DE PRÉDICTION =====
              _buildPredictButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== WIDGETS ====================

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [dangerColor, const Color(0xFFC2185B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: dangerColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.info_circle,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assistant de triage IA',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Renseignez les données du patient pour obtenir une prédiction du niveau d\'urgence',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 13),
          suffixText: suffix,
          suffixStyle: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
          prefixIcon: Icon(icon, size: 20, color: primaryColor),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Requis';
          }
          if (double.tryParse(value) == null) {
            return 'Nombre invalide';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: CheckboxListTile(
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade800,
          ),
        ),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
        activeColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildPredictButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _predict,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Iconsax.hospital, size: 22),
        label: Text(
          _isLoading ? 'Analyse en cours...' : 'PRÉDIRE LE TRIAGE',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: dangerColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: dangerColor.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 5,
          shadowColor: dangerColor.withOpacity(0.4),
        ),
      ),
    );
  }
}