// lib/providers/rendezvous_provider.dart

import 'package:flutter/material.dart';
import '../models/rendez_vous.dart';
import '../services/rendezvous_service.dart';

class RendezVousProvider extends ChangeNotifier {
  List<RendezVous> _rendezVous = [];
  bool _isLoading = false;
  String? _error;

  List<RendezVous> get rendezVous => _rendezVous;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final RendezVousService _service = RendezVousService();

  // Charger tous les rendez-vous
  Future<void> loadRendezVous({String? statut}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rendezVous = await _service.getRendezVous(statut: statut);
    } catch (e) {
      _error = 'Erreur: $e';
      print('❌ Erreur loadRendezVous: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger les rendez-vous du jour
  Future<void> loadTodayRendezVous() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rendezVous = await _service.getTodayRendezVous();
    } catch (e) {
      _error = 'Erreur: $e';
      print('❌ Erreur loadTodayRendezVous: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ajouter un rendez-vous
  Future<bool> addRendezVous(RendezVous rendezvous) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _service.createRendezVous(rendezvous);
      if (result != null) {
        _rendezVous.insert(0, result);
        _rendezVous.sort((a, b) => a.dateHeure.compareTo(b.dateHeure));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Erreur: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Modifier un rendez-vous
  Future<bool> updateRendezVous(int id, RendezVous rendezvous) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _service.updateRendezVous(id, rendezvous);
      if (result != null) {
        final index = _rendezVous.indexWhere((r) => r.id == id);
        if (index != -1) {
          _rendezVous[index] = result;
          _rendezVous.sort((a, b) => a.dateHeure.compareTo(b.dateHeure));
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Erreur: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Supprimer un rendez-vous
  Future<bool> deleteRendezVous(int id) async {
    try {
      final success = await _service.deleteRendezVous(id);
      if (success) {
        _rendezVous.removeWhere((r) => r.id == id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = 'Erreur: $e';
      return false;
    }
  }

  // Récupérer les rendez-vous à venir
  List<RendezVous> get aVenir {
    return _rendezVous.where((r) => r.isAVenir).toList();
  }

  // Récupérer les rendez-vous d'aujourd'hui
  List<RendezVous> get aujourdhui {
    return _rendezVous.where((r) => r.isToday).toList();
  }

  // Compter les rendez-vous d'aujourd'hui
  int get countAujourdhui => aujourdhui.length;
}