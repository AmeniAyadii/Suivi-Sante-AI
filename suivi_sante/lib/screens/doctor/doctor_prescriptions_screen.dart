import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/doctor_service.dart';

class DoctorPrescriptionsScreen extends StatefulWidget {
  const DoctorPrescriptionsScreen({super.key});

  @override
  State<DoctorPrescriptionsScreen> createState() =>
      _DoctorahJ91ZuNL8Y2px8iYciYeHN8sfSh5eXH8();
}

class _DoctorahJ91ZuNL8Y2px8iYciYeHN8sfSh5eXH8 extends State<DoctorPrescriptionsScreen>
    with SingleTickerProviderStateMixin {
  // ==================== THEME ====================
  static const Color _primary = Color(0xFF6C5CE7);
  static const Color _primaryDark = Color(0xFF4834D4);
  static const Color _bg = Color(0xFFF7F8FC);
  static const Color _success = Color(0xFF00B894);
  static const Color _info = Color(0xFF0984E3);
  static const Color _muted = Color(0xFFB2BEC3);

  late Future<List<dynamic>> _future;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _fadeController;

  String _search = '';
  String _statutFilter = 'all';
  bool _isSearchVisible = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _future = _load().whenComplete(() => _fadeController.forward());
    
    // ✅ CORRECTION 1 : Le listener de recherche ne fait que mettre à jour l'état
    _searchController.addListener(() {
      if (_searchController.text != _search) {
        setState(() {
          _search = _searchController.text.trim();
          _future = _load(); // On déclenche le Future proprement
        });
      }
    });
    
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final visible = _scrollController.offset < 60;
    if (visible != _isSearchVisible) {
      setState(() => _isSearchVisible = visible);
    }
  }

  // ==================== DATA ====================
  Future<List<dynamic>> _load() async {
    return DoctorService().getPrescriptions(
      statut: _statutFilter == 'all' ? null : _statutFilter,
      search: _search.isEmpty ? null : _search,
    );
  }

  // ✅ CORRECTION 2 : _reload ne contient plus de async à l'intérieur du setState
  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  // ==================== HELPERS ====================
  Color _statutColor(String? s) {
    switch (s) {
      case 'actif': return _success;
      case 'inactif': return _muted;
      case 'termine': return _info;
      default: return Colors.grey;
    }
  }

  String _statutLabel(String? s) {
    switch (s) {
      case 'actif': return 'ACTIF';
      case 'inactif': return 'INACTIF';
      case 'termine': return 'TERMINÉ';
      default: return (s ?? '—').toUpperCase();
    }
  }

  IconData _statutIcon(String? s) {
    switch (s) {
      case 'actif': return Icons.check_circle_rounded;
      case 'inactif': return Icons.pause_circle_rounded;
      case 'termine': return Icons.flag_circle_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  void _showSnack(String msg, {Color bg = _success, IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            if (icon != null) Icon(icon, color: Colors.white, size: 20),
            if (icon != null) const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }

  // ==================== DIALOG AJOUT ====================
  void _showAddDialog() {
    final nomController = TextEditingController();
    final dosageController = TextEditingController();
    final frequenceController = TextEditingController();
    final notesController = TextEditingController();
    
    int? selectedPatientId;
    List<dynamic> patients = [];
    bool loadingPatients = true;
    bool submitting = false;

    Future<void> loadPatients() async {
      try {
        final p = await DoctorService().getPatients();
        patients = p;
        loadingPatients = false;
      } catch (e) {
        loadingPatients = false;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setStateModal) {
              
              if (loadingPatients && patients.isEmpty) {
                loadPatients().then((_) {
                  if (ctx.mounted) {
                    setStateModal(() {});
                  }
                });
              }

              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [_primary, _primaryDark]),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.medication_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Nouvelle prescription', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
                                Text('Remplissez les informations ci-dessous', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _label('Patient', required: true),
                      const SizedBox(height: 8),
                      if (loadingPatients)
                        Container(
                          height: 56,
                          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(14)),
                          child: const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
                        )
                      else
                        DropdownButtonFormField<int>(
                          value: selectedPatientId,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          decoration: _inputDecoration(hint: 'Sélectionner un patient', icon: Icons.person_rounded),
                          items: patients.map<DropdownMenuItem<int>>(
                            (p) => DropdownMenuItem<int>(
                              value: p['id'],
                              child: Text('${p['nom']}', overflow: TextOverflow.ellipsis),
                            ),
                          ).toList(),
                          onChanged: (v) => setStateModal(() => selectedPatientId = v),
                        ),
                      const SizedBox(height: 16),
                      _label('Médicament', required: true),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nomController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _inputDecoration(hint: 'Ex: Paracétamol', icon: Icons.medication_rounded),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Dosage'),
                                const SizedBox(height: 8),
                                TextField(controller: dosageController, decoration: _inputDecoration(hint: 'Ex: 500mg', icon: Icons.straighten_rounded)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Fréquence'),
                                const SizedBox(height: 8),
                                TextField(controller: frequenceController, decoration: _inputDecoration(hint: 'Ex: 2x/jour', icon: Icons.repeat_rounded)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _label('Notes'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _inputDecoration(hint: 'Instructions supplémentaires...', icon: Icons.notes_rounded),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: submitting ? null : () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                side: BorderSide(color: Colors.grey.shade300),
                                foregroundColor: Colors.grey.shade700,
                              ),
                              child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: submitting ? null : () async {
                                if (selectedPatientId == null || nomController.text.trim().isEmpty) {
                                  _showSnack('Patient et médicament requis', bg: Colors.orange.shade700, icon: Icons.warning_amber_rounded);
                                  return;
                                }
                                setStateModal(() => submitting = true);
                                try {
                                  await DoctorService().createPrescription(
                                    patientId: selectedPatientId!,
                                    nom: nomController.text.trim(),
                                    dosage: dosageController.text.trim().isEmpty ? null : dosageController.text.trim(),
                                    frequence: frequenceController.text.trim().isEmpty ? null : frequenceController.text.trim(),
                                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                                  );
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  _reload();
                                  _showSnack('Prescription créée avec succès', icon: Icons.check_circle_rounded);
                                } catch (e) {
                                  if (!ctx.mounted) return;
                                  setStateModal(() => submitting = false);
                                  _showSnack('Erreur: $e', bg: Colors.red.shade600, icon: Icons.error_rounded);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: submitting
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_rounded, size: 18),
                                        SizedBox(width: 6),
                                        Text('Prescrire', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Row(
      children: [
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3436))),
        if (required) const Text(' *', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
      prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
      filled: true,
      fillColor: _bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _primary, width: 1.5)),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: _isSearchVisible
          ? Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Rechercher un médicament...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade500),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(icon: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade600), onPressed: () => _searchController.clear())
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _primary, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bg,
        floatingActionButton: _buildFAB(),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildFilters(),
              const SizedBox(height: 4),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Prescriptions', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2D3436), letterSpacing: -0.5)),
              Text('Gérez vos ordonnances patients', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF2D3436), size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = <Map<String, dynamic>>[
      {'key': 'all', 'label': 'Toutes', 'icon': Icons.apps_rounded},
      {'key': 'actif', 'label': 'Actifs', 'icon': Icons.check_circle_rounded},
      {'key': 'inactif', 'label': 'Inactifs', 'icon': Icons.pause_circle_rounded},
      {'key': 'termine', 'label': 'Terminés', 'icon': Icons.flag_circle_rounded},
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = filters[i];
          final key = f['key'] as String;
          final label = f['label'] as String;
          final icon = f['icon'] as IconData;
          final selected = _statutFilter == key;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _statutFilter = key);
                  _reload();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? _primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: selected ? [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
                    border: selected ? null : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 14, color: selected ? Colors.white : Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.w500, color: selected ? Colors.white : Colors.grey.shade700)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2.5));
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error);
        }
        final list = snapshot.data ?? [];
        if (list.isEmpty) {
          return _buildEmptyState();
        }
        return RefreshIndicator(
          color: _primary,
          // ✅ CORRECTION 3 : onRefresh utilise une fonction async qui appelle setState de manière sécurisée
          onRefresh: () async {
            _reload();
            await _future;
          },
          child: FadeTransition(
            opacity: _fadeController,
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              itemCount: list.length,
              itemBuilder: (context, i) {
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 250 + (i * 40)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(offset: Offset(0, 12 * (1 - value)), child: child),
                    );
                  },
                  child: _buildCard(list[i]),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: _primary.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(Icons.medication_liquid_rounded, size: 48, color: _primary.withOpacity(0.6)),
          ),
          const SizedBox(height: 20),
          const Text('Aucune prescription', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
          const SizedBox(height: 6),
          Text(
            _search.isNotEmpty || _statutFilter != 'all' ? 'Essayez de modifier vos filtres' : 'Créez votre première prescription',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.error_outline_rounded, size: 40, color: Colors.red.shade400),
            ),
            const SizedBox(height: 16),
            const Text('Une erreur est survenue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('$error', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(dynamic m) {
    final statut = m['statut']?.toString();
    final color = _statutColor(statut);
    final nom = m['nom']?.toString() ?? 'Sans nom';
    final patient = m['user']?['nom']?.toString() ?? 'Patient inconnu';
    final dosage = m['dosage']?.toString();
    final frequence = m['frequence']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showPrescriptionDetails(m),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color, color.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: const Icon(Icons.medication_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nom, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.person_rounded, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(patient, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statutIcon(statut), size: 11, color: color),
                          const SizedBox(width: 4),
                          Text(_statutLabel(statut), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3)),
                        ],
                      ),
                    ),
                  ],
                ),
                if ((dosage != null && dosage.isNotEmpty) || (frequence != null && frequence.isNotEmpty)) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        if (dosage != null && dosage.isNotEmpty) _infoChip(Icons.straighten_rounded, dosage),
                        if (dosage != null && dosage.isNotEmpty && frequence != null && frequence.isNotEmpty)
                          Container(width: 1, height: 14, margin: const EdgeInsets.symmetric(horizontal: 10), color: Colors.grey.shade300),
                        if (frequence != null && frequence.isNotEmpty) _infoChip(Icons.repeat_rounded, frequence),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  void _showPrescriptionDetails(dynamic m) {
    final statut = m['statut']?.toString();
    final color = _statutColor(statut);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 44, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3))),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.medication_rounded, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['nom']?.toString() ?? 'Sans nom', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
                      Text(_statutLabel(statut), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _detailRow(Icons.person_rounded, 'Patient', m['user']?['nom']?.toString() ?? '—'),
            _detailRow(Icons.straighten_rounded, 'Dosage', m['dosage']?.toString() ?? '—'),
            _detailRow(Icons.repeat_rounded, 'Fréquence', m['frequence']?.toString() ?? '—'),
            if (m['notes'] != null && m['notes'].toString().isNotEmpty) _detailRow(Icons.notes_rounded, 'Notes', m['notes'].toString()),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D3436))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddDialog();
        },
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text('Nouvelle', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}