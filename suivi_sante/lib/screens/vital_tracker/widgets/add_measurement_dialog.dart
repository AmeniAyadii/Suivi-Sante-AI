// lib/screens/vital_tracker/widgets/add_measurement_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/constante_vitale.dart';
import '../../../providers/vital_provider.dart';

class AddMeasurementDialog extends StatefulWidget {
  const AddMeasurementDialog({Key? key}) : super(key: key);

  @override
  State<AddMeasurementDialog> createState() => _AddMeasurementDialogState();
}

class _AddMeasurementDialogState extends State<AddMeasurementDialog> {
  final _formKey = GlobalKey<FormState>();
  TypeConstante? _selectedType;
  final _valeurController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '➕ Ajouter une mesure',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A6B),
                ),
              ),
              const SizedBox(height: 20),
              
              // Type de constante
              DropdownButtonFormField<TypeConstante>(
                decoration: InputDecoration(
                  labelText: 'Type de constante',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.medical_services),
                ),
                value: _selectedType,
                items: TypeConstante.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text('${type.icon} ${type.label}'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedType = value),
                validator: (value) =>
                    value == null ? 'Sélectionnez un type' : null,
              ),
              
              const SizedBox(height: 16),
              
              // Valeur
              TextFormField(
                controller: _valeurController,
                decoration: InputDecoration(
                  labelText: 'Valeur',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.numbers),
                  suffixText: _selectedType?.uniteParDefaut ?? '',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir une valeur';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez saisir un nombre valide';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Date
              ListTile(
                title: const Text('Date et heure'),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate),
                ),
                leading: const Icon(Icons.calendar_today),
                onTap: _selectDate,
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              ),
              
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Flexible(flex: 1, child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Enregistrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A5BB5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  // lib/screens/vital_tracker/widgets/add_measurement_dialog.dart

void _submit() async {
  if (!_formKey.currentState!.validate()) return;
  
  setState(() => _isLoading = true);
  
  try {
    final provider = Provider.of<VitalProvider>(context, listen: false);
    
    // ✅ Utiliser la bonne valeur pour l'API
    final typeValue = _selectedType!.value;
    debugPrint('📤 Envoi type: $typeValue');
    
    await provider.addConstante(
      typeConstante: typeValue, // ✅ Utiliser .value
      valeur: double.parse(_valeurController.text),
      unite: _selectedType!.uniteParDefaut,
      dateMesure: _selectedDate,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Mesure ajoutée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  if (mounted) {
    setState(() => _isLoading = false);
  }
}

  @override
  void dispose() {
    _valeurController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

