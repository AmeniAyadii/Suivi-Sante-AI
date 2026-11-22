// lib/models/scanned_product.dart

class ScannedProduct {
  final String? barcode;
  final String nom;
  final String? manufacturer;
  final String? category;
  final String? subCategory;
  final String? dosage;
  final String? imageUrl;
  final String source;
  final String productType;
  final String productTypeLabel;
  final List<String> ingredients;
  final List<String> indications;
  final List<String> contreIndications;
  final List<String> effetsSecondaires;
  final String? posologie;
  final String? conservation;
  final bool alreadyExists;

  ScannedProduct({
    this.barcode,
    required this.nom,
    this.manufacturer,
    this.category,
    this.subCategory,
    this.dosage,
    this.imageUrl,
    this.source = 'Scan',
    this.productType = 'unknown',
    this.productTypeLabel = 'Non identifié',
    this.ingredients = const [],
    this.indications = const [],
    this.contreIndications = const [],
    this.effetsSecondaires = const [],
    this.posologie,
    this.conservation,
    this.alreadyExists = false,
  });

  factory ScannedProduct.fromJson(Map<String, dynamic> json) {
    return ScannedProduct(
      barcode: json['barcode'],
      nom: json['nom'] ?? 'Produit inconnu',
      manufacturer: json['manufacturer'],
      category: json['category'],
      subCategory: json['sub_category'],
      dosage: json['dosage'],
      imageUrl: json['image_url'],
      source: json['source'] ?? 'Scan',
      productType: json['product_type'] ?? 'unknown',
      productTypeLabel: json['product_type_label'] ?? 'Non identifié',
      ingredients: _parseList(json['ingredients']),
      indications: _parseList(json['indications']),
      contreIndications: _parseList(json['contre_indications']),
      effetsSecondaires: _parseList(json['effets_secondaires']),
      posologie: json['posologie'],
      conservation: json['conservation'],
      alreadyExists: json['already_exists'] ?? false,
    );
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      return value.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'nom': nom,
      'manufacturer': manufacturer,
      'category': category,
      'sub_category': subCategory,
      'dosage': dosage,
      'image_url': imageUrl,
      'source': source,
      'product_type': productType,
      'product_type_label': productTypeLabel,
      'ingredients': ingredients,
      'indications': indications,
      'contre_indications': contreIndications,
      'effets_secondaires': effetsSecondaires,
      'posologie': posologie,
      'conservation': conservation,
    };
  }
}