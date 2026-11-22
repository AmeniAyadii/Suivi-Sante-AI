// lib/screens/health_assessment_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../services/health_assessment_service.dart';
import '../theme/app_theme.dart';

class HealthAssessmentFormScreen extends StatefulWidget {
  const HealthAssessmentFormScreen({super.key});

  @override
  State<HealthAssessmentFormScreen> createState() =>
      _HealthAssessmentFormScreenState();
}

class _HealthAssessmentFormScreenState extends State<HealthAssessmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final HealthAssessmentService _service = HealthAssessmentService();

  bool _isLoading = false;

  // Contrôleurs de texte
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _sysController = TextEditingController();
  final _diaController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _tempController = TextEditingController();
  final _sleepController = TextEditingController();
  final _exerciseController = TextEditingController();
  final _waterController = TextEditingController();
  final _stressController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedMood = 'Neutre';
  final List<String> _moods = ['Heureux', 'Neutre', 'Triste', 'Fatigué', 'Stressé'];

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _sysController.dispose();
    _diaController.dispose();
    _heartRateController.dispose();
    _tempController.dispose();
    _sleepController.dispose();
    _exerciseController.dispose();
    _waterController.dispose();
    _stressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    // 1. Validation locale Flutter (bloque si hors limites)
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez corriger les erreurs du formulaire'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 2. Préparation des données (conversion sécurisée)
    setState(() => _isLoading = true);

    final Map<String, dynamic> data = {};

    if (_weightController.text.isNotEmpty) {
      data['weight'] = double.parse(_weightController.text);
    }
    if (_heightController.text.isNotEmpty) {
      data['height'] = double.parse(_heightController.text);
    }
    if (_sysController.text.isNotEmpty) {
      data['blood_pressure_systolic'] = int.parse(_sysController.text);
    }
    if (_diaController.text.isNotEmpty) {
      data['blood_pressure_diastolic'] = int.parse(_diaController.text);
    }
    if (_heartRateController.text.isNotEmpty) {
      data['heart_rate'] = int.parse(_heartRateController.text);
    }
    if (_tempController.text.isNotEmpty) {
      data['temperature'] = double.parse(_tempController.text);
    }
    if (_sleepController.text.isNotEmpty) {
      data['sleep_hours'] = double.parse(_sleepController.text);
    }
    if (_exerciseController.text.isNotEmpty) {
      data['exercise_minutes'] = int.parse(_exerciseController.text);
    }
    if (_waterController.text.isNotEmpty) {
      data['water_intake'] = int.parse(_waterController.text);
    }
    if (_stressController.text.isNotEmpty) {
      data['stress_level'] = int.parse(_stressController.text);
    }

    data['mood'] = _selectedMood;
    if (_notesController.text.isNotEmpty) {
      data['notes'] = _notesController.text;
    }

    try {
      await _service.saveAssessment(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Bilan enregistré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Retour à l'écran précédent
      }
    } catch (e) {
      if (mounted) {
        // Affiche l'erreur du backend (validation Laravel) proprement
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Erreur de validation'),
            content: SingleChildScrollView(
              child: Text(e.toString().replaceAll('Exception: ', '')),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Compris'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight;
    final textColor = isDark ? AppTheme.textDark : AppTheme.textLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        elevation: 0,
        title: Text(
          'Nouveau bilan',
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= PARAMÈTRES VITAUX =================
              _buildSectionTitle('🩺 Paramètres vitaux', isDark),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildNumericField(
                      controller: _weightController,
                      label: 'Poids (kg)',
                      icon: Iconsax.weight,
                      maxLength: 3,
                      min: 20,
                      max: 500,
                      isDecimal: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumericField(
                      controller: _heightController,
                      label: 'Taille (cm)',
                      icon: Icons.height,
                      maxLength: 3,
                      min: 50,
                      max: 300,
                      isDecimal: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildNumericField(
                      controller: _sysController,
                      label: 'Tension Sys. (mmHg)',
                      icon: Iconsax.heart,
                      maxLength: 3,
                      min: 80,
                      max: 250,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumericField(
                      controller: _diaController,
                      label: 'Tension Dia. (mmHg)',
                      icon: Iconsax.heart,
                      maxLength: 3,
                      min: 40,
                      max: 150,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildNumericField(
                      controller: _heartRateController,
                      label: 'Fréq. cardiaque (bpm)',
                      icon: Iconsax.activity,
                      maxLength: 3,
                      min: 30,
                      max: 200,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNumericField(
                      controller: _tempController,
                      label: 'Température (°C)',
                      icon: Iconsax.monitor,
                      maxLength: 4, // 37.5
                      min: 35,
                      max: 42,
                      isDecimal: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ================= MODE DE VIE =================
              _buildSectionTitle('🌿 Mode de vie', isDark),
              const SizedBox(height: 12),

              _buildNumericField(
                controller: _sleepController,
                label: 'Sommeil (heures)',
                icon: Iconsax.moon,
                maxLength: 2, // 24
                min: 0,
                max: 24,
                isDecimal: true,
              ),
              const SizedBox(height: 12),

              _buildNumericField(
                controller: _exerciseController,
                label: 'Exercice (minutes)',
                icon: Iconsax.activity,
                maxLength: 4, // 1440
                min: 0,
                max: 1440,
              ),
              const SizedBox(height: 12),

              _buildNumericField(
                controller: _waterController,
                label: 'Eau (ml)',
                icon: Iconsax.drop,
                maxLength: 5, // 10000
                min: 0,
                max: 10000,
              ),
              const SizedBox(height: 12),

              _buildNumericField(
                controller: _stressController,
                label: 'Niveau de stress (1-10)',
                icon: Iconsax.info_circle,
                maxLength: 2, // 10
                min: 0,
                max: 10,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _selectedMood,
                decoration: _inputDecoration('Humeur', Iconsax.emoji_happy),
                items: _moods.map((m) {
                  return DropdownMenuItem(value: m, child: Text(m));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMood = val);
                },
              ),

              const SizedBox(height: 24),

              // ================= NOTES =================
              _buildSectionTitle('📝 Notes', isDark),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: _inputDecoration(
                    'Notes supplémentaires...', Iconsax.document_text),
                style: TextStyle(color: textColor),
              ),

              const SizedBox(height: 32),

              // ================= BOUTON SOUMETTRE =================
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Enregistrer le bilan',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ================= WIDGETS UTILITAIRES =================

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? AppTheme.textDark : AppTheme.textLight,
      ),
    );
  }

  Widget _buildNumericField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required int maxLength,
    required num min,
    required num max,
    bool isDecimal = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      inputFormatters: [
        if (isDecimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')) // Chiffres + point
        else
          FilteringTextInputFormatter.digitsOnly, // Chiffres uniquement
        LengthLimitingTextInputFormatter(maxLength),
      ],
      decoration: _inputDecoration(label, icon),
      validator: (value) {
        if (value == null || value.isEmpty) return null; // Champ optionnel
        final num? parsed = isDecimal ? double.tryParse(value) : int.tryParse(value);
        if (parsed == null) return 'Valeur invalide';
        if (parsed < min || parsed > max) return 'Doit être entre $min et $max';
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.primaryLight),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryLight, width: 2),
      ),
    );
  }
}