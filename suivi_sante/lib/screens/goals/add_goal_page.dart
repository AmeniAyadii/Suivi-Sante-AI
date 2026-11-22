// lib/screens/goals/add_goal_page.dart
// Version: 2.0.0
// Description: Page d'ajout et de modification d'objectifs avec logs complets

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:suivi_sante_pro/models/goal.dart';
import 'package:suivi_sante_pro/providers/goals_provider.dart';

// ============================================================
// LOGGER UTILITY
// ============================================================
class AddGoalLogger {
  static const String _tag = '📝 ADD_GOAL';
  
  static void info(String message) {
    debugPrint('$_tag ℹ️ $message');
  }
  
  static void success(String message) {
    debugPrint('$_tag ✅ $message');
  }
  
  static void warning(String message) {
    debugPrint('$_tag ⚠️ $message');
  }
  
  static void error(String message, {dynamic error, StackTrace? stackTrace}) {
    debugPrint('$_tag ❌ $message');
    if (error != null) debugPrint('$_tag 📍 Error: $error');
    if (stackTrace != null) debugPrint('$_tag 📍 Stack: $stackTrace');
  }
  
  static void lifecycle(String message) {
    debugPrint('$_tag 🔄 $message');
  }
  
  static void data(String message) {
    debugPrint('$_tag 📊 $message');
  }
  
  static void navigation(String message) {
    debugPrint('$_tag 🧭 $message');
  }
}

// ============================================================
// MAIN PAGE
// ============================================================
class AddGoalPage extends StatefulWidget {
  final String? goalId;

  const AddGoalPage({Key? key, this.goalId}) : super(key: key);

  @override
  State<AddGoalPage> createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  // ============================================================
  // CONTROLLERS & VARIABLES
  // ============================================================
  
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController();
  final _unitController = TextEditingController();
  
  GoalCategory _selectedCategory = GoalCategory.other;
  DateTime _startDate = DateTime.now();
  DateTime? _targetDate;
  bool _isRecurring = false;
  String? _recurrencePattern;
  String _selectedIcon = '🎯';
  String _selectedColor = '#4CAF50';
  final List<GoalMilestone> _milestones = [];
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isDisposed = false;

  // ============================================================
  // CONSTANTS
  // ============================================================
  
  final List<Map<String, String>> _icons = const [
    {'emoji': '🎯', 'name': 'Objectif'},
    {'emoji': '💊', 'name': 'Médicament'},
    {'emoji': '🏃', 'name': 'Sport'},
    {'emoji': '🍎', 'name': 'Nutrition'},
    {'emoji': '💧', 'name': 'Hydratation'},
    {'emoji': '😴', 'name': 'Sommeil'},
    {'emoji': '❤️', 'name': 'Santé'},
    {'emoji': '🧘', 'name': 'Bien-être'},
    {'emoji': '📚', 'name': 'Apprentissage'},
    {'emoji': '⚖️', 'name': 'Poids'},
    {'emoji': '🩸', 'name': 'Glycémie'},
    {'emoji': '📊', 'name': 'Statistiques'},
  ];

