// lib/screens/symptome_form_screen.dart
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import '../models/symptome.dart';
import '../services/symptome_service.dart';

// ============================================================================
// LOGGER
// ============================================================================
class SymptomeFormLogger {
  static const String _tag = '📝 SymptomeForm';
  
  static void info(String message) {
    final log = '$_tag - ℹ️ $message';
    print(log);
    developer.log(log, name: 'INFO', time: DateTime.now());
  }
  
  static void debug(String message) {
    final log = '$_tag - 🐛 $message';
    print(log);
    developer.log(log, name: 'DEBUG', time: DateTime.now());
  }
  
  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    final log = '$_tag - ❌ $message';
    print(log);
    if (error != null) print('Erreur: $error');
    if (stackTrace != null) print(stackTrace);
    developer.log(log, name: 'ERROR', time: DateTime.now(), error: error, stackTrace: stackTrace);
  }
  
  static void success(String message) {
    final log = '$_tag - ✅ $message';
    print(log);
    developer.log(log, name: 'SUCCESS', time: DateTime.now());
  }
  
  static void warning(String message) {
    final log = '$_tag - ⚠️ $message';
    print(log);
    developer.log(log, name: 'WARNING', time: DateTime.now());
  }
}

// ============================================================================
// CONSTANTES
// ============================================================================
class SymptomeFormConstants {
  // ✅ Correction: Utilisation d'icônes Iconsax existantes
  static const List<Map<String, dynamic>> types = [
    {'label': '🤕 Douleur', 'value': 'douleur', 'icon': Iconsax.hospital},
    {'label': '😴 Fatigue', 'value': 'fatigue', 'icon': Iconsax.happyemoji},
    {'label': '🍽️ Digestif', 'value': 'digestif', 'icon': Iconsax.driver},
    {'label': '🫁 Respiratoire', 'value': 'respiratoire', 'icon': Iconsax.airplane},
    {'label': '🧠 Neurologique', 'value': 'neurologique', 'icon': Iconsax.bag}, // ✅ Remplacement de brain par bag
    {'label': '❤️ Cardiaque', 'value': 'cardiaque', 'icon': Iconsax.heart},
    {'label': '💪 Musculaire', 'value': 'musculaire', 'icon': Iconsax.directbox_send},
    {'label': '🧴 Cutané', 'value': 'cutane', 'icon': Iconsax.shield}, // ✅ Remplacement de skin par shield
    {'label': '📌 Général', 'value': 'general', 'icon': Iconsax.document},
  ];

  static const List<Map<String, dynamic>> statuses = [
    {'label': '🟢 Actif', 'value': 'actif', 'color': Color(0xFF00B894)},
    {'label': '🟡 En amélioration', 'value': 'en_amelioration', 'color': Color(0xFFFDCB6E)},
    {'label': '🔴 Aggravation', 'value': 'aggravation', 'color': Color(0xFFE17055)},
  ];

  static const List<Map<String, dynamic>> severities = [
    {'label': 'Léger', 'value': 1, 'color': Color(0xFF00B894)},
    {'label': 'Modéré', 'value': 5, 'color': Color(0xFFFDCB6E)},
    {'label': 'Sévère', 'value': 8, 'color': Color(0xFFE17055)},
    {'label': 'Critique', 'value': 10, 'color': Color(0xFFD63031)},
  ];
}

// ============================================================================
// SCREEN PRINCIPAL
// ============================================================================
class SymptomeFormScreen extends StatefulWidget {
  final Symptome? symptome;

  const SymptomeFormScreen({super.key, this.symptome});

  @override
  State<SymptomeFormScreen> createState() => _SymptomeFormScreenState();
}

