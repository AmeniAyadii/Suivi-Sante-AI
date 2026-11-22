import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/doctor_service.dart';

class DoctorAddAppointmentScreen extends StatefulWidget {
  final List<Map<String, dynamic>> patients;
  final DateTime? initialDate;

  const DoctorAddAppointmentScreen({
    super.key,
    required this.patients,
    this.initialDate,
  });

  @override
  State<DoctorAddAppointmentScreen> createState() =>
      _Doctor9yMnTm4NSzvG9rrwjM2ec8xZgh1cafXH8();
}

class _Doctor9yMnTm4NSzvG9rrwjM2ec8xZgh1cafXH8
    extends State<DoctorAddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _lieuController = TextEditingController();
  final _notesController = TextEditingController();

  Map<String, dynamic>? _selectedPatient;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  int _duree = 30;
  String _type = 'Consultation';
  bool _isLoading = false;

  static const Color _primary = Color(0xFF00B894);

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
      _selectedTime = TimeOfDay.fromDateTime(widget.initialDate!);
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _lieuController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatient == null) {
      _showSnack('Veuillez sélectionner un patient', isError: true);
      return;
    }

    final dateHeure = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (dateHeure.isBefore(DateTime.now())) {
      _showSnack('La date doit être dans le futur', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await DoctorService().createRendezvous(
        patientId: _selectedPatient!['id'],
        titre: _titreController.text.trim(),
        dateHeure: dateHeure,
        duree: _duree,
        type: _type,
        lieu: _lieuController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      _showSnack('Rendez-vous créé avec succès');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showSnack('Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade600 : _primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final textColor = isDark ? Colors.white : const Color(0xFF2D3436);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Nouveau rendez-vous',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
        centerTitle: true,
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionTitle('Patient', isDark),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Map<String, dynamic>>(
                  isExpanded: true,
                  hint: Text('Choisir un patient',
                      style: GoogleFonts.inter(color: Colors.grey)),
                  value: _selectedPatient,
                  dropdownColor: cardColor,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: widget.patients.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: _primary.withOpacity(0.15),
                            child: Text(
                              (p['nom'] ?? '?')[0].toUpperCase(),
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _primary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(p['nom'],
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: textColor)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedPatient = val),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Détails', isDark),
            const SizedBox(height: 8),
            _buildTextField(
                controller: _titreController,
                label: 'Titre du RDV',
                hint: 'Ex: Consultation de suivi',
                isDark: isDark,
                validator: (v) => v!.isEmpty ? 'Requis' : null),
            const SizedBox(height: 12),
            _buildTypeDropdown(isDark, textColor),
            const SizedBox(height: 20),
            _sectionTitle('Date & Heure', isDark),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildPickerTile(
                    icon: Icons.calendar_month_rounded,
                    label: 'Date',
                    value: DateFormat('dd/MM/yyyy').format(_selectedDate),
                    onTap: _pickDate,
                    isDark: isDark,
                    textColor: textColor,
                    cardColor: cardColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPickerTile(
                    icon: Icons.access_time_rounded,
                    label: 'Heure',
                    value: _selectedTime.format(context),
                    onTap: _pickTime,
                    isDark: isDark,
                    textColor: textColor,
                    cardColor: cardColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionTitle('Durée', isDark),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [15, 30, 45, 60].map((d) {
                final selected = _duree == d;
                return ChoiceChip(
                  label: Text('$d min'),
                  selected: selected,
                  onSelected: (_) => setState(() => _duree = d),
                  selectedColor: _primary,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: selected ? Colors.white : textColor,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Lieu & Notes', isDark),
            const SizedBox(height: 8),
            _buildTextField(
                controller: _lieuController,
                label: 'Lieu',
                hint: 'Ex: Cabinet A',
                isDark: isDark),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _notesController,
              label: 'Notes',
              hint: 'Instructions particulières...',
              isDark: isDark,
              maxLines: 3,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      'Créer le rendez-vous',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.inter(
          color: isDark ? Colors.white : Colors.black87, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
        hintStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTypeDropdown(bool isDark, Color textColor) {
    final types = ['Consultation', 'Examen', 'Urgence', 'Suivi', 'Chirurgie'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _type,
          dropdownColor:
              isDark ? const Color(0xFF1E1E1E) : Colors.white,
          icon: Icon(Icons.category_rounded,
              size: 18, color: textColor.withOpacity(0.7)),
          items: types.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Text(t,
                  style: GoogleFonts.inter(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            );
          }).toList(),
          onChanged: (v) => setState(() => _type = v ?? 'Consultation'),
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
    required Color cardColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: _primary),
                const SizedBox(width: 6),
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
          ],
        ),
      ),
    );
  }
}