  final List<Color> _colors = const [
    Color(0xFF4CAF50), // Vert
    Color(0xFF2196F3), // Bleu
    Color(0xFFFF9800), // Orange
    Color(0xFFF44336), // Rouge
    Color(0xFF9C27B0), // Violet
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFF5722), // Orange profond
    Color(0xFF8BC34A), // Vert clair
    Color(0xFFE91E63), // Rose
    Color(0xFF3F51B5), // Indigo
    Color(0xFFFF6B6B), // Corail
    Color(0xFF6C63FF), // Violet clair
  ];

  // ============================================================
  // LIFECYCLE
  // ============================================================
  
  @override
  void initState() {
    super.initState();
    _isEditing = widget.goalId != null;
    AddGoalLogger.lifecycle('Page initialisée - Mode: ${_isEditing ? "Édition" : "Création"}');
    
    if (_isEditing) {
      AddGoalLogger.info('Chargement des données pour l\'édition: ${widget.goalId}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed && mounted) {
          _loadGoalData();
        }
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    AddGoalLogger.lifecycle('Page disposée');
    
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA LOADING
  // ============================================================
  
  void _loadGoalData() {
    AddGoalLogger.info('Chargement des données de l\'objectif');
    
    try {
      final provider = context.read<GoalsProvider>();
      AddGoalLogger.data('Provider récupéré, ${provider.goals.length} objectifs disponibles');
      
      final goal = provider.goals.firstWhere(
        (g) => g.id == widget.goalId,
        orElse: () {
          AddGoalLogger.warning('Objectif non trouvé, création d\'un nouveau');
          return Goal(
            id: '',
            title: '',
            description: '',
            category: GoalCategory.other,
            targetValue: 0,
            currentValue: 0,
            unit: '',
            status: GoalStatus.notStarted,
            startDate: DateTime.now(),
            progressPercentage: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        },
      );
      
      if (goal.id.isNotEmpty) {
        AddGoalLogger.success('Objectif chargé: ${goal.title}');
        
        _titleController.text = goal.title;
        _descriptionController.text = goal.description ?? '';
        _selectedCategory = goal.category;
        _targetController.text = goal.targetValue.toString();
        _unitController.text = goal.unit;
        _startDate = goal.startDate;
        _targetDate = goal.targetDate;
        _selectedIcon = goal.icon;
        _selectedColor = goal.colorHex;
        _milestones.addAll(goal.milestones);
        _isRecurring = goal.isRecurring;
        _recurrencePattern = goal.recurrencePattern;
        
        AddGoalLogger.data('Données chargées - Titre: ${goal.title}, Catégorie: ${goal.category}, Cible: ${goal.targetValue}');
      } else {
        AddGoalLogger.warning('Aucune donnée chargée, formulaire vide');
      }
    } catch (e, stackTrace) {
      AddGoalLogger.error('Erreur lors du chargement', error: e, stackTrace: stackTrace);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  
  @override
  Widget build(BuildContext context) {
    if (_isDisposed) return const SizedBox.shrink();
    
    AddGoalLogger.lifecycle('Build page');
    
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _isEditing ? '✏️ Modifier l\'objectif' : '➕ Nouvel objectif',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.check, size: 28),
          onPressed: _isLoading ? null : _saveGoal,
          tooltip: _isEditing ? 'Mettre à jour' : 'Créer',
        ),
      ],
    );
  }

  // ============================================================
  // BODY
  // ============================================================
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.blue,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Enregistrement en cours...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIconSelector(),
            const SizedBox(height: 16),
            _buildColorSelector(),
            const SizedBox(height: 16),
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 16),
            _buildCategoryDropdown(),
            const SizedBox(height: 16),
            _buildTargetField(),
            const SizedBox(height: 16),
            _buildDateSelectors(),
            const SizedBox(height: 16),
            _buildRecurrenceToggle(),
            const SizedBox(height: 16),
            _buildMilestonesSection(),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS
  // ============================================================
  
  Widget _buildIconSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisissez une icône',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _icons.map((icon) {
              final isSelected = _selectedIcon == icon['emoji'];
              return GestureDetector(
                onTap: () {
                  AddGoalLogger.data('Icône sélectionnée: ${icon['emoji']} - ${icon['name']}');
                  setState(() => _selectedIcon = icon['emoji']!);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(icon['emoji']!, style: const TextStyle(fontSize: 22)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisissez une couleur',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colors.map((color) {
            final isSelected = _selectedColor == _colorToHex(color);
            return GestureDetector(
              onTap: () {
                AddGoalLogger.data('Couleur sélectionnée: ${_colorToHex(color)}');
                setState(() => _selectedColor = _colorToHex(color));
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey[300]!,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: isSelected
                    ? const Center(child: Icon(Icons.check, color: Colors.white, size: 20))
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Titre de l\'objectif *',
        hintText: 'Ex: Perdre 2kg, Courir 5km, ...',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.title),
      ),
      onChanged: (value) {
        AddGoalLogger.data('Titre modifié: "$value"');
      },
      validator: (value) {
        if (value?.trim().isEmpty ?? true) {
          return 'Veuillez entrer un titre';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'Décrivez votre objectif en détail...',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
      ),
      maxLines: 3,
      onChanged: (value) {
        AddGoalLogger.data('Description modifiée (${value.length} caractères)');
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<GoalCategory>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Catégorie *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: GoalCategory.values.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(_getCategoryLabel(category)),
        );
      }).toList(),
      onChanged: (value) {
        AddGoalLogger.data('Catégorie sélectionnée: ${_getCategoryLabel(value!)}');
        setState(() => _selectedCategory = value);
      },
      validator: (value) {
        if (value == null) return 'Veuillez sélectionner une catégorie';
        return null;
      },
    );
  }

  Widget _buildTargetField() {
    return Row(
      children: [
        Flexible(
          flex: 2,
          child: TextFormField(
            controller: _targetController,
            decoration: const InputDecoration(
              labelText: 'Valeur cible *',
              hintText: 'Ex: 10, 5.5, ...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.tablet),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              AddGoalLogger.data('Valeur cible modifiée: "$value"');
            },
            validator: (value) {
              if (value?.trim().isEmpty ?? true) return 'Valeur requise';
              if (double.tryParse(value!) == null) return 'Entrez un nombre valide';
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: TextFormField(
            controller: _unitController,
            decoration: const InputDecoration(
              labelText: 'Unité *',
              hintText: 'kg, km, ...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.scale),
            ),
            onChanged: (value) {
              AddGoalLogger.data('Unité modifiée: "$value"');
            },
            validator: (value) {
              if (value?.trim().isEmpty ?? true) return 'Unité requise';
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelectors() {
    return Row(
      children: [
        Flexible(
          child: _buildDatePicker(
            label: 'Date de début',
            date: _startDate,
            onChanged: (date) {
              AddGoalLogger.data('Date de début: ${DateFormat('dd/MM/yyyy').format(date)}');
              setState(() => _startDate = date);
            },
            firstDate: DateTime(2020),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(flex: 1, child: _buildDatePicker(
            label: 'Date cible (optionnelle)',
            date: _targetDate,
            onChanged: (date) {
              AddGoalLogger.data('Date cible: ${DateFormat('dd/MM/yyyy').format(date)}');
              setState(() => _targetDate = date);
            },
            firstDate: DateTime.now(),
            isOptional: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required Function(DateTime) onChanged,
    required DateTime firstDate,
    bool isOptional = false,
  }) {
    return GestureDetector(
      onTap: () async {
        AddGoalLogger.navigation('Ouverture du sélecteur de date: $label');
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: firstDate,
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: Colors.blue),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          AddGoalLogger.success('Date sélectionnée: ${DateFormat('dd/MM/yyyy').format(picked)}');
          onChanged(picked);
        } else {
          AddGoalLogger.info('Sélection de date annulée');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  Text(
                    date != null
                        ? DateFormat('dd/MM/yyyy').format(date)
                        : isOptional ? 'Pas de date' : 'Sélectionner',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceToggle() {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text(
                'Objectif récurrent',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Répéter cet objectif régulièrement'),
              value: _isRecurring,
              onChanged: (value) {
                AddGoalLogger.data('Récurrence ${value ? "activée" : "désactivée"}');
                setState(() {
                  _isRecurring = value;
                  if (!value) _recurrencePattern = null;
                });
              },
              activeColor: Colors.blue,
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _recurrencePattern,
                decoration: const InputDecoration(
                  labelText: 'Fréquence de répétition',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.repeat),
                ),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('📅 Quotidien')),
                  DropdownMenuItem(value: 'weekly', child: Text('📅 Hebdomadaire')),
                  DropdownMenuItem(value: 'monthly', child: Text('📅 Mensuel')),
                ],
                onChanged: (value) {
                  AddGoalLogger.data('Fréquence sélectionnée: $value');
                  setState(() => _recurrencePattern = value);
                },
                validator: (value) {
                  if (_isRecurring && value == null) return 'Sélectionnez une fréquence';
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesSection() {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📌 Étapes intermédiaires',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez des sous-objectifs pour suivre votre progression',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            if (_milestones.isNotEmpty) ...[
              ..._milestones.map((milestone) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      milestone.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: milestone.isCompleted ? Colors.green : Colors.grey,
                    ),
                    title: Text(milestone.title),
                    subtitle: Text(
                      'Valeur: ${milestone.targetValue}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        AddGoalLogger.data('Étape supprimée: ${milestone.title}');
                        setState(() => _milestones.remove(milestone));
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
            TextButton.icon(
              onPressed: _addMilestone,
              icon: const Icon(Icons.add_circle),
              label: const Text('Ajouter une étape'),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  void _addMilestone() {
    AddGoalLogger.navigation('Ouverture du dialogue d\'ajout d\'étape');
    
    final titleController = TextEditingController();
    final valueController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouvelle étape intermédiaire'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre de l\'étape *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: valueController,
                decoration: const InputDecoration(
                  labelText: 'Valeur cible *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tablet),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                AddGoalLogger.info('Ajout d\'étape annulé');
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final value = double.tryParse(valueController.text);
                if (title.isNotEmpty && value != null && value > 0) {
                  AddGoalLogger.success('Étape ajoutée: "$title" ($value)');
                  setState(() {
                    _milestones.add(GoalMilestone(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: title,
                      targetValue: value,
                    ));
                  });
                  Navigator.pop(context);
                } else {
                  AddGoalLogger.warning('Étape invalide - Titre: "$title", Valeur: $value');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez remplir tous les champs correctement'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveGoal,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isEditing ? '✏️ Mettre à jour' : '🎯 Créer l\'objectif',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // ============================================================
  // SAVE METHOD
  // ============================================================
  
  void _saveGoal() async {
    AddGoalLogger.info('=== DÉBUT DE LA SAUVEGARDE ===');
    AddGoalLogger.info('Mode: ${_isEditing ? "Édition" : "Création"}');
    
    // 1. Validation du formulaire
    if (!_formKey.currentState!.validate()) {
      AddGoalLogger.warning('Formulaire invalide');
      return;
    }
    AddGoalLogger.success('Formulaire valide');

    // 2. Activation du chargement
    setState(() => _isLoading = true);

    try {
      // 3. Récupération des données
      final targetValue = double.parse(_targetController.text);
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null;
      final unit = _unitController.text.trim();
      
      AddGoalLogger.data('📝 Données récupérées:');
      AddGoalLogger.data('  - Titre: "$title"');
      AddGoalLogger.data('  - Description: "${description ?? "Aucune"}"');
      AddGoalLogger.data('  - Catégorie: ${_getCategoryLabel(_selectedCategory)}');
      AddGoalLogger.data('  - Cible: $targetValue $unit');
      AddGoalLogger.data('  - Étapes: ${_milestones.length}');
      AddGoalLogger.data('  - Récurrent: $_isRecurring');
      AddGoalLogger.data('  - Icône: $_selectedIcon');
      AddGoalLogger.data('  - Couleur: $_selectedColor');

      // 4. Construction de l'objet Goal
      final goal = Goal(
        id: widget.goalId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        category: _selectedCategory,
        targetValue: targetValue,
        currentValue: _isEditing ? _getCurrentGoalValue() : 0,
        unit: unit,
        status: _isEditing ? _getCurrentGoalStatus() : GoalStatus.notStarted,
        startDate: _startDate,
        targetDate: _targetDate,
        progressPercentage: _isEditing ? _getCurrentGoalProgress() : 0,
        milestones: _milestones,
        isRecurring: _isRecurring,
        recurrencePattern: _recurrencePattern,
        icon: _selectedIcon,
        colorHex: _selectedColor,
        reminders: const [],
        createdAt: _isEditing ? _getCurrentGoalCreatedAt() : DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      AddGoalLogger.success('✅ Goal créé: ${goal.id}');

      // 5. Sauvegarde via le provider
      final provider = context.read<GoalsProvider>();
      
      if (_isEditing) {
        AddGoalLogger.info('✏️ Mise à jour de l\'objectif...');
        await provider.updateGoal(goal);
        AddGoalLogger.success('✅ Objectif mis à jour avec succès');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Objectif mis à jour avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        AddGoalLogger.info('➕ Création du nouvel objectif...');
        await provider.addGoal(goal);
        AddGoalLogger.success('✅ Objectif créé avec succès');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Objectif créé avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      AddGoalLogger.info('=== SAUVEGARDE RÉUSSIE ===');
      if (mounted) {
        Navigator.pop(context, true);
      }
      
    } catch (e, stackTrace) {
      AddGoalLogger.error('❌ Erreur lors de la sauvegarde', error: e, stackTrace: stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString().split('\n').first}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        AddGoalLogger.info('État de chargement désactivé');
      }
    }
  }

  // ============================================================
  // UTILITY METHODS
  // ============================================================
  
  double _getCurrentGoalValue() {
    try {
      final provider = context.read<GoalsProvider>();
      final goal = provider.goals.firstWhere((g) => g.id == widget.goalId);
      AddGoalLogger.data('Valeur actuelle: ${goal.currentValue}');
      return goal.currentValue;
    } catch (e) {
      AddGoalLogger.warning('Impossible de récupérer la valeur actuelle, retour à 0');
      return 0;
    }
  }

  GoalStatus _getCurrentGoalStatus() {
    try {
      final provider = context.read<GoalsProvider>();
      final goal = provider.goals.firstWhere((g) => g.id == widget.goalId);
      AddGoalLogger.data('Statut actuel: ${goal.status}');
      return goal.status;
    } catch (e) {
      AddGoalLogger.warning('Impossible de récupérer le statut, retour à notStarted');
      return GoalStatus.notStarted;
    }
  }

  int _getCurrentGoalProgress() {
    try {
      final provider = context.read<GoalsProvider>();
      final goal = provider.goals.firstWhere((g) => g.id == widget.goalId);
      AddGoalLogger.data('Progression actuelle: ${goal.progressPercentage}%');
      return goal.progressPercentage;
    } catch (e) {
      AddGoalLogger.warning('Impossible de récupérer la progression, retour à 0');
      return 0;
    }
  }

  DateTime _getCurrentGoalCreatedAt() {
    try {
      final provider = context.read<GoalsProvider>();
      final goal = provider.goals.firstWhere((g) => g.id == widget.goalId);
      return goal.createdAt;
    } catch (e) {
      AddGoalLogger.warning('Impossible de récupérer la date de création, retour à maintenant');
      return DateTime.now();
    }
  }

  String _getCategoryLabel(GoalCategory category) {
    switch (category) {
      case GoalCategory.medication: return '💊 Médicaments';
      case GoalCategory.exercise: return '🏃 Sport/Exercice';
      case GoalCategory.nutrition: return '🍎 Nutrition/Alimentation';
      case GoalCategory.sleep: return '😴 Sommeil';
      case GoalCategory.hydration: return '💧 Hydratation';
      case GoalCategory.weight: return '⚖️ Poids';
      case GoalCategory.bloodPressure: return '❤️ Tension artérielle';
      case GoalCategory.bloodSugar: return '🩸 Glycémie';
      case GoalCategory.stress: return '🧘 Gestion du stress';
      default: return '📌 Autre';
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}