class _SymptomeFormScreenState extends State<SymptomeFormScreen>
    with TickerProviderStateMixin {
  // ==========================================================================
  // CONTROLEURS
  // ==========================================================================
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _dureeController = TextEditingController();
  final _frequenceController = TextEditingController();

  // ==========================================================================
  // ÉTATS
  // ==========================================================================
  bool _isLoading = false;
  bool _isSubmitting = false;
  int _niveau = 5;
  String? _selectedType;
  String? _selectedStatus = 'actif';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // ==========================================================================
  // ANIMATIONS
  // ==========================================================================
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    SymptomeFormLogger.info('🔄 Initialisation du formulaire');
    _initAnimations();
    _loadDataForEdit();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _animationController.forward();
  }

  void _loadDataForEdit() {
    if (widget.symptome != null) {
      final s = widget.symptome!;
      _descriptionController.text = s.description;
      _niveau = s.niveau;
      _selectedType = s.type;
      _selectedStatus = s.status;
      _dureeController.text = s.duree ?? '';
      _frequenceController.text = s.frequence ?? '';
      _notesController.text = s.notes ?? '';
      _selectedDate = s.dateEnregistrement;
      _selectedTime = TimeOfDay.fromDateTime(s.dateEnregistrement);
      
      SymptomeFormLogger.debug('📝 Édition du symptôme #${s.id}');
    } else {
      SymptomeFormLogger.debug('📝 Création d\'un nouveau symptôme');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _dureeController.dispose();
    _frequenceController.dispose();
    SymptomeFormLogger.debug('🗑️ Formulaire détruit');
    super.dispose();
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.symptome != null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A1A) : const Color(0xFFF8F9FE),
      appBar: _buildAppBar(isDark, isEdit),
      body: _buildBody(isDark, isEdit),
    );
  }

  // ==========================================================================
  // APP BAR
  // ==========================================================================
  PreferredSizeWidget _buildAppBar(bool isDark, bool isEdit) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Text(
        isEdit ? 'Modifier le symptôme' : 'Nouveau symptôme',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextButton(
            onPressed: _isSubmitting ? null : _submitForm,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Enregistrer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // BODY
  // ==========================================================================
  Widget _buildBody(bool isDark, bool isEdit) {
    return SafeArea(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildHeader(isDark),
                  const SizedBox(height: 24),
                  _buildDescriptionField(isDark),
                  const SizedBox(height: 20),
                  _buildSeveritySection(isDark),
                  const SizedBox(height: 20),
                  _buildTypeAndStatusSection(isDark),
                  const SizedBox(height: 20),
                  _buildDurationAndFrequencySection(isDark),
                  const SizedBox(height: 20),
                  _buildDateTimeSection(isDark),
                  const SizedBox(height: 20),
                  _buildNotesField(isDark),
                  const SizedBox(height: 32),
                  _buildSubmitButton(isDark, isEdit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // HEADER
  // ==========================================================================
  Widget _buildHeader(bool isDark) {
    final isEdit = widget.symptome != null;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6C5CE7),
            const Color(0xFFA29BFE),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isEdit ? Iconsax.edit : Iconsax.add_circle,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Modification' : 'Nouveau symptôme',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEdit
                      ? 'Mettez à jour les informations'
                      : 'Enregistrez un nouveau symptôme',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
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

  // ==========================================================================
  // DESCRIPTION FIELD
  // ==========================================================================
  Widget _buildDescriptionField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 4,
        minLines: 3,
        decoration: InputDecoration(
          labelText: 'Description du symptôme',
          hintText: 'Décrivez précisément ce que vous ressentez...',
          prefixIcon: Icon(
            Iconsax.document_text,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 14,
          ),
          hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            fontSize: 14,
          ),
          errorStyle: const TextStyle(fontSize: 12),
        ),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 14,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez décrire le symptôme';
          }
          if (value.length < 3) {
            return 'La description doit contenir au moins 3 caractères';
          }
          return null;
        },
      ),
    );
  }

  // ==========================================================================
  // SEVERITY SECTION
  // ==========================================================================
  Widget _buildSeveritySection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.danger,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Niveau de gravité',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _getSeverityColor(_niveau).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getSeverityColor(_niveau).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '$_niveau / 10',
                  style: TextStyle(
                    color: _getSeverityColor(_niveau),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: Row(
              children: [
                ...SymptomeFormConstants.severities.map((severity) {
                  final isSelected = _niveau == severity['value'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _niveau = severity['value'] as int);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (severity['color'] as Color).withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? severity['color'] as Color
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            severity['label'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? severity['color'] as Color
                                  : isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _niveau.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: _niveau.toString(),
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _niveau = value.round());
            },
            activeColor: _getSeverityColor(_niveau),
            inactiveColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Léger',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ),
              Text(
                'Modéré',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ),
              Text(
                'Sévère',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ),
              Text(
                'Critique',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TYPE AND STATUS SECTION
  // ==========================================================================
  Widget _buildTypeAndStatusSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdownField(
              isDark: isDark,
              label: 'Type',
              hint: 'Sélectionnez un type',
              value: _selectedType,
              items: SymptomeFormConstants.types,
              onChanged: (value) {
                setState(() => _selectedType = value);
                SymptomeFormLogger.debug('📌 Type sélectionné: $value');
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Sélectionnez un type';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropdownField(
              isDark: isDark,
              label: 'Statut',
              hint: 'Statut actuel',
              value: _selectedStatus,
              items: SymptomeFormConstants.statuses,
              onChanged: (value) {
                setState(() => _selectedStatus = value);
                SymptomeFormLogger.debug('📊 Statut sélectionné: $value');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required bool isDark,
    required String label,
    required String hint,
    required String? value,
    required List<Map<String, dynamic>> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF0A0A1A) : const Color(0xFFF5F7FB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          fontSize: 13,
        ),
      ),
      items: items.map<DropdownMenuItem<String>>((item) {
        return DropdownMenuItem<String>(
          value: item['value'] as String,
          child: Row(
            children: [
              if (item.containsKey('icon'))
                Icon(
                  item['icon'] as IconData,
                  size: 18,
                  color: isDark ? Colors.white : Colors.black,
                ),
              if (item.containsKey('icon')) const SizedBox(width: 8),
              Text(
                item['label'] as String,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      icon: Icon(
        Icons.arrow_drop_down,
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
      ),
      dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 13,
      ),
    );
  }

  // ==========================================================================
  // DURATION AND FREQUENCY SECTION
  // ==========================================================================
  Widget _buildDurationAndFrequencySection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildTextField(
              isDark: isDark,
              controller: _dureeController,
              label: 'Durée',
              hint: 'Ex: 2 jours',
              icon: Iconsax.timer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTextField(
              isDark: isDark,
              controller: _frequenceController,
              label: 'Fréquence',
              hint: 'Ex: Quotidien',
              icon: Iconsax.repeat,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required bool isDark,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF0A0A1A) : const Color(0xFFF5F7FB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          fontSize: 13,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          fontSize: 13,
        ),
      ),
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 13,
      ),
    );
  }

  // ==========================================================================
  // DATE TIME SECTION
  // ==========================================================================
  Widget _buildDateTimeSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDateTimePicker(
              isDark: isDark,
              label: 'Date',
              value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              icon: Iconsax.calendar,
              onTap: _selectDate,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
          Expanded(
            child: _buildDateTimePicker(
              isDark: isDark,
              label: 'Heure',
              value: _selectedTime.format(context),
              icon: Iconsax.clock,
              onTap: _selectTime,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker({
    required bool isDark,
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // NOTES FIELD
  // ==========================================================================
  Widget _buildNotesField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _notesController,
        maxLines: 3,
        minLines: 2,
        decoration: InputDecoration(
          labelText: 'Notes supplémentaires',
          hintText: 'Ajoutez des informations complémentaires...',
          prefixIcon: Icon(
            Iconsax.note,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontSize: 14,
          ),
          hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            fontSize: 14,
          ),
        ),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 14,
        ),
      ),
    );
  }

  // ==========================================================================
  // SUBMIT BUTTON
  // ==========================================================================
  Widget _buildSubmitButton(bool isDark, bool isEdit) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C5CE7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: const Color(0xFF6C5CE7).withOpacity(0.3),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Enregistrement en cours...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEdit ? Iconsax.save_2 : Iconsax.add,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'Mettre à jour' : 'Enregistrer le symptôme',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ==========================================================================
  // DATE/TIME PICKERS
  // ==========================================================================
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C5CE7),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
      SymptomeFormLogger.debug('📅 Date sélectionnée: ${DateFormat('dd/MM/yyyy').format(date)}');
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6C5CE7),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTime = time);
      SymptomeFormLogger.debug('🕐 Heure sélectionnée: ${time.format(context)}');
    }
  }

  // ==========================================================================
  // SUBMIT LOGIC
  // ==========================================================================
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      SymptomeFormLogger.warning('⚠️ Formulaire invalide');
      return;
    }

    SymptomeFormLogger.info('📤 Soumission du formulaire');
    setState(() => _isSubmitting = true);

    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final data = {
        'description': _descriptionController.text.trim(),
        'niveau': _niveau,
        'type': _selectedType!,
        'duree': _dureeController.text.trim(),
        'frequence': _frequenceController.text.trim(),
        'notes': _notesController.text.trim(),
        'status': _selectedStatus ?? 'actif',
        'date_enregistrement': dateTime.toIso8601String(),
      };

      SymptomeFormLogger.debug('📦 Données: ${data.keys.join(', ')}');

      final service = SymptomeService();

      if (widget.symptome != null) {
        // Mode édition
        await service.updateSymptome(widget.symptome!.id!, data);
        SymptomeFormLogger.success('✅ Symptôme #${widget.symptome!.id} mis à jour');
        _showSnackbar('✅ Symptôme mis à jour avec succès', isSuccess: true);
      } else {
        // Mode création
        await service.createSymptome(data);
        SymptomeFormLogger.success('✅ Nouveau symptôme créé');
        _showSnackbar('✅ Symptôme enregistré avec succès', isSuccess: true);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e, stackTrace) {
      SymptomeFormLogger.error('❌ Erreur lors de la soumission', error: e, stackTrace: stackTrace);
      _showSnackbar('❌ Erreur: ${e.toString().replaceAll('Exception: ', '')}', isSuccess: false);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================
  Color _getSeverityColor(int level) {
    if (level <= 3) return const Color(0xFF00B894);
    if (level <= 5) return const Color(0xFFFDCB6E);
    if (level <= 7) return const Color(0xFFE17055);
    return const Color(0xFFD63031);
  }

  void _showSnackbar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? const Color(0xFF00B894) : const Color(0xFFE17055),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}