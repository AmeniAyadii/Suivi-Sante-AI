// lib/screens/vital_tracker/widgets/alert_banner.dart

import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';
import '../../../models/alerte_sante.dart';

/// Widget affichant une bannière d'alertes de santé avec animations et interactions
class AlertBanner extends StatefulWidget {
  final List<AlerteSante> alertes;
  final VoidCallback? onTap;
  final ValueChanged<AlerteSante>? onAlerteTap;
  final Function(AlerteSante)? onMarquerLue;
  final Function(AlerteSante)? onMarquerResolue;
  final bool autoDismiss;
  final Duration autoDismissDuration;
  final bool showCountBadge;
  final bool expandable;

  const AlertBanner({
    super.key,
    required this.alertes,
    this.onTap,
    this.onAlerteTap,
    this.onMarquerLue,
    this.onMarquerResolue,
    this.autoDismiss = false,
    this.autoDismissDuration = const Duration(seconds: 10),
    this.showCountBadge = true,
    this.expandable = true,
  });

  @override
  State<AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<AlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isExpanded = false;
  bool _isVisible = true;

  // ============ MÉTHODES UTILITAIRES POUR LES LISTES ============
  
  List<AlerteSante> get _alertesNonLues {
    return widget.alertes.where((a) => !a.estLue).toList();
  }

  List<AlerteSante> get _alertesCritiques {
    return widget.alertes.where(
      (a) => a.niveauGravite == NiveauGravite.critique ||
          a.niveauGravite == NiveauGravite.eleve,
    ).toList();
  }

  List<AlerteSante> get _alertesTrieesParGravite {
    final order = {
      NiveauGravite.critique: 0,
      NiveauGravite.eleve: 1,
      NiveauGravite.moder: 2,
      NiveauGravite.faible: 3,
    };
    final sorted = List<AlerteSante>.from(widget.alertes);
    sorted.sort((a, b) => order[a.niveauGravite]!.compareTo(order[b.niveauGravite]!));
    return sorted;
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();

    if (widget.autoDismiss && widget.alertes.isNotEmpty) {
      Future.delayed(widget.autoDismissDuration, () {
        if (mounted) {
          setState(() {
            _isVisible = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || widget.alertes.isEmpty) {
      return const SizedBox.shrink();
    }

    final alertesCritiques = _alertesCritiques;
    final alertesNonLues = _alertesNonLues;
    final alertesTriees = _alertesTrieesParGravite;
    final plusUrgente = alertesTriees.isNotEmpty ? alertesTriees.first : null;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          elevation: 4,
          shadowColor: Colors.black26,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: _buildGradient(plusUrgente),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: _getCouleurPrincipale(plusUrgente).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildContent(context, plusUrgente, alertesNonLues),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AlerteSante? plusUrgente,
    List<AlerteSante> alertesNonLues,
  ) {
    final alertesTriees = _alertesTrieesParGravite;

    return InkWell(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        } else if (widget.expandable) {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        }
      },
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la bannière
            Row(
              children: [
                // Icône
                _buildIcon(plusUrgente),
                const SizedBox(width: 12),
                // Texte principal
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTitre(plusUrgente, alertesNonLues),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.alertes.length > 1) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${widget.alertes.length} alerte${widget.alertes.length > 1 ? 's' : ''} au total',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Badge de compteur
                if (widget.showCountBadge && alertesNonLues.isNotEmpty)
                  _buildCountBadge(alertesNonLues.length),
                // Bouton fermer (si auto-dismiss est désactivé)
                if (!widget.autoDismiss)
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _isVisible = false;
                      });
                    },
                  ),
              ],
            ),
            // Contenu étendu
            if (_isExpanded && widget.expandable) ...[
              const Divider(
                color: Colors.white24,
                height: 16,
                thickness: 0.5,
              ),
              _buildExpandedContent(context),
            ],
            // Boutons d'action rapide
            if (widget.alertes.length > 1 && !_isExpanded) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = true;
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Voir tout ▼',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(AlerteSante? plusUrgente) {
    if (plusUrgente == null) {
      return const Icon(
        Icons.notifications_active,
        color: Colors.white,
        size: 28,
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        shape: BoxShape.circle,
      ),
      child: Icon(
        plusUrgente.typeIcone,
        color: Colors.white,
        size: 22,
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    final alertesTriees = _alertesTrieesParGravite;
    final alertesAPlus = alertesTriees.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        ...alertesAPlus.map((alerte) {
          return _buildAlerteItem(context, alerte);
        }),
        if (widget.alertes.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Et ${widget.alertes.length - 5} autre${widget.alertes.length - 5 > 1 ? 's' : ''}...',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        const SizedBox(height: 4),
        // Actions en bas
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _marquerToutesLues,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: Colors.white.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Marquer toutes lues',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlerteItem(BuildContext context, AlerteSante alerte) {
    return InkWell(
      onTap: () {
        if (widget.onAlerteTap != null) {
          widget.onAlerteTap!(alerte);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                color: alerte.niveauCouleur,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              alerte.typeIcone,
              color: Colors.white70,
              size: 16,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alerte.typeTexte,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    alerte.message,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!alerte.estLue)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              alerte.tempsEcoule,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
            if (widget.onMarquerLue != null && !alerte.estLue)
              IconButton(
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white54,
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => widget.onMarquerLue!(alerte),
                tooltip: 'Marquer comme lue',
              ),
          ],
        ),
      ),
    );
  }

