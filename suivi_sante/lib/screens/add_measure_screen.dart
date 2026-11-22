// lib/screens/tension/add_measure_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/tension_provider.dart';
import '../../models/tension_measure.dart';
import 'dart:developer' as developer;

/// 📝 Écran d'ajout de mesure de tension artérielle
class AddMeasureScreen extends StatefulWidget {
  const AddMeasureScreen({super.key});

  @override
  State<AddMeasureScreen> createState() => _AddMeasureScreenState();
}

class _AddMeasureScreenState extends State<AddMeasureScreen> {
  // ============================================
  // CONTROLEURS
  // ============================================
  final _formKey = GlobalKey<FormState>();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _notesController = TextEditingController();

  // ============================================
  // VARIABLES D'ÉTAT
  // ============================================
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  bool _isFormValid = false;
  String? _bloodPressureCategory;
  String? _bloodPressureAdvice;

  // ============================================
  // CYCLE DE VIE
  // ============================================
  @override
  void initState() {
    super.initState();
    _log('📝 Initialisation');
    
    // 🔥 Ajouter des listeners pour la validation en temps réel
    _systolicController.addListener(_validateForm);
    _diastolicController.addListener(_validateForm);
    _heartRateController.addListener(_validateForm);
    
    // 🔥 Validation initiale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateForm();
    });
  }

  @override
  void dispose() {
    _log('🧹 Nettoyage');
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ============================================
  // MÉTHODES DE LOG
  // ============================================
  void _log(String message) {
    developer.log('[AddMeasureScreen] $message');
  }

  // ============================================
  // VALIDATION
  // ============================================
  void _validateForm() {
    _log('🔄 Validation du formulaire');
    
    final systolicText = _systolicController.text.trim();
    final diastolicText = _diastolicController.text.trim();
    final heartRateText = _heartRateController.text.trim();
    
    _log('📊 Valeurs: S=$systolicText, D=$diastolicText, HR=$heartRateText');
    
    // Valider la systolique
    final isSystolicValid = systolicText.isNotEmpty && 
        (int.tryParse(systolicText) ?? 0) >= 80 &&
        (int.tryParse(systolicText) ?? 0) <= 250;
    
    // Valider la diastolique
    final isDiastolicValid = diastolicText.isNotEmpty && 
        (int.tryParse(diastolicText) ?? 0) >= 50 &&
        (int.tryParse(diastolicText) ?? 0) <= 160;
    
    // Valider le pouls (optionnel)
    final isHeartRateValid = heartRateText.isEmpty || 
        ((int.tryParse(heartRateText) ?? 0) >= 30 &&
         (int.tryParse(heartRateText) ?? 0) <= 200);

    final newValid = isSystolicValid && isDiastolicValid && isHeartRateValid;
    
    _log('✅ Validation: S=$isSystolicValid, D=$isDiastolicValid, HR=$isHeartRateValid, Result=$newValid');
    
    if (newValid != _isFormValid) {
      setState(() {
        _isFormValid = newValid;
        _log('🔁 _isFormValid mis à jour: $_isFormValid');
      });
    }

    // Mettre à jour la catégorie de tension
    if (isSystolicValid && isDiastolicValid) {
      final systolic = int.parse(systolicText);
      final diastolic = int.parse(diastolicText);
      _updateBloodPressureCategory(systolic, diastolic);
    } else {
      setState(() {
        _bloodPressureCategory = null;
        _bloodPressureAdvice = null;
      });
    }
  }

  void _updateBloodPressureCategory(int systolic, int diastolic) {
    String category;
    String advice;

    if (systolic < 120 && diastolic < 80) {
      category = 'Normale';
      advice = '👍 Excellente tension, continuez ainsi !';
    } else if (systolic < 130 && diastolic < 80) {
      category = 'Élevée';
      advice = '⚠️ Tension légèrement élevée, surveillez votre alimentation.';
    } else if (systolic < 140 || diastolic < 90) {
      category = 'Hypertension stade 1';
      advice = '⚠️ Consultez votre médecin pour un suivi.';
    } else {
      category = 'Hypertension stade 2';
      advice = '🚨 Consultez votre médecin rapidement !';
    }

    setState(() {
      _bloodPressureCategory = category;
      _bloodPressureAdvice = advice;
    });
  }

  // ============================================
  // SÉLECTION DATE/HEURE
  // ============================================
  Future<void> _selectDate() async {
    _log('📅 Ouverture du sélecteur de date');
    try {
      final date = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF2563EB),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (date != null) {
        _log('📅 Date sélectionnée: ${DateFormat('dd/MM/yyyy').format(date)}');
        setState(() => _selectedDate = date);
      }
    } catch (e) {
      _log('❌ Erreur date: $e');
    }
  }

  Future<void> _selectTime() async {
    _log('⏰ Ouverture du sélecteur d\'heure');
    try {
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF2563EB),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (time != null) {
        _log('⏰ Heure sélectionnée: ${time.format(context)}');
        setState(() => _selectedTime = time);
      }
    } catch (e) {
      _log('❌ Erreur heure: $e');
    }
  }

  // ============================================
  // ENREGISTREMENT
  // ============================================
  Future<void> _saveMeasure() async {
    _log('💾 Tentative d\'enregistrement');
    
    // 🔥 Forcer la validation du formulaire
    final isValid = _formKey.currentState?.validate() ?? false;
    
    if (!isValid) {
      _log('⚠️ Formulaire invalide');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez corriger les erreurs du formulaire'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_isFormValid) {
      _log('⚠️ Formulaire non valide');
      return;
    }

    final combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    _log('📊 Création de la mesure pour ${DateFormat('dd/MM/yyyy HH:mm').format(combinedDateTime)}');

    setState(() => _isLoading = true);

    try {
      final measure = TensionMeasure(
        systolic: int.parse(_systolicController.text.trim()),
        diastolic: int.parse(_diastolicController.text.trim()),
        heartRate: _heartRateController.text.trim().isNotEmpty
            ? int.parse(_heartRateController.text.trim())
            : null,
        measureDate: combinedDateTime,
        notes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
      );

      _log('📤 Envoi au provider: ${measure.toJson()}');
      
      final provider = context.read<TensionProvider>();
      final success = await provider.addMeasure(measure);
      
      _log('📥 Résultat: success=$success');

      setState(() => _isLoading = false);

      if (success && mounted) {
        _log('✅ Mesure enregistrée');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Flexible(flex: 1, child: Text('✅ Mesure enregistrée avec succès !')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        _log('❌ Erreur enregistrement');
        final error = provider.error ?? 'Erreur inconnue';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Flexible(flex: 1, child: Text('❌ $error')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _log('❌ Exception: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Flexible(flex: 1, child: Text('❌ ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ============================================
  // BUILD PRINCIPAL
  // ============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // ============================================
  // APP BAR
  // ============================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Row(
        children: [
          Icon(Icons.add_circle_outline, color: Color(0xFF2563EB)),
          SizedBox(width: 10),
          Text(
            'Nouvelle mesure',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: const Color(0xFF1E293B),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: Color(0xFF2563EB)),
          onPressed: _showHelpDialog,
          tooltip: 'Aide',
        ),
      ],
    );
  }

  // ============================================
  // BODY PRINCIPAL
  // ============================================
  Widget _buildBody() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
            Colors.white,
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            onChanged: _validateForm, // 🔥 Validation automatique
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecentMeasuresPreview(),
                const SizedBox(height: 16),
                _buildFormCard(),
                const SizedBox(height: 20),
                _buildSaveButton(),
                const SizedBox(height: 16),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // APERÇU DES MESURES RÉCENTES - CORRIGÉ
  // ============================================
  Widget _buildRecentMeasuresPreview() {
    try {
      final provider = context.watch<TensionProvider>();
      final recentMeasures = provider.measures.take(3).toList();

      if (recentMeasures.isEmpty) {
        return const SizedBox();
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête - CORRIGÉ
            Row(
              children: [
                const Icon(Icons.history, size: 18, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Mesures récentes',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                // Afficher le nombre total de mesures
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${provider.measures.length} total',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Liste des mesures
            ...recentMeasures.map((measure) => _buildRecentMeasureItem(measure)),
          ],
        ),
      );
    } catch (e) {
      print('❌ Erreur dans _buildRecentMeasuresPreview: $e');
      return const SizedBox();
    }
  }

  // ============================================
  // ITEM MESURE RÉCENTE
  // ============================================
  Widget _buildRecentMeasureItem(TensionMeasure measure) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          // Indicateur de couleur
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getBloodPressureColor(measure.systolic, measure.diastolic),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Valeurs - Utilisation de Flexible
          Flexible(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${measure.systolic}/${measure.diastolic} mmHg',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (measure.heartRate != null)
                  Text(
                    '❤️ ${measure.heartRate} bpm',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          // Date - Utilisation de Flexible
          Flexible(
            flex: 1,
            child: Text(
              DateFormat('dd/MM HH:mm').format(measure.measureDate),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBloodPressureColor(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) return Colors.green;
    if (systolic < 130 && diastolic < 80) return Colors.orange;
    if (systolic < 140 || diastolic < 90) return Colors.orange.shade700;
    return Colors.red;
  }

  // ============================================
  // FORMULAIRE
  // ============================================
  Widget _buildFormCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      shadowColor: Colors.blue.shade100,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSystolicField(),
            const SizedBox(height: 16),
            _buildDiastolicField(),
            const SizedBox(height: 16),
            _buildHeartRateField(),
            const SizedBox(height: 16),
            _buildDateTimePickers(),
            const SizedBox(height: 16),
            if (_bloodPressureCategory != null)
              _buildBloodPressureCategory(),
            const SizedBox(height: 16),
            _buildNotesField(),
          ],
        ),
      ),
    );
  }

  // ============================================
  // CHAMPS DE SAISIE
  // ============================================
  Widget _buildSystolicField() {
    return TextFormField(
      controller: _systolicController,
      decoration: InputDecoration(
        labelText: 'Pression Systolique',
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        hintText: 'Ex: 120',
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.arrow_upward, color: Colors.red.shade700, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        suffixText: 'mmHg',
        suffixStyle: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(),
      style: const TextStyle(fontSize: 16),
      onChanged: (_) => _validateForm(),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Champ obligatoire';
        }
        final v = int.tryParse(value.trim());
        if (v == null || v < 80 || v > 250) {
          return 'Valeur invalide (80-250 mmHg)';
        }
        return null;
      },
    );
  }

  Widget _buildDiastolicField() {
    return TextFormField(
      controller: _diastolicController,
      decoration: InputDecoration(
        labelText: 'Pression Diastolique',
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        hintText: 'Ex: 80',
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.arrow_downward, color: Colors.blue.shade700, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        suffixText: 'mmHg',
        suffixStyle: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(),
      style: const TextStyle(fontSize: 16),
      onChanged: (_) => _validateForm(),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Champ obligatoire';
        }
        final v = int.tryParse(value.trim());
        if (v == null || v < 50 || v > 160) {
          return 'Valeur invalide (50-160 mmHg)';
        }
        return null;
      },
    );
  }

  Widget _buildHeartRateField() {
    return TextFormField(
      controller: _heartRateController,
      decoration: InputDecoration(
        labelText: 'Pouls',
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        hintText: 'Ex: 72 (optionnel)',
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.pink.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.favorite, color: Colors.pink.shade700, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        suffixText: 'bpm',
        suffixStyle: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(),
      style: const TextStyle(fontSize: 16),
      onChanged: (_) => _validateForm(),
      validator: (value) {
        if (value != null && value.trim().isNotEmpty) {
          final v = int.tryParse(value.trim());
          if (v == null || v < 30 || v > 200) {
            return 'Valeur invalide (30-200 bpm)';
          }
        }
        return null;
      },
    );
  }

  // ============================================
  // SÉLECTEURS DATE/HEURE - CORRIGÉ
  // ============================================
  Widget _buildDateTimePickers() {
    return Row(
      children: [
        Flexible(
          flex: 1,
          child: _buildDateTimePicker(
            label: 'Date',
            value: DateFormat('dd/MM/yyyy').format(_selectedDate),
            icon: Icons.calendar_today,
            onTap: _selectDate,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          flex: 1,
          child: _buildDateTimePicker(
            label: 'Heure',
            value: _selectedTime.format(context),
            icon: Icons.access_time,
            onTap: _selectTime,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2563EB), size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  // ============================================
  // CATÉGORIE DE TENSION
  // ============================================
  Widget _buildBloodPressureCategory() {
    Color color;
    IconData icon;
    
    switch (_bloodPressureCategory) {
      case 'Normale':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'Élevée':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case 'Hypertension stade 1':
        color = Colors.orange.shade700;
        icon = Icons.warning_amber;
        break;
      case 'Hypertension stade 2':
        color = Colors.red;
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _bloodPressureCategory!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _bloodPressureAdvice!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // CHAMP NOTES
  // ============================================
  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'Notes (optionnel)',
        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
        hintText: 'Ex: "Après le repas", "Stressé", "Médication"',
        prefixIcon: const Icon(Icons.note_add, color: Color(0xFF2563EB)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: 3,
      style: const TextStyle(fontSize: 14),
      onChanged: (_) => _validateForm(),
    );
  }

  // ============================================
  // BOUTON D'ENREGISTREMENT
  // ============================================
  Widget _buildSaveButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isLoading || !_isFormValid) ? null : _saveMeasure,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: _isFormValid ? 4 : 0,
          shadowColor: Colors.blue.shade200,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isFormValid ? Icons.save : Icons.lock_outline,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isFormValid ? '💾 Enregistrer la mesure' : '⚠️ Remplissez tous les champs',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================
  // FOOTER
  // ============================================
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 16,
            color: Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Text(
            'Données sécurisées et confidentielles',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // DIALOGUE D'AIDE - CORRIGÉ
  // ============================================
  Future<void> _showHelpDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Color(0xFF2563EB)),
            SizedBox(width: 10),
            Text('Conseils de mesure'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(
              '🪑 Position',
              'Asseyez-vous confortablement, dos droit, pieds au sol.',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              '💪 Bras',
              'Placez le brassard au niveau du cœur, bras détendu.',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              '⏰ Moment',
              'Mesurez à la même heure chaque jour, au repos.',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              '📊 Résultats',
              'Enregistrez vos valeurs pour un meilleur suivi.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  // ============================================
  // ITEM D'AIDE - CORRIGÉ
  // ============================================
  Widget _buildHelpItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}

