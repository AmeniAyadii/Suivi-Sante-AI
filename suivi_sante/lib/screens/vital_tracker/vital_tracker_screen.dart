// lib/screens/vital_tracker/vital_tracker_screen.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/constante_vitale.dart';
import '../../models/alerte_sante.dart';
import '../../providers/vital_provider.dart';
import 'widgets/vital_card.dart';
import 'widgets/add_measurement_dialog.dart';
import 'alert_banner.dart';

class VitalTrackerScreen extends StatefulWidget {
  const VitalTrackerScreen({Key? key}) : super(key: key);

  @override
  State<VitalTrackerScreen> createState() => _VitalTrackerScreenState();
}

class _VitalTrackerScreenState extends State<VitalTrackerScreen> {
  late DateTime _currentWeekStart;
  late DateTime _currentWeekEnd;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeDates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _initializeDates() {
    final now = DateTime.now();
    _currentWeekStart = DateTime(
      now.year,
      now.month,
      now.day - now.weekday + 1,
    );
    _currentWeekEnd = _currentWeekStart.add(const Duration(days: 6));
  }

  void _updateWeekRange() {
    _currentWeekEnd = _currentWeekStart.add(const Duration(days: 6));
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vitalProvider = Provider.of<VitalProvider>(context, listen: false);
      await vitalProvider.loadConstantes(
        dateDebut: _currentWeekStart.toIso8601String(),
        dateFin: _currentWeekEnd.toIso8601String(),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
        _showSnackBar('Erreur de chargement: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changeWeek(int offset) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: offset * 7));
      _updateWeekRange();
    });
    _loadData();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<VitalProvider>(
          builder: (context, vitalProvider, child) {
            return CustomScrollView(
              slivers: [
                // Header avec AppBar
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1A3A6B),
                    ),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    },
                    tooltip: 'Retour au Dashboard',
                  ),
                  title: const Text(
                    '📊 Suivi des Signes Vitaux',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A6B),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: _buildWeekNavigator(),
                  ),
                ),

                // Alertes
                if (vitalProvider.alertesNonLues.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: AlertBanner(
                        alertes: vitalProvider.alertesNonLues,
                        onAlerteTap: (alerte) {
                          _showAlerteDetails(alerte);
                        },
                        onMarquerLue: (alerte) {
                          _marquerAlerteLue(alerte);
                        },
                      ),
                    ),
                  ),

                // Contenu principal
                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF1A5BB5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Chargement des données...',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur de chargement',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Réessayer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A5BB5),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Carte Tension
                        _buildVitalCard(
                          type: TypeConstante.tensionSystolique,
                          provider: vitalProvider,
                        ),
                        const SizedBox(height: 16),

                        // Carte Fréquence Cardiaque
                        _buildVitalCard(
                          type: TypeConstante.frequenceCardiaque,
                          provider: vitalProvider,
                          isCircular: true,
                        ),
                        const SizedBox(height: 16),

                        // Carte Température
                        _buildVitalCard(
                          type: TypeConstante.temperature,
                          provider: vitalProvider,
                        ),
                        const SizedBox(height: 16),

                        // Carte Glycémie
                        _buildVitalCard(
                          type: TypeConstante.glycemie,
                          provider: vitalProvider,
                        ),
                        const SizedBox(height: 16),

                        // Boutons d'action
                        _buildActionButtons(),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMeasurementDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter une mesure'),
        backgroundColor: const Color(0xFF1A5BB5),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  Widget _buildVitalCard({
    required TypeConstante type,
    required VitalProvider provider,
    bool isCircular = false,
  }) {
    return VitalCard(
      type: type,
      valeur: provider.getDerniereValeur(type),
      unite: type.uniteParDefaut,
      statut: provider.getStatut(type),
      tendance: provider.getTendance(type),
      chartData: provider.getChartData(type),
      isCircular: isCircular,
    );
  }

  Widget _buildWeekNavigator() {
    final dateFormat = DateFormat('d MMMM y', 'fr_FR');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F5FE),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: () => _changeWeek(-1),
            color: const Color(0xFF1A3A6B),
            tooltip: 'Semaine précédente',
          ),
          Flexible(
            flex: 1,
            child: Text(
              '📅 ${dateFormat.format(_currentWeekStart)} - ${dateFormat.format(_currentWeekEnd)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A3A6B),
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 28),
            onPressed: () => _changeWeek(1),
            color: const Color(0xFF1A3A6B),
            tooltip: 'Semaine suivante',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          // Bouton Ajouter une mesure
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddMeasurementDialog(context),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Ajouter une mesure'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A5BB5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bouton Historique
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showHistorique(context),
              icon: const Icon(Icons.history),
              label: const Text('Voir l\'historique complet'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A3A6B),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                side: const BorderSide(color: Color(0xFFC3D7ED)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bouton Export CSV
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _exportCSV(),
              icon: const Icon(Icons.file_download),
              label: const Text('Export CSV pour médecin'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A3A6B),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                side: const BorderSide(color: Color(0xFFC3D7ED)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMeasurementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddMeasurementDialog(),
    ).then((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _showHistorique(BuildContext context) {
    Navigator.pushNamed(context, '/historique-constantes').then((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _exportCSV() async {
  try {
    setState(() => _isLoading = true);
    
    final provider = Provider.of<VitalProvider>(context, listen: false);
    await provider.exportCSV();
    
    if (mounted) {
      _showSnackBar('✅ Export CSV prêt à être partagé !');
    }
  } catch (e) {
    if (mounted) {
      _showSnackBar('❌ Erreur export: $e', isError: true);
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  void _showAlerteDetails(AlerteSante alerte) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(alerte.typeIcone, color: alerte.niveauCouleur),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                alerte.typeTexte,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: alerte.niveauCouleur.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Gravité: ${alerte.niveauGraviteTexte}',
                style: TextStyle(
                  color: alerte.niveauCouleur,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              alerte.message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              '📅 ${DateFormat('dd/MM/yyyy HH:mm').format(alerte.dateCreation)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (!alerte.estLue)
            ElevatedButton(
              onPressed: () {
                _marquerAlerteLue(alerte);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A5BB5),
              ),
              child: const Text('Marquer comme lue'),
            ),
        ],
      ),
    );
  }

  void _marquerAlerteLue(AlerteSante alerte) async {
    try {
      final provider = Provider.of<VitalProvider>(context, listen: false);
      await provider.marquerAlerteLue(alerte.id);
      if (mounted) {
        _showSnackBar('✅ Alerte marquée comme lue');
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Erreur: $e', isError: true);
      }
    }
  }
}