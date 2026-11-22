// lib/models/scanned_medication.dart

class ScannedMedication {
  final String barcode;
  final String nom;
  final String? manufacturer;
  final String? category;
  final String? dosage;
  final String? imageUrl;
  final String? source;
  final bool alreadyExists;
  final DateTime? scannedAt;
  final List<String> ingredients; // ✅ Ajout de la propriété
  final List<String> indications; // ✅ Ajout de la propriété
  final List<String> contreIndications; // ✅ Ajout de la propriété
  final List<String> effetsSecondaires; // ✅ Ajout de la propriété
  final String? statut;

  ScannedMedication({
    required this.barcode,
    required this.nom,
    this.manufacturer,
    this.category,
    this.dosage,
    this.imageUrl,
    this.source,
    this.alreadyExists = false,
    this.scannedAt,
    this.ingredients = const [], // ✅ Valeur par défaut
    this.indications = const [], // ✅ Valeur par défaut
    this.contreIndications = const [], // ✅ Valeur par défaut
    this.effetsSecondaires = const [], // ✅ Valeur par défaut
    this.statut,
  });

  factory ScannedMedication.fromJson(Map<String, dynamic> json) {
    // Vérifier si le médicament est "non trouvé"
    final nom = json['nom'] ?? '';
    final isNotFound = nom.contains('non trouvé') || nom.contains('not found');
    
    return ScannedMedication(
      barcode: json['barcode'] ?? json['code'] ?? '',
      nom: nom.isNotEmpty ? nom : 'Médicament inconnu',
      manufacturer: json['manufacturer'] ?? json['fabricant'],
      category: json['category'] ?? json['categorie'],
      dosage: json['dosage'],
      imageUrl: json['image_url'] ?? json['imageUrl'],
      source: json['source'],
      alreadyExists: isNotFound ? false : (json['already_exists'] ?? false),
      scannedAt: json['scanned_at'] != null 
          ? DateTime.tryParse(json['scanned_at']) 
          : null,
      // ✅ Récupérer les ingrédients
      ingredients: _parseList(json['ingredients']),
      // ✅ Récupérer les indications
      indications: _parseList(json['indications']),
      // ✅ Récupérer les contre-indications
      contreIndications: _parseList(json['contre_indications']),
      // ✅ Récupérer les effets secondaires
      effetsSecondaires: _parseList(json['effets_secondaires']),
      statut: json['statut'],
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

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'nom': nom,
      'manufacturer': manufacturer,
      'category': category,
      'dosage': dosage,
      'image_url': imageUrl,
      'source': source,
      'already_exists': alreadyExists,
      'scanned_at': scannedAt?.toIso8601String(),
      'ingredients': ingredients,
      'indications': indications,
      'contre_indications': contreIndications,
      'effets_secondaires': effetsSecondaires,
      'statut': statut,
    };
  }

  // ✅ Propriété calculée pour vérifier si le produit a été trouvé
  bool get isFound => !nom.contains('non trouvé') && !nom.contains('not found');

  // ✅ Date de scan
  DateTime get scannedAtValue => scannedAt ?? DateTime.now();

  ScannedMedication copyWith({
    String? barcode,
    String? nom,
    String? manufacturer,
    String? category,
    String? dosage,
    String? imageUrl,
    String? source,
    bool? alreadyExists,
    DateTime? scannedAt,
    List<String>? ingredients,
    List<String>? indications,
    List<String>? contreIndications,
    List<String>? effetsSecondaires,
    String? statut,
  }) {
    return ScannedMedication(
      barcode: barcode ?? this.barcode,
      nom: nom ?? this.nom,
      manufacturer: manufacturer ?? this.manufacturer,
      category: category ?? this.category,
      dosage: dosage ?? this.dosage,
      imageUrl: imageUrl ?? this.imageUrl,
      source: source ?? this.source,
      alreadyExists: alreadyExists ?? this.alreadyExists,
      scannedAt: scannedAt ?? this.scannedAt,
      ingredients: ingredients ?? this.ingredients,
      indications: indications ?? this.indications,
      contreIndications: contreIndications ?? this.contreIndications,
      effetsSecondaires: effetsSecondaires ?? this.effetsSecondaires,
      statut: statut ?? this.statut,
    );
  }
}