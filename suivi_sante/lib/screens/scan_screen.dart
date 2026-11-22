import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:suivi_sante_pro/config/app_config.dart';
import '../services/scan_service.dart';
import '../models/scanned_medication.dart';

// ==================== MODÈLE DE MÉDICAMENT DÉTAILLÉ ====================
class MedicationDetail {
  final String nom;
  final String? code;
  final String? forme;
  final String? dosage;
  final String? presentation;
  final List<String> ingredients;
  final List<String> indications;
  final List<String> contreIndications;
  final List<String> effetsSecondaires;
  final List<String> precautions;
  final String? posologie;
  final String? conservation;
  final String? prix;
  final String? imageUrl;
  final String? fabricant;

  MedicationDetail({
    required this.nom,
    this.code,
    this.forme,
    this.dosage,
    this.presentation,
    this.ingredients = const [],
    this.indications = const [],
    this.contreIndications = const [],
    this.effetsSecondaires = const [],
    this.precautions = const [],
    this.posologie,
    this.conservation,
    this.prix,
    this.imageUrl,
    this.fabricant,
  });

  factory MedicationDetail.fromJson(Map<String, dynamic> json) {
    return MedicationDetail(
      nom: json['nom'] ?? 'Médicament inconnu',
      code: json['code'] ?? json['barcode'],
      forme: json['forme'],
      dosage: json['dosage'],
      presentation: json['presentation'],
      ingredients: _parseList(json['ingredients']),
      indications: _parseList(json['indications']),
      contreIndications: _parseList(json['contre_indications'] ?? json['contreIndications']),
      effetsSecondaires: _parseList(json['effets_secondaires'] ?? json['effetsSecondaires']),
      precautions: _parseList(json['precautions']),
      posologie: json['posologie'],
      conservation: json['conservation'],
      prix: json['prix'],
      imageUrl: json['image_url'] ?? json['imageUrl'],
      fabricant: json['fabricant'],
    );
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return [];
  }
}

// ==================== SERVICE API MÉDICAMENT ====================
class MedicationApiService {
  static String get baseUrl => '${AppConfig.baseUrl}/medicaments/';
  static const String openFdaUrl = 'https://api.fda.gov/drug/ndc.json';

  Future<MedicationDetail?> getMedicationByBarcode(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}search?barcode=$barcode'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return MedicationDetail.fromJson(data['data']);
        }
      }

      return await _searchOpenFDA(barcode);
    } catch (e) {
      print('❌ Erreur API: $e');
      return null;
    }
  }

  Future<MedicationDetail?> _searchOpenFDA(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('$openFdaUrl?search=product_ndc:"$barcode"'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          return _parseOpenFDA(results.first);
        }
      }
      return null;
    } catch (e) {
      print('❌ Erreur OpenFDA: $e');
      return null;
    }
  }

  MedicationDetail _parseOpenFDA(Map<String, dynamic> data) {
    final product = data['openfda'] ?? {};
    final ingredientsList = product['ingredient'] as List? ?? [];
    final brandName = product['brand_name'] as List? ?? [];
    final genericName = product['generic_name'] as List? ?? [];

    return MedicationDetail(
      nom: brandName.isNotEmpty ? brandName.first : (genericName.isNotEmpty ? genericName.first : 'Médicament'),
      code: data['product_ndc'] ?? data['ndc'],
      ingredients: ingredientsList.map((e) => e.toString()).toList(),
      indications: ['Information non disponible', 'Consultez votre médecin'],
      contreIndications: ['Consultez votre médecin'],
      effetsSecondaires: [],
      precautions: [],
    );
  }
}

// ==================== THÈME DE COULEURS ÉLÉGANT ====================
class ElegantColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B83FF);
  static const Color primaryDark = Color(0xFF5046E5);
  static const Color secondary = Color(0xFF00D2FF);
  static const Color accent = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color cardShadow = Color(0x1A6C63FF);
  static const Color gradientStart = Color(0xFF6C63FF);
  static const Color gradientEnd = Color(0xFF00D2FF);
}