  String _getTitre(AlerteSante? plusUrgente, List<AlerteSante> nonLues) {
    if (plusUrgente == null) {
      return 'Aucune alerte';
    }

    if (nonLues.isNotEmpty) {
      final urgentesCount = _alertesCritiques.length;
      if (urgentesCount > 0) {
        return '⚠️ $urgentesCount alerte${urgentesCount > 1 ? 's' : ''} urgente${urgentesCount > 1 ? 's' : ''} à traiter';
      }
      return '📢 ${nonLues.length} nouvelle${nonLues.length > 1 ? 's' : ''} alerte${nonLues.length > 1 ? 's' : ''}';
    }

    return plusUrgente.typeTexte;
  }

  LinearGradient _buildGradient(AlerteSante? plusUrgente) {
    final couleur = _getCouleurPrincipale(plusUrgente);
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        couleur,
        couleur.withOpacity(0.8),
      ],
      stops: const [0.0, 1.0],
    );
  }

  Color _getCouleurPrincipale(AlerteSante? plusUrgente) {
    if (plusUrgente == null) {
      return Colors.grey.shade700;
    }

    switch (plusUrgente.niveauGravite) {
      case NiveauGravite.critique:
        return Colors.red.shade700;
      case NiveauGravite.eleve:
        return Colors.orange.shade800;
      case NiveauGravite.moder:
        return Colors.orange.shade600;
      case NiveauGravite.faible:
        return Colors.green.shade700;
    }
  }

  void _marquerToutesLues() {
    if (widget.onMarquerLue == null) return;

    for (final alerte in widget.alertes.where((a) => !a.estLue)) {
      widget.onMarquerLue!(alerte);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toutes les alertes ont été marquées comme lues'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// ============ SimpleAlertBanner ============

class SimpleAlertBanner extends StatelessWidget {
  final AlerteSante alerte;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const SimpleAlertBanner({
    super.key,
    required this.alerte,
    this.onDismiss,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: _getCouleurFond(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alerte.niveauCouleur.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: alerte.niveauCouleur.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    alerte.typeIcone,
                    color: alerte.niveauCouleur,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alerte.typeTexte,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alerte.message,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.grey,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDismiss,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCouleurFond() {
    switch (alerte.niveauGravite) {
      case NiveauGravite.critique:
        return Colors.red.shade50;
      case NiveauGravite.eleve:
        return Colors.orange.shade50;
      case NiveauGravite.moder:
        return Colors.amber.shade50;
      case NiveauGravite.faible:
        return Colors.green.shade50;
    }
  }
}

// ============ AlertesDrawer ============

class AlertesDrawer extends StatelessWidget {
  final List<AlerteSante> alertes;
  final ValueChanged<AlerteSante>? onAlerteTap;
  final ValueChanged<AlerteSante>? onMarquerLue;
  final ValueChanged<AlerteSante>? onMarquerResolue;

  const AlertesDrawer({
    super.key,
    required this.alertes,
    this.onAlerteTap,
    this.onMarquerLue,
    this.onMarquerResolue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '📋 Alertes de santé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Flexible(
            child: alertes.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune alerte pour le moment',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: alertes.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final alerte = alertes[index];
                      return _buildAlerteTile(context, alerte);
                    },
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAlerteTile(BuildContext context, AlerteSante alerte) {
    return ListTile(
      onTap: () => onAlerteTap?.call(alerte),
      leading: CircleAvatar(
        backgroundColor: alerte.niveauCouleur.withOpacity(0.15),
        child: Icon(
          alerte.typeIcone,
          color: alerte.niveauCouleur,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              alerte.typeTexte,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (!alerte.estLue)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            alerte.niveauGraviteTexte,
            style: TextStyle(
              color: alerte.niveauCouleur,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alerte.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            alerte.tempsEcoule,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!alerte.estLue && onMarquerLue != null)
            IconButton(
              icon: const Icon(
                Icons.check_circle_outline,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: () => onMarquerLue!(alerte),
              tooltip: 'Marquer comme lue',
            ),
          if (alerte.estActive && onMarquerResolue != null)
            IconButton(
              icon: const Icon(
                Icons.done_all,
                color: Colors.green,
                size: 20,
              ),
              onPressed: () => onMarquerResolue!(alerte),
              tooltip: 'Marquer comme résolue',
            ),
        ],
      ),
    );
  }
}
