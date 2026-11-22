// lib/screens/vital_tracker/historique_constantes_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/constante_vitale.dart';
import '../../providers/vital_provider.dart';

class HistoriqueConstantesScreen extends StatefulWidget {
  const HistoriqueConstantesScreen({Key? key}) : super(key: key);

  @override
  State<HistoriqueConstantesScreen> createState() =>
      _Histor9yMnTm4NSzvG9rrwjM2ec8xZgh1cafXH8();
}

class _Histor9yMnTm4NSzvG9rrwjM2ec8xZgh1cafXH8 extends State<HistoriqueConstantesScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VitalProvider>().loadHistorique(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<VitalProvider>().loadHistorique();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onFilterTap(String? type) {
    setState(() => _selectedType = type);
    context.read<VitalProvider>().setFiltreTypeHistorique(type);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDark),
            _buildFilters(isDark),
            Expanded(
              child: Consumer<VitalProvider>(
                builder: (context, provider, _) {
                  if (provider.isHistoriqueLoading && provider.historique.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                    );
                  }

                  if (provider.historique.isEmpty) {
                    return _buildEmptyState(isDark);
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.loadHistorique(
                      type: _selectedType,
                      refresh: true,
                    ),
                    color: const Color(0xFF6C63FF),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.historique.length + 1,
                      itemBuilder: (context, index) {
                        if (index == provider.historique.length) {
                          return provider.isHistoriqueLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF6C63FF),
                                    ),
                                  ),
                                )
                              : const SizedBox(height: 80);
                        }

                        final constante = provider.historique[index];
                        return _HistoryCard(
                          constante: constante,
                          index: index,
                          isDark: isDark,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== APP BAR ====================
  Widget _buildAppBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8B83FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historique complet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Toutes vos mesures de santé',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
    );
  }

  // ==================== FILTRES ====================
  Widget _buildFilters(bool isDark) {
    final types = <Map<String, dynamic>>[
      {'label': 'Tous', 'value': null, 'icon': Icons.apps_rounded},
      {'label': 'Tension', 'value': 'tension_systolique', 'icon': Icons.favorite_rounded},
      {'label': 'FC', 'value': 'frequence_cardiaque', 'icon': Icons.monitor_heart_rounded},
      {'label': 'Temp.', 'value': 'temperature', 'icon': Icons.thermostat_rounded},
      {'label': 'Glycémie', 'value': 'glycemie', 'icon': Icons.water_drop_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: types.map((t) {
            final isSelected = _selectedType == t['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: t['label'],
                icon: t['icon'],
                isSelected: isSelected,
                isDark: isDark,
                onTap: () => _onFilterTap(t['value']),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==================== EMPTY STATE ====================
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune mesure trouvée',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Commencez par ajouter une mesure',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ℹ️ À propos de l\'historique'),
        content: const Text(
          'Cet écran affiche toutes vos mesures de santé enregistrées.\n\n'
          'Utilisez les filtres en haut pour afficher un type de mesure spécifique.\n\n'
          'Tirez vers le bas pour actualiser les données.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}

// ==================== FILTER CHIP ====================
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? const Color(0xFF6C63FF)
        : (isDark ? const Color(0xFF2A2A3E) : const Color(0xFFF0F0F8));

    final textColor = isSelected
        ? Colors.white
        : (isDark ? Colors.grey[400] : Colors.grey[700]);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== HISTORY CARD ====================
class _HistoryCard extends StatelessWidget {
  final ConstanteVitale constante;
  final int index;
  final bool isDark;

  const _HistoryCard({
    required this.constante,
    required this.index,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final type = TypeConstante.values.firstWhere(
      (t) => t.value == constante.typeConstante,
      orElse: () => TypeConstante.tensionSystolique,
    );

    final cardColor = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetail(context, type),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icone avec fond coloré
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: type.uiColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(type.uiIcon, color: type.uiColor, size: 22),
                ),
                const SizedBox(width: 14),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy • HH:mm', 'fr_FR')
                                .format(constante.dateMesure),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Valeur
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${constante.valeur.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: type.uiColor,
                      ),
                    ),
                    Text(
                      constante.unite,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
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

  void _showDetail(BuildContext context, TypeConstante type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: type.uiColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(type.uiIcon, color: type.uiColor, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  type.label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Valeur', '${constante.valeur} ${constante.unite}', isDark),
            _buildDetailRow('Date', DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR')
                .format(constante.dateMesure), isDark),
            if (constante.notes != null && constante.notes!.isNotEmpty)
              _buildDetailRow('Notes', constante.notes!, isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== EXTENSION POUR LE DESIGN ====================
extension TypeConstanteDesign on TypeConstante {
  Color get uiColor {
    switch (this) {
      case TypeConstante.tensionSystolique:
      case TypeConstante.tensionDiastolique:
        return const Color(0xFFE63946);
      case TypeConstante.frequenceCardiaque:
        return const Color(0xFFFF6B6B);
      case TypeConstante.temperature:
        return const Color(0xFFF4A261);
      case TypeConstante.glycemie:
        return const Color(0xFF2A9D8F);
      default:
        return const Color(0xFF6C63FF);
    }
  }

  IconData get uiIcon {
    switch (this) {
      case TypeConstante.tensionSystolique:
      case TypeConstante.tensionDiastolique:
        return Icons.favorite_rounded;
      case TypeConstante.frequenceCardiaque:
        return Icons.monitor_heart_rounded;
      case TypeConstante.temperature:
        return Icons.thermostat_rounded;
      case TypeConstante.glycemie:
        return Icons.water_drop_rounded;
      default:
        return Icons.analytics_rounded;
    }
  }
}