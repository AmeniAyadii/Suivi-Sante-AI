import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class DoctorPrescriptionForm extends StatefulWidget {
  final List<Map<String, dynamic>> patients;
  final String doctorName;
  final String doctorSpecialty;

  const DoctorPrescriptionForm({
    super.key,
    required this.patients,
    required this.doctorName,
    required this.doctorSpecialty,
  });

  @override
  State<DoctorPrescriptionForm> createState() => _DoctorPrescriptionFormState();
}

class _DoctorPrescriptionFormState extends State<DoctorPrescriptionForm> {
  final _formKey = GlobalKey<FormState>();
  final _instructionsController = TextEditingController();
  final PageController _pageController = PageController();

  int _currentStep = 0;
  Map<String, dynamic>? _selectedPatient;
  List<Map<String, dynamic>> _medicaments = [];
  bool _isLoading = false;

  // Couleurs du thème
  final Color _primaryGreen = const Color(0xFF00B894);
  final Color _primaryDarkGreen = const Color(0xFF009975);
  
  @override
  void dispose() {
    _instructionsController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _addMedicament() {
    setState(() {
      _medicaments.add({'nom': '', 'dosage': '', 'frequence': '', 'duree': ''});
    });
  }

  void _removeMedicament(int index) {
    setState(() => _medicaments.removeAt(index));
  }

  void _nextStep() {
    if (_selectedPatient == null) {
      _showSnack('Veuillez sélectionner un patient', isError: true);
      return;
    }
    if (_medicaments.isEmpty || _medicaments.any((m) => m['nom'].isEmpty)) {
      _showSnack('Veuillez ajouter au moins un médicament', isError: true);
      return;
    }
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentStep = 1);
  }

  void _previousStep() {
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentStep = 0);
  }

  Future<void> _generatePreview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulation API
      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PrescriptionPreviewScreen(
            patientName: _selectedPatient!['nom'],
            doctorName: widget.doctorName,
            doctorSpecialty: widget.doctorSpecialty,
            date: DateTime.now(),
            instructions: _instructionsController.text,
            medicaments: _medicaments,
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showSnack('Erreur: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade600 : _primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final textColor = isDark ? Colors.white : const Color(0xFF2D3436);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Nouvelle Ordonnance',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor),
        ),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildProgressIndicator(isDark, textColor),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(isDark, cardColor, borderColor, textColor),
                  _buildStep2(isDark, cardColor, textColor),
                ],
              ),
            ),
            _buildBottomActionBar(isDark, cardColor),
          ],
        ),
      ),
    );
  }

  // ==================== PROGRESS INDICATOR ====================
  Widget _buildProgressIndicator(bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildStepCircle(0, 'Patient & Médicaments', isDark, textColor),
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _currentStep >= 1 ? _primaryGreen : (isDark ? Colors.grey[700] : Colors.grey[300]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          _buildStepCircle(1, 'Instructions', isDark, textColor),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label, bool isDark, Color textColor) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? _primaryGreen : (isDark ? Colors.grey[800] : Colors.grey[200]),
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [BoxShadow(color: _primaryGreen.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]
                : [],
          ),
          child: Center(
            child: Icon(
              step == 0 ? Icons.person_rounded : Icons.edit_note_rounded,
              color: isActive ? Colors.white : Colors.grey,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? _primaryGreen : Colors.grey,
          ),
        ),
      ],
    );
  }

  // ==================== STEP 1 : PATIENT & MEDICAMENTS ====================
  Widget _buildStep1(bool isDark, Color cardColor, Color borderColor, Color textColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionTitle('Sélectionner un patient', isDark),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              isExpanded: true,
              hint: Text('Choisir un patient', style: GoogleFonts.inter(color: Colors.grey)),
              value: _selectedPatient,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              dropdownColor: cardColor,
              style: GoogleFonts.inter(color: textColor, fontSize: 14),
              items: widget.patients.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: _primaryGreen.withOpacity(0.15),
                        child: Text(
                          (p['nom'] ?? '?')[0].toUpperCase(),
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: _primaryGreen),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(p['nom'], style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textColor)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedPatient = val),
            ),
          ),
        ),
        const SizedBox(height: 28),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Médicaments', isDark),
            TextButton.icon(
              onPressed: _addMedicament,
              icon: Icon(Icons.add_circle_outline, color: _primaryGreen, size: 20),
              label: Text('Ajouter', style: GoogleFonts.inter(color: _primaryGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_medicaments.isEmpty)
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.medication_outlined, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text('Aucun médicament ajouté', style: GoogleFonts.inter(color: Colors.grey)),
                ],
              ),
            ),
          ),

        ..._medicaments.asMap().entries.map((entry) {
          return _buildMedicamentCard(entry.key, isDark, cardColor, borderColor, textColor)
              .animate().fadeIn(duration: 300.ms).slideX(begin: 0.1);
        }),
      ],
    );
  }

  // ==================== STEP 2 : INSTRUCTIONS ====================
  Widget _buildStep2(bool isDark, Color cardColor, Color textColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionTitle('Instructions & Remarques', isDark),
        const SizedBox(height: 10),
        TextFormField(
          controller: _instructionsController,
          maxLines: 5,
          style: GoogleFonts.inter(fontSize: 14, color: textColor),
          decoration: InputDecoration(
            hintText: 'Ex: Prendre après les repas, repos strict...',
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
            filled: true,
            fillColor: cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _primaryGreen, width: 1.5)),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(isDark ? 0.15 : 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'L\'ordonnance sera générée au format PDF. Vous pourrez la partager ou l\'imprimer.',
                  style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.blue[200] : Colors.blue[900]),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn().slideX();
  }

  // ==================== WIDGETS COMMUNS ====================
  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
      ),
    );
  }

  Widget _buildMedicamentCard(int idx, bool isDark, Color cardColor, Color borderColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Médicament ${idx + 1}',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: _primaryGreen),
                ),
              ),
              IconButton(
                onPressed: () => _removeMedicament(idx),
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInputField(
            label: 'Nom du médicament',
            hint: 'Ex: Paracétamol',
            onChanged: (v) => _medicaments[idx]['nom'] = v,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Dosage',
                  hint: 'Ex: 500mg',
                  onChanged: (v) => _medicaments[idx]['dosage'] = v,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInputField(
                  label: 'Durée',
                  hint: 'Ex: 7 jours',
                  onChanged: (v) => _medicaments[idx]['duree'] = v,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInputField(
            label: 'Fréquence',
            hint: 'Ex: 2 fois par jour',
            onChanged: (v) => _medicaments[idx]['frequence'] = v,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required Function(String) onChanged,
    required bool isDark,
  }) {
    return TextFormField(
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
        hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryGreen, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: (v) => v!.isEmpty ? 'Requis' : null,
    );
  }

  // ==================== BOTTOM ACTION BAR ====================
  Widget _buildBottomActionBar(bool isDark, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                ),
                child: Text('Retour', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : (_currentStep == 0 ? _nextStep : _generatePreview),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep == 0 ? 'Suivant' : 'Générer PDF',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentStep == 0 ? Icons.arrow_forward_rounded : Icons.picture_as_pdf_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// VUE D'APERÇU (PREVIEW) & PARTAGE/IMPRESSION
// =====================================================================
class PrescriptionPreviewScreen extends StatelessWidget {
  final String patientName;
  final String doctorName;
  final String doctorSpecialty;
  final DateTime date;
  final String instructions;
  final List<Map<String, dynamic>> medicaments;

  const PrescriptionPreviewScreen({
    super.key,
    required this.patientName,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.date,
    required this.instructions,
    required this.medicaments,
  });

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Dr. $doctorName', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(doctorSpecialty, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text('ORDONNANCE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green800, fontSize: 12)),
                ),
              ]
            ),
            pw.Divider(thickness: 1, height: 30, color: PdfColors.grey400),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Patient : $patientName', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date : ${DateFormat('dd/MM/yyyy').format(date)}', style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
                ]
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Text('Prescription', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            pw.SizedBox(height: 10),
            ...medicaments.map((m) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(m['nom'] ?? '', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Text('Dosage : ', style: const pw.TextStyle(color: PdfColors.grey700)),
                      pw.Text(m['dosage'] ?? '-', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 20),
                      pw.Text('Fréquence : ', style: const pw.TextStyle(color: PdfColors.grey700)),
                      pw.Text(m['frequence'] ?? '-', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 20),
                      pw.Text('Durée : ', style: const pw.TextStyle(color: PdfColors.grey700)),
                      pw.Text(m['duree'] ?? '-', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ]
                  ),
                ]
              )
            )),
            if (instructions.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              pw.Text('Instructions supplémentaires :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text(instructions, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
            ],
            pw.SizedBox(height: 60),
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Column(
                children: [
                  pw.Text('Signature & Cachet', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                  pw.SizedBox(height: 50),
                  pw.Container(width: 150, height: 1, color: PdfColors.grey400),
                ]
              )
            )
          ];
        }
      )
    );
    return pdf;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF0F2F5);
    final textColor = isDark ? Colors.white : const Color(0xFF2D3436);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Aperçu de l\'ordonnance', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor)),
        centerTitle: true,
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ✅ Aperçu visuel (faux papier) - Il reste BLANC pour simuler une vraie ordonnance
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white, // Toujours blanc pour le réalisme
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dr. $doctorName', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                        const SizedBox(height: 4),
                        Text(doctorSpecialty, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B894).withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ORDONNANCE', 
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, color: const Color(0xFF00B894)),
                      ),
                    )
                  ],
                ),
                const Divider(height: 30, thickness: 1.5, color: Colors.black12),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Patient : $patientName', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                      Text('Date : ${DateFormat('dd/MM/yyyy').format(date)}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700])),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                Text('PRESCRIPTION', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1)),
                const SizedBox(height: 10),
                ...medicaments.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['nom'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                      const SizedBox(height: 6),
                      Text(
                        'Dosage : ${m['dosage'] ?? '-'}  •  Fréquence : ${m['frequence'] ?? '-'}  •  Durée : ${m['duree'] ?? '-'}', 
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                )),

                if (instructions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('INSTRUCTIONS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Text(instructions, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87, height: 1.4)),
                ],

                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    children: [
                      Text('Signature & Cachet', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
                      const SizedBox(height: 30),
                      Container(width: 120, height: 1, color: Colors.grey[400]),
                    ],
                  ),
                )
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
          
          const SizedBox(height: 24),
          
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final pdf = await _generatePdf();
                    final bytes = await pdf.save();
                    await Share.shareXFiles([XFile.fromData(bytes, name: 'ordonnance_$patientName.pdf', mimeType: 'application/pdf')]);
                  },
                  icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                  label: Text('Partager', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0984E3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final pdf = await _generatePdf();
                    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
                  },
                  icon: Icon(Icons.print_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
                  label: Text('Imprimer', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[400]!),
                    backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}