import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scanned_medication.dart';

class ScanService {
  // ==================== CONFIGURATION ====================

  // Backend Laravel : port 8001
  // FastAPI Triage ML utilise séparément le port 8002.
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.5:8001/api',
  );

  static const int TIMEOUT_SECONDS = 60;

  // ==================== CONSTRUCTION DES URL ====================

  Uri _buildUri(String endpoint) {
    String base = baseUrl.replaceAll(RegExp(r'/+$'), '');

    // Garantir un seul préfixe /api.
    if (!base.endsWith('/api')) {
      base = '$base/api';
    }

    final path = endpoint.replaceFirst(RegExp(r'^/+'), '');

    return Uri.parse('$base/$path');
  }

  // ==================== GESTION DU TOKEN ====================

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('📤 Token ScanService: ${token != null ? 'Présent' : 'Absent'}');

      return token;
    } catch (e) {
      print('❌ Erreur récupération token: $e');
      return null;
    }
  }

  // ==================== MÉTHODE GÉNÉRIQUE POUR LES REQUÊTES ====================

  Future<Map<String, dynamic>> _postRequest(
    String endpoint,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      final token = await _getToken();
      final uri = _buildUri(endpoint);

      print('📤 POST Request: $uri');
      print('📤 Body: $body');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: json.encode(body),
          )
          .timeout(timeout);

      print('📥 Status Code: ${response.statusCode}');

      print(
        '📥 Body: ${response.body.substring(
          0,
          response.body.length > 200 ? 200 : response.body.length,
        )}...',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return data;
        }

        throw Exception(
          data['error'] ?? data['message'] ?? 'Erreur inconnue',
        );
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (response.statusCode == 422) {
        final data = json.decode(response.body);
        final errors = data['errors'] ?? {};

        String firstError = 'Données invalides';

        if (errors is Map && errors.isNotEmpty) {
          final firstValue = errors.values.first;

          if (firstValue is List && firstValue.isNotEmpty) {
            firstError = firstValue.first.toString();
          } else {
            firstError = firstValue.toString();
          }
        }

        throw Exception(firstError);
      } else {
        throw Exception(
          'Erreur ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Erreur _postRequest: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getRequest(
    String endpoint, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      final token = await _getToken();
      final uri = _buildUri(endpoint);

      print('📤 GET Request: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception(
          'Erreur ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Erreur _getRequest: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _deleteRequest(
    String endpoint, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      final token = await _getToken();
      final uri = _buildUri(endpoint);

      print('📤 DELETE Request: $uri');

      final response = await http
          .delete(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return {};
        }

        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 204) {
        return {};
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception(
          'Erreur ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Erreur _deleteRequest: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _putRequest(
    String endpoint,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      final token = await _getToken();
      final uri = _buildUri(endpoint);

      print('📤 PUT Request: $uri');

      final response = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: json.encode(body),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception(
          'Erreur ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Erreur _putRequest: $e');
      rethrow;
    }
  }

  // ==================== MÉTHODES SPÉCIFIQUES ====================

  /// Scanner un code-barres
  Future<ScannedMedication> scanBarcode(String barcode) async {
    try {
      print('📤 Scan barcode: $barcode');

      final response = await _postRequest(
        'scan',
        {
          'barcode': barcode,
        },
        timeout: const Duration(seconds: 60),
      );

      if (response['data'] != null) {
        final medication = ScannedMedication.fromJson(response['data']);

        print('✅ Médicament trouvé: ${medication.nom}');
        print('📊 Ingrédients: ${medication.ingredients}');

        return medication;
      }

      throw Exception('Aucune donnée retournée');
    } catch (e) {
      print('❌ Erreur scanBarcode: $e');
      rethrow;
    }
  }

  /// Récupérer l'historique des scans
  Future<List<ScannedMedication>> getScanHistory() async {
    try {
      print('📤 Get scan history');

      final response = await _getRequest(
        'scan/history',
        timeout: const Duration(seconds: 60),
      );

      if (response['data'] != null && response['data'] is List) {
        final history = (response['data'] as List)
            .map((item) => ScannedMedication.fromJson(item))
            .toList();

        print('✅ Historique: ${history.length} éléments');

        return history;
      }

      return [];
    } catch (e) {
      print('❌ Erreur getScanHistory: $e');
      return [];
    }
  }

  /// Scanner un code-barres avec validation
  Future<ScannedMedication> scanBarcodeWithValidation(
    String barcode,
  ) async {
    try {
      if (barcode.trim().isEmpty) {
        throw Exception('Le code-barres est vide');
      }

      if (barcode.trim().length < 6) {
        throw Exception('Code-barres invalide (trop court)');
      }

      if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(barcode.trim())) {
        throw Exception('Code-barres invalide (caractères non autorisés)');
      }

      return await scanBarcode(barcode);
    } catch (e) {
      print('❌ Erreur scanBarcodeWithValidation: $e');
      rethrow;
    }
  }

  /// Scanner un code-barres avec gestion d'erreur silencieuse
  Future<ScannedMedication?> scanBarcodeSafe(String barcode) async {
    try {
      return await scanBarcode(barcode);
    } catch (e) {
      print('⚠️ Scan safe error: $e');
      return null;
    }
  }

  /// Scanner plusieurs codes-barres
  Future<List<ScannedMedication>> scanMultipleBarcodes(
    List<String> barcodes,
  ) async {
    try {
      final results = <ScannedMedication>[];

      for (var barcode in barcodes) {
        try {
          final result = await scanBarcode(barcode);
          results.add(result);
        } catch (e) {
          print('⚠️ Erreur scan pour $barcode: $e');
          continue;
        }
      }

      return results;
    } catch (e) {
      print('❌ Erreur scanMultipleBarcodes: $e');
      return [];
    }
  }

  /// Sauvegarder un médicament scanné
  Future<ScannedMedication> saveScannedMedication(
    Map<String, dynamic> data,
  ) async {
    try {
      print('📤 Save medication: $data');

      // Validation des données
      if (data['nom'] == null ||
          data['nom'].toString().trim().isEmpty) {
        throw Exception('Le nom du médicament est requis');
      }

      if (data['barcode'] == null ||
          data['barcode'].toString().trim().isEmpty) {
        throw Exception('Le code-barres est requis');
      }

      // Nettoyer les données
      final cleanedData = {
        ...data,
        'nom': data['nom'].toString().trim(),
        'barcode': data['barcode'].toString().trim(),
        'dosage': data['dosage']?.toString().trim() ?? '',
        'frequence': data['frequence']?.toString().trim() ?? '',
        'notes': data['notes']?.toString().trim() ?? '',
      };

      final response = await _postRequest(
        'scan/store',
        cleanedData,
        timeout: const Duration(seconds: 60),
      );

      if (response['data'] != null) {
        return ScannedMedication.fromJson(response['data']);
      }

      throw Exception('Erreur lors de la sauvegarde');
    } catch (e) {
      print('❌ Erreur saveScannedMedication: $e');
      rethrow;
    }
  }

  /// Sauvegarder avec gestion d'erreur
  Future<ScannedMedication?> saveScannedMedicationSafe(
    Map<String, dynamic> data,
  ) async {
    try {
      return await saveScannedMedication(data);
    } catch (e) {
      print('⚠️ Save safe error: $e');
      return null;
    }
  }

  /// Récupérer l'historique avec pagination
  Future<Map<String, dynamic>> getScanHistoryPaginated({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      print('📤 Get scan history page $page');

      final response = await _getRequest(
        'scan/history?page=$page&per_page=$perPage',
        timeout: const Duration(seconds: 60),
      );

      return {
        'items': (response['data'] as List?)
                ?.map((item) => ScannedMedication.fromJson(item))
                .toList() ??
            [],
        'total': response['total'] ?? 0,
        'current_page': response['current_page'] ?? 1,
        'last_page': response['last_page'] ?? 1,
        'per_page': response['per_page'] ?? perPage,
      };
    } catch (e) {
      print('❌ Erreur getScanHistoryPaginated: $e');

      return {
        'items': [],
        'total': 0,
        'current_page': 1,
        'last_page': 1,
        'per_page': perPage,
      };
    }
  }

  /// Récupérer un médicament par ID
  Future<ScannedMedication?> getScannedMedicationById(int id) async {
    try {
      print('📤 Get medication $id');

      final response = await _getRequest(
        'scan/$id',
        timeout: const Duration(seconds: 60),
      );

      if (response['data'] != null) {
        return ScannedMedication.fromJson(response['data']);
      }

      return null;
    } catch (e) {
      print('❌ Erreur getScannedMedicationById: $e');
      return null;
    }
  }

  /// Supprimer un médicament de l'historique
  Future<bool> deleteScannedMedication(int id) async {
    try {
      print('📤 Delete medication $id');

      await _deleteRequest(
        'scan/$id',
        timeout: const Duration(seconds: 60),
      );

      return true;
    } catch (e) {
      print('❌ Erreur deleteScannedMedication: $e');
      return false;
    }
  }

  /// Supprimer plusieurs médicaments
  Future<int> deleteMultipleScannedMedications(List<int> ids) async {
    try {
      int deleted = 0;

      for (var id in ids) {
        final success = await deleteScannedMedication(id);

        if (success) deleted++;
      }

      return deleted;
    } catch (e) {
      print('❌ Erreur deleteMultipleScannedMedications: $e');
      return 0;
    }
  }

  /// Supprimer tout l'historique
  Future<bool> clearScanHistory() async {
    try {
      print('📤 Clear scan history');

      final token = await _getToken();

      if (token == null) {
        throw Exception('Non authentifié');
      }

      final uri = _buildUri('scan/clear');

      print('📤 DELETE URL: $uri');

      final response = await http
          .delete(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }

      if (response.statusCode == 204) {
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Erreur clearScanHistory: $e');
      return false;
    }
  }

  /// Mettre à jour un médicament scanné
  Future<ScannedMedication?> updateScannedMedication(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      print('📤 Update medication $id: $data');

      final response = await _putRequest(
        'scan/$id',
        data,
        timeout: const Duration(seconds: 60),
      );

      if (response['data'] != null) {
        return ScannedMedication.fromJson(response['data']);
      }

      return null;
    } catch (e) {
      print('❌ Erreur updateScannedMedication: $e');
      return null;
    }
  }

  /// Mettre à jour le statut d'un médicament
  Future<ScannedMedication?> updateMedicationStatus(
    int id,
    String status,
  ) async {
    try {
      return await updateScannedMedication(
        id,
        {'statut': status},
      );
    } catch (e) {
      print('❌ Erreur updateMedicationStatus: $e');
      return null;
    }
  }

  /// Vérifier si un médicament existe déjà
  Future<bool> medicationExists(String barcode) async {
    try {
      final history = await getScanHistory();
      return history.any((med) => med.barcode == barcode);
    } catch (e) {
      print('❌ Erreur medicationExists: $e');
      return false;
    }
  }

  /// Vérifier si un médicament existe par nom
  Future<bool> medicationExistsByName(String name) async {
    try {
      final history = await getScanHistory();

      return history.any(
        (med) => med.nom.toLowerCase() == name.toLowerCase().trim(),
      );
    } catch (e) {
      print('❌ Erreur medicationExistsByName: $e');
      return false;
    }
  }

  /// Rechercher des médicaments par nom
  Future<List<ScannedMedication>> searchMedications(String query) async {
    try {
      if (query.trim().isEmpty) {
        return await getScanHistory();
      }

      final history = await getScanHistory();

      return history
          .where(
            (med) => med.nom.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      print('❌ Erreur searchMedications: $e');
      return [];
    }
  }

  /// Rechercher des médicaments par catégorie
  Future<List<ScannedMedication>> searchByCategory(String category) async {
    try {
      final history = await getScanHistory();

      return history
          .where(
            (med) => med.category?.toLowerCase() == category.toLowerCase(),
          )
          .toList();
    } catch (e) {
      print('❌ Erreur searchByCategory: $e');
      return [];
    }
  }

  /// Obtenir toutes les catégories uniques
  Future<List<String>> getUniqueCategories() async {
    try {
      final history = await getScanHistory();
      final categories = <String>{};

      for (var med in history) {
        if (med.category != null && med.category!.isNotEmpty) {
          categories.add(med.category!);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      print('❌ Erreur getUniqueCategories: $e');
      return [];
    }
  }

  /// Compter le nombre total de médicaments scannés
  Future<int> getTotalScannedCount() async {
    try {
      final history = await getScanHistory();
      return history.length;
    } catch (e) {
      print('❌ Erreur getTotalScannedCount: $e');
      return 0;
    }
  }

  /// Compter par statut
  Future<Map<String, int>> getCountByStatus() async {
    try {
      final history = await getScanHistory();
      final statusCount = <String, int>{};

      for (var med in history) {
        final status = med.statut ?? 'Non défini';
        statusCount[status] = (statusCount[status] ?? 0) + 1;
      }

      return statusCount;
    } catch (e) {
      print('❌ Erreur getCountByStatus: $e');
      return {};
    }
  }

  /// Récupérer les statistiques des scans
  Future<Map<String, dynamic>> getScanStats() async {
    try {
      final history = await getScanHistory();

      // Compter par catégorie
      final categoryCount = <String, int>{};

      for (var med in history) {
        final category = med.category ?? 'Non catégorisé';
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }

      // Compter par source
      final sourceCount = <String, int>{};

      for (var med in history) {
        final source = med.source ?? 'Inconnue';
        sourceCount[source] = (sourceCount[source] ?? 0) + 1;
      }

      // Compter par statut
      final statusCount = <String, int>{};

      for (var med in history) {
        final status = med.statut ?? 'Non défini';
        statusCount[status] = (statusCount[status] ?? 0) + 1;
      }

      final sortedHistory = List<ScannedMedication>.from(history)
        ..sort((a, b) {
          return b.scannedAtValue.compareTo(a.scannedAtValue);
        });

      return {
        'total': history.length,
        'par_categorie': categoryCount,
        'par_source': sourceCount,
        'par_statut': statusCount,
        'dernier_scan': sortedHistory.isNotEmpty
            ? sortedHistory.first.scannedAtValue
            : null,
        'premier_scan': sortedHistory.isNotEmpty
            ? sortedHistory.last.scannedAtValue
            : null,
        'categories_uniques': categoryCount.keys.length,
        'sources_uniques': sourceCount.keys.length,
      };
    } catch (e) {
      print('❌ Erreur getScanStats: $e');

      return {
        'total': 0,
        'par_categorie': {},
        'par_source': {},
        'par_statut': {},
        'dernier_scan': null,
        'premier_scan': null,
        'categories_uniques': 0,
        'sources_uniques': 0,
      };
    }
  }

  /// Récupérer du cache local
  Future<List<ScannedMedication>> getFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('scan_cache');

      if (jsonString == null) return [];

      final List<dynamic> data = json.decode(jsonString);

      return data
          .map((item) => ScannedMedication.fromJson(item))
          .toList();
    } catch (e) {
      print('❌ Erreur getFromLocalCache: $e');
      return [];
    }
  }

  /// Vider le cache local
  Future<void> clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('scan_cache');

      print('✅ Cache local vidé');
    } catch (e) {
      print('❌ Erreur clearLocalCache: $e');
    }
  }

  // ==================== MÉTHODES DE TEST ====================

  /// Tester la connexion à l'API
  Future<bool> testConnection() async {
    try {
      final token = await _getToken();
      final uri = _buildUri('scan/test');

      print('📤 Test connection à: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Test connection status: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Test connection failed: $e');
      return false;
    }
  }

  /// 💾 Enregistre réellement un produit scanné en base via Laravel.
  /// Retourne true si succès, false sinon.
  Future<bool> saveScannedProduct(ScannedMedication medication) async {
    try {
      print('💾 saveScannedProduct: ${medication.nom} (${medication.barcode})');

      // Construire le body au format attendu par ScanController@store
      final body = {
  'barcode': medication.barcode,
  'nom': medication.nom,
  'manufacturer': medication.manufacturer,
  'category': medication.category,
  'dosage': medication.dosage,
  'image_url': medication.imageUrl,
  'ingredients': medication.ingredients,
  'indications': medication.indications ?? [],
  'contre_indications': medication.contreIndications ?? [],
  'effets_secondaires': medication.effetsSecondaires ?? [],
  'notes': null,
  'expiry_date': null,
  'source': medication.source ?? 'Scan',
};

      // Utilise le helper _postRequest pour bénéficier de la gestion d'erreurs
      final response = await _postRequest(
        'scan/store',
        body,
        timeout: const Duration(seconds: 15),
      );

      // _postRequest a déjà vérifié que data['success'] == true
      print('✅ Produit sauvegardé: ${response['message'] ?? 'OK'}');
      return true;
    } catch (e) {
      print('❌ Erreur saveScannedProduct: $e');
      return false;
    }
  }

  /// Tester un scan avec un code-barres fictif
  Future<void> testScan() async {
    try {
      print('🧪 Test scan avec code: 76420-808');

      final result = await scanBarcode('76420-808');

      print('✅ Test réussi: ${result.nom}');
      print('   Code: ${result.barcode}');
      print('   Catégorie: ${result.category ?? 'Non définie'}');
      print('   Source: ${result.source ?? 'Inconnue'}');
    } catch (e) {
      print('❌ Test échoué: $e');
    }
  }

  /// Tester l'ensemble des fonctionnalités
  Future<void> testAllFeatures() async {
    print('🧪 Début des tests...');

    // 1. Test de connexion
    print('1️⃣ Test de connexion...');

    final connected = await testConnection();

    print('   ${connected ? '✅' : '❌'} Connecté: $connected');

    if (!connected) {
      print('❌ Arrêt des tests - API non accessible');
      return;
    }

    // 2. Test de scan
    print('2️⃣ Test de scan...');
    await testScan();

    // 3. Test d'historique
    print('3️⃣ Test d\'historique...');

    final history = await getScanHistory();

    print('   ✅ ${history.length} médicaments dans l\'historique');

    // 4. Test de statistiques
    print('4️⃣ Test de statistiques...');

    final stats = await getScanStats();

    print('   ✅ Total: ${stats['total']}');
    print('   ✅ Catégories: ${stats['categories_uniques']}');
    print('   ✅ Sources: ${stats['sources_uniques']}');

    // 5. Test de recherche
    if (history.isNotEmpty) {
      print('5️⃣ Test de recherche...');

      final searchResult = await searchMedications(
        history.first.nom.substring(0, 3),
      );

      print('   ✅ ${searchResult.length} résultats trouvés');
    }

    print('🧪 Tests terminés');
  }
}