// ==================== SCREEN PRINCIPAL ====================
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with TickerProviderStateMixin {
  // ==================== ÉTATS ====================
  bool _isScanning = false;
  bool _isLoading = false;
  bool _isFlashOn = false;
  String? _scanResult;
  ScannedMedication? _scannedMedication;
  MedicationDetail? _medicationDetail;
  List<ScannedMedication> _scanHistory = [];
  String _searchQuery = '';
  List<ScannedMedication> _filteredHistory = [];

  // ==================== CONTROLEURS ====================
  final MobileScannerController _scannerController = MobileScannerController(
    torchEnabled: false,
    facing: CameraFacing.back,
  );

  // ==================== ANIMATIONS ====================
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadHistory();
    _checkPermissions();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _scanLineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _animationController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  // ==================== PERMISSIONS ====================
  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      await Permission.camera.request();
    }
  }

  // ==================== CHARGEMENT HISTORIQUE ====================
  Future<void> _loadHistory() async {
    try {
      final service = ScanService();
      final history = await service.getScanHistory();
      
      if (mounted) {
        setState(() {
          _scanHistory = history;
          _filteredHistory = _scanHistory;
        });
      }
    } catch (e) {
      print('❌ Erreur historique: $e');
      if (mounted) {
        _showSnackBar('Erreur de chargement de l\'historique', ElegantColors.accent);
      }
    }
  }

  // ==================== AFFICHER LE MODAL HISTORIQUE ====================
  void _showHistoryModal() async {
    await _loadHistory();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '📋 Historique des scans',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ElegantColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: ElegantColors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: _scanHistory.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Iconsax.search_normal, size: 60, color: ElegantColors.textLight.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun scan effectué',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: ElegantColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Scannez un produit pour le voir ici',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: ElegantColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _scanHistory.length,
                          itemBuilder: (context, index) {
                            final item = _scanHistory[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: ElegantColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    item.source == 'OpenProductsFacts' ? Icons.shopping_cart : Icons.medication,
                                    color: ElegantColors.primary,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  item.nom,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  item.category ?? 'Produit',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: ElegantColors.textSecondary,
                                  ),
                                ),
                                trailing: Text(
                                  item.barcode,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: ElegantColors.textLight,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==================== DÉMARRER SCAN ====================
  Future<void> _startScan() async {
    try {
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        _showSnackBar('Permission caméra refusée', ElegantColors.accent);
        return;
      }

      setState(() {
        _isScanning = true;
        _scanResult = null;
        _scannedMedication = null;
        _medicationDetail = null;
      });

      await _scannerController.start();
    } on PlatformException catch (e) {
      setState(() => _isScanning = false);
      _showSnackBar('Erreur scanner: ${e.message}', ElegantColors.accent);
    } catch (e) {
      setState(() => _isScanning = false);
      _showSnackBar('Erreur: $e', ElegantColors.accent);
    }
  }

  // ==================== TRAITEMENT DU SCAN ====================
  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning || _isLoading) return;

    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      final code = barcode.displayValue ?? barcode.rawValue;
      
      if (code != null && code.isNotEmpty) {
        setState(() {
          _scanResult = code;
          _isScanning = false;
        });
        _scannerController.stop();
        _processScan(code);
      }
    }
  }

  // ==================== TRAITEMENT SCAN ====================
  Future<void> _processScan(String barcode) async {
    setState(() => _isLoading = true);

    try {
      final apiService = MedicationApiService();
      final medicationDetail = await apiService.getMedicationByBarcode(barcode);

      if (medicationDetail != null) {
        setState(() {
          _medicationDetail = medicationDetail;
          _isLoading = false;
        });
        _showMedicationDetailDialog(medicationDetail);
        return;
      }

      final service = ScanService();
      final result = await service.scanBarcode(barcode);

      setState(() {
        _scannedMedication = result;
        _isLoading = false;
      });

      if (result == null) {
        _showSnackBar('Produit non trouvé', ElegantColors.accent);
        return;
      }

      if (result.alreadyExists) {
        _showSnackBar('Ce produit est déjà dans votre liste', ElegantColors.primary);
      } else {
        _showResultDialog(result);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Produit non trouvé: $e', ElegantColors.accent);
    }
  }

  // ==================== DIALOGUE DÉTAIL MÉDICAMENT ====================
  void _showMedicationDetailDialog(MedicationDetail detail) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, ElegantColors.background],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: ElegantColors.cardShadow,
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogHeader(detail),
              const SizedBox(height: 12),
              Flexible(
                flex: 1,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGeneralInfo(detail),
                      const SizedBox(height: 16),
                      if (detail.ingredients.isNotEmpty)
                        _buildInfoSection(
                          title: 'Ingrédients actifs',
                          items: detail.ingredients,
                          icon: Iconsax.bezier,
                          color: ElegantColors.primary,
                        ),
                      if (detail.indications.isNotEmpty)
                        _buildInfoSection(
                          title: 'Indications thérapeutiques',
                          items: detail.indications,
                          icon: Iconsax.health,
                          color: ElegantColors.success,
                        ),
                      if (detail.contreIndications.isNotEmpty)
                        _buildInfoSection(
                          title: 'Contre-indications',
                          items: detail.contreIndications,
                          icon: Iconsax.danger,
                          color: ElegantColors.accent,
                        ),
                      if (detail.effetsSecondaires.isNotEmpty)
                        _buildInfoSection(
                          title: 'Effets secondaires',
                          items: detail.effetsSecondaires,
                          icon: Iconsax.warning_2,
                          color: ElegantColors.warning,
                        ),
                      if (detail.precautions.isNotEmpty)
                        _buildInfoSection(
                          title: 'Précautions d\'emploi',
                          items: detail.precautions,
                          icon: Iconsax.shield,
                          color: ElegantColors.secondary,
                        ),
                      if (detail.posologie != null)
                        _buildInfoChip('Posologie', detail.posologie!, Iconsax.clock, ElegantColors.primary),
                      if (detail.conservation != null)
                        _buildInfoChip('Conservation', detail.conservation!, Iconsax.box_1, ElegantColors.secondary),
                      if (detail.prix != null)
                        _buildInfoChip('Prix indicatif', detail.prix!, Iconsax.money, ElegantColors.success),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [ElegantColors.primary, ElegantColors.primaryLight],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: ElegantColors.primary.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showSaveForm(detail);
                          },
                          icon: const Icon(Iconsax.add_circle, color: Colors.white),
                          label: const Text(
                            'Ajouter ce médicament',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== EN-TÊTE DIALOGUE ====================
  Widget _buildDialogHeader(MedicationDetail detail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ElegantColors.primary.withOpacity(0.05), ElegantColors.secondary.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ElegantColors.primary, ElegantColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ElegantColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: detail.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      detail.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Iconsax.health,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  )
                : const Icon(
                    Iconsax.health,
                    size: 32,
                    color: Colors.white,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.nom,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ElegantColors.textPrimary,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (detail.forme != null)
                  Text(
                    detail.forme!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: ElegantColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (detail.dosage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: ElegantColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${detail.dosage}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ElegantColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 18,
                color: ElegantColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SECTION D'INFORMATIONS ====================
  Widget _buildInfoSection({
    required String title,
    required List<String> items,
    required IconData icon,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (color ?? ElegantColors.primary).withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (color ?? ElegantColors.primary).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color ?? ElegantColors.primary, size: 18),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color ?? ElegantColors.primary,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: (color ?? ElegantColors.primary).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  items.length.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color ?? ElegantColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.take(3).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: (color ?? ElegantColors.primary).withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: ElegantColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
          if (items.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${items.length - 3} autres...',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: ElegantColors.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== CHIP D'INFORMATION ====================
  Widget _buildInfoChip(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ElegantColors.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: ElegantColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== INFORMATIONS GÉNÉRALES ====================
  Widget _buildGeneralInfo(MedicationDetail detail) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          if (detail.code != null)
            _buildMiniChip('Code', detail.code!, Iconsax.barcode),
          if (detail.fabricant != null)
            _buildMiniChip('Fabricant', detail.fabricant!, Iconsax.building),
          if (detail.presentation != null)
            _buildMiniChip('Présentation', detail.presentation!, Iconsax.box),
        ],
      ),
    );
  }

  Widget _buildMiniChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ElegantColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ElegantColors.primary.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: ElegantColors.textLight),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: ElegantColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==================== DIALOGUE RÉSULTAT AVEC INGRÉDIENTS ====================
  void _showResultDialog(ScannedMedication medication) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, ElegantColors.background],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: ElegantColors.cardShadow,
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [ElegantColors.success, ElegantColors.success.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ElegantColors.success.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Produit scanné !',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: ElegantColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Voici les informations du produit',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: ElegantColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                if (medication.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      medication.imageUrl!,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: ElegantColors.textLight,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [ElegantColors.primary.withOpacity(0.03), ElegantColors.secondary.withOpacity(0.03)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ElegantColors.primary.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.nom,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ElegantColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (medication.manufacturer != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Iconsax.building, size: 14, color: ElegantColors.textLight),
                              const SizedBox(width: 6),
                              Text(
                                medication.manufacturer!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: ElegantColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      if (medication.dosage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(Iconsax.bucket, size: 14, color: ElegantColors.textLight),
                              const SizedBox(width: 6),
                              Text(
                                'Dosage: ${medication.dosage}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: ElegantColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      if (medication.ingredients.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Iconsax.bezier, size: 14, color: ElegantColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Ingrédients actifs',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ElegantColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: medication.ingredients.map((ing) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [ElegantColors.primary.withOpacity(0.1), ElegantColors.primaryLight.withOpacity(0.05)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: ElegantColors.primary.withOpacity(0.1),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                ing,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: ElegantColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Annuler',
                          style: GoogleFonts.inter(
                            color: ElegantColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [ElegantColors.primary, ElegantColors.primaryLight],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: ElegantColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showSaveForm(medication);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Ajouter',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
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
      ),
    );
  }

  // ==================== FORMULAIRE D'AJOUT (RÉEL) ====================
  Future<void> _showSaveForm(dynamic medication) async {
    // 1. Popup de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: ElegantColors.primary),
      ),
    );

    bool success = false;
    String errorMsg = '';

    try {
      final service = ScanService();
      ScannedMedication? toSave;

      if (medication is MedicationDetail) {
        toSave = ScannedMedication(
  barcode: medication.code ?? '',
  nom: medication.nom,
  manufacturer: medication.fabricant,
  category: null,
  dosage: medication.dosage,
  imageUrl: medication.imageUrl,
  source: 'Scan',
  ingredients: medication.ingredients,
  indications: medication.indications,
  contreIndications: medication.contreIndications,
  effetsSecondaires: medication.effetsSecondaires,
  scannedAt: DateTime.now(),
);
      } else if (medication is ScannedMedication) {
        toSave = medication;
      }

      if (toSave == null || toSave.barcode.isEmpty) {
        errorMsg = 'Code-barres manquant';
      } else {
        success = await service.saveScannedProduct(toSave);
        if (!success) errorMsg = 'Erreur lors de l\'enregistrement (voir logs Laravel)';
      }
    } catch (e) {
      errorMsg = 'Exception: $e';
    }

    if (mounted) Navigator.of(context).pop();

    if (!mounted) return;

    // 2. Popup de résultat (succès ou échec)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.35,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, ElegantColors.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: success
                        ? [ElegantColors.success, ElegantColors.success.withOpacity(0.7)]
                        : [ElegantColors.accent, ElegantColors.accent.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  success ? Iconsax.tick_circle : Iconsax.close_circle,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                success ? 'Produit ajouté avec succès !' : 'Échec de l\'ajout',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ElegantColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              if (success)
                Text(
                  medication is MedicationDetail ? medication.nom : (medication as ScannedMedication).nom,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: ElegantColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    errorMsg,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: ElegantColors.accent,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 24),
              Container(
                width: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ElegantColors.primary, ElegantColors.primaryLight],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (success) _loadHistory();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    success ? 'Terminer' : 'Fermer',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  // ==================== SNACKBAR ====================
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == ElegantColors.success ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ElegantColors.background,
      body: SafeArea(
        child: _buildMainContent(),
      ),
    );
  }

  // ==================== CONTENU PRINCIPAL ====================
  Widget _buildMainContent() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [ElegantColors.primary.withOpacity(0.05), Colors.transparent],
                center: Alignment.center,
                radius: 0.8,
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [ElegantColors.secondary.withOpacity(0.05), Colors.transparent],
                center: Alignment.center,
                radius: 0.8,
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildScanArea(),
                      const SizedBox(height: 16),
                      _buildButtons(),
                      if (_scanHistory.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildHistory(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== APP BAR ====================
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: ElegantColors.cardShadow,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ElegantColors.primary, ElegantColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: ElegantColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ElegantColors.primary, ElegantColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.scanner,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Scanner',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ElegantColors.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  color: _isFlashOn ? ElegantColors.warning : ElegantColors.textLight,
                  size: 22,
                ),
                onPressed: _isScanning ? _toggleFlash : null,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.cameraswitch_rounded,
                  color: ElegantColors.textSecondary,
                  size: 22,
                ),
                onPressed: _isScanning ? _switchCamera : null,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== ZONE DE SCAN ====================
  Widget _buildScanArea() {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, ElegantColors.background],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ElegantColors.cardShadow,
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: _isScanning
                ? MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                  )
                : _buildPlaceholder(),
          ),
          if (_isScanning) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _scanLineController,
                builder: (context, child) {
                  return Container(
                    height: 2,
                    margin: EdgeInsets.only(
                      top: _scanLineController.value * 340,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          ElegantColors.primary.withOpacity(0.8),
                          ElegantColors.secondary.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 30,
              left: 30,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
                    left: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: 30,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
                    right: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 30,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
                    left: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              right: 30,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
                    right: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Placez le code-barres dans le cadre',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (_isLoading)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Recherche des informations...',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Veuillez patienter',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== PLACEHOLDER ====================
  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ElegantColors.primary.withOpacity(0.05), ElegantColors.secondary.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: ElegantColors.primary.withOpacity(0.1),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              size: 64,
              color: ElegantColors.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scannez le code-barres',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ElegantColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ou saisissez-le manuellement',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: ElegantColors.textSecondary,
            ),
          ),
          if (_scanResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ElegantColors.success.withOpacity(0.1), ElegantColors.success.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ElegantColors.success.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: ElegantColors.success, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Code: $_scanResult',
                    style: GoogleFonts.inter(
                      color: ElegantColors.success,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== BOUTONS ====================
  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isScanning
                    ? [ElegantColors.accent, ElegantColors.accent.withOpacity(0.8)]
                    : [ElegantColors.primary, ElegantColors.primaryLight],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (_isScanning ? ElegantColors.accent : ElegantColors.primary).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _startScan,
              icon: Icon(
                _isScanning ? Icons.stop : Icons.qr_code_scanner_rounded,
                color: Colors.white,
              ),
              label: Text(
                _isScanning ? 'Arrêter' : 'Scanner',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: ElegantColors.primary.withOpacity(0.2),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: OutlinedButton.icon(
              onPressed: _showManualBarcodeDialog,
              icon: Icon(Iconsax.keyboard, color: ElegantColors.primary, size: 18),
              label: Text(
                'Saisir',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ElegantColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: ElegantColors.textLight.withOpacity(0.2),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: OutlinedButton.icon(
              onPressed: _showHistoryModal,
              icon: Icon(Icons.history, color: ElegantColors.textSecondary, size: 18),
              label: Text(
                'Liste',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ElegantColors.textSecondary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== HISTORIQUE ====================
  Widget _buildHistory() {
    final displayHistory = _searchQuery.isEmpty
        ? _scanHistory
        : _scanHistory.where((item) =>
            item.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (item.category?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
          ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ElegantColors.cardShadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un produit...',
              hintStyle: GoogleFonts.inter(
                color: ElegantColors.textLight,
                fontSize: 14,
              ),
              prefixIcon: Icon(Icons.search, color: ElegantColors.textLight, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: ElegantColors.textPrimary,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  '📋 Historique',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ElegantColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [ElegantColors.primary, ElegantColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    displayHistory.length.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _loadHistory,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ElegantColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ElegantColors.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 14, color: ElegantColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Rafraîchir',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: ElegantColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (displayHistory.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Iconsax.search_normal,
                    size: 48,
                    color: ElegantColors.textLight.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isEmpty
                        ? 'Aucun scan effectué'
                        : 'Aucun résultat pour "$_searchQuery"',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: ElegantColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => _searchQuery = ''),
                      child: Text(
                        'Effacer la recherche',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: ElegantColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
        else
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ElegantColors.cardShadow,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: displayHistory.length,
              itemBuilder: (context, index) {
                final item = displayHistory[index];
                return Animate(
                  effects: [
                    FadeEffect(duration: 300.ms, delay: (index * 50).ms),
                    SlideEffect(
                      duration: 300.ms,
                      delay: (index * 50).ms,
                      begin: const Offset(0.2, 0),
                      end: Offset.zero,
                    ),
                  ],
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: ElegantColors.background.withOpacity(0.5),
                      border: Border.all(
                        color: Colors.grey.shade100,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [ElegantColors.primary.withOpacity(0.1), ElegantColors.primaryLight.withOpacity(0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.source == 'OpenProductsFacts'
                              ? Icons.shopping_cart
                              : Icons.medication,
                          color: ElegantColors.primary,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        item.nom,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: ElegantColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.category ?? 'Produit',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ElegantColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.ingredients.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: item.ingredients.take(2).map((ing) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: ElegantColors.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    ing,
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: ElegantColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                            ),
                            if (item.ingredients.length > 2)
                              Text(
                                '+ ${item.ingredients.length - 2} autres',
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: ElegantColors.textLight,
                                ),
                              ),
                          ],
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.barcode,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: ElegantColors.textLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      dense: true,
                      minVerticalPadding: 0,
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ==================== SAISIE MANUELLE DU CODE-BARRES ====================
  void _showManualBarcodeDialog() {
    final TextEditingController barcodeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, ElegantColors.background],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: ElegantColors.cardShadow,
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [ElegantColors.primary, ElegantColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Iconsax.keyboard,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Saisie manuelle',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ElegantColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: ElegantColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Entrez le code-barres du produit à rechercher',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: ElegantColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: ElegantColors.cardShadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Code-barres',
                    labelStyle: GoogleFonts.inter(
                      color: ElegantColors.textSecondary,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Iconsax.barcode,
                      color: ElegantColors.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Ex: 76420-808',
                    hintStyle: GoogleFonts.inter(
                      color: ElegantColors.textLight,
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: ElegantColors.textPrimary,
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      Navigator.pop(context);
                      _processManualBarcode(value.trim());
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ElegantColors.primary.withOpacity(0.05), ElegantColors.secondary.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: ElegantColors.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: ElegantColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Codes de test',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: ElegantColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildTestChip('76420-808', 'Buspirone'),
                        _buildTestChip('5449000000996', 'Coca-Cola'),
                        _buildTestChip('3017620422003', 'Nutella'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Annuler',
                        style: GoogleFonts.inter(
                          color: ElegantColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [ElegantColors.primary, ElegantColors.primaryLight],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: ElegantColors.primary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final barcode = barcodeController.text.trim();
                          if (barcode.isEmpty) {
                            _showSnackBar('Veuillez entrer un code-barres', ElegantColors.accent);
                            return;
                          }
                          Navigator.pop(context);
                          _processManualBarcode(barcode);
                        },
                        icon: const Icon(Iconsax.search_normal, color: Colors.white, size: 18),
                        label: Text(
                          'Rechercher',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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

  Widget _buildTestChip(String barcode, String label) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _processManualBarcode(barcode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ElegantColors.primary.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: ElegantColors.cardShadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: ElegantColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ==================== TRAITEMENT MANUEL ====================
  Future<void> _processManualBarcode(String barcode) async {
    setState(() => _isLoading = true);

    try {
      final cleanBarcode = barcode.trim().replaceAll(' ', '');
      
      if (cleanBarcode.isEmpty) {
        setState(() => _isLoading = false);
        _showSnackBar('Code-barres vide', ElegantColors.accent);
        return;
      }

      final service = ScanService();
      final result = await service.scanBarcode(cleanBarcode);

      setState(() => _isLoading = false);

      if (result != null && !result.nom.contains('non trouvé')) {
        setState(() {
          _scannedMedication = result;
          _scanResult = cleanBarcode;
        });
        
        if (result.alreadyExists) {
          _showSnackBar('Ce produit est déjà dans votre liste', ElegantColors.primary);
        } else {
          _showResultDialog(result);
        }
        return;
      }

      _showSnackBar('Aucun produit trouvé pour le code: $cleanBarcode', ElegantColors.accent);
      
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur: $e', ElegantColors.accent);
    }
  }

  // ==================== FONCTIONS UTILITAIRES ====================
  void _toggleFlash() {
    _scannerController.toggleTorch();
    setState(() => _isFlashOn = !_isFlashOn);
  }

  void _switchCamera() {
    _scannerController.switchCamera();
  }
}