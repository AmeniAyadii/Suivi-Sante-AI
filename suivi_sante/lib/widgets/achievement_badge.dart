// lib/widgets/achievement_badge.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suivi_sante_pro/models/achievement.dart';

class AchievementBadge extends StatefulWidget {
  final Achievement achievement;
  final bool isLocked;
  final double size;
  final VoidCallback? onTap;
  final bool showTooltip;

  const AchievementBadge({
    Key? key,
    required this.achievement,
    this.isLocked = false,
    this.size = 80,
    this.onTap,
    this.showTooltip = true,
  }) : super(key: key);

  @override
  State<AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<AchievementBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (!widget.isLocked) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isLocked
        ? Colors.grey
        : Color(
            int.parse(
              widget.achievement.colorHex.replaceFirst('#', ''),
              radix: 16,
            ),
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _isHovered ? 1.05 : _scaleAnimation.value,
              child: Transform.rotate(
                angle: _isHovered ? 0 : _rotationAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  margin: const EdgeInsets.all(4),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background
                      Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: widget.isLocked
                              ? LinearGradient(
                                  colors: [
                                    Colors.grey[300]!,
                                    Colors.grey[400]!,
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    color.withOpacity(0.3),
                                    color.withOpacity(0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          border: Border.all(
                            color: widget.isLocked ? Colors.grey[400]! : color,
                            width: widget.isLocked ? 1 : 2,
                          ),
                          boxShadow: widget.isLocked
                              ? null
                              : [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: Text(
                            widget.isLocked ? '🔒' : widget.achievement.icon,
                            style: TextStyle(fontSize: widget.size * 0.45),
                          ),
                        ),
                      ),

                      // Unlocked animation glow
                      if (!widget.isLocked)
                        Positioned(
                          child: Container(
                            width: widget.size * 1.2,
                            height: widget.size * 1.2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  color.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                                radius: 0.5,
                              ),
                            ),
                          ),
                        ),

                      // Level badge
                      if (!widget.isLocked && widget.achievement.level > 1)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Text(
                              '${widget.achievement.level}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      // Points badge
                      if (!widget.isLocked)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Text(
                              '${widget.achievement.points} pts',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                      // Tooltip
                      if (widget.showTooltip && _isHovered)
                        Positioned(
                          bottom: -30,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.isLocked
                                  ? '🔒 À débloquer'
                                  : widget.achievement.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// WIDGET: AchievementBadgeList (Version améliorée avec grille)
// ============================================================
class AchievementBadgeList extends StatelessWidget {
  final List<Achievement> achievements;
  final int crossAxisCount;
  final double spacing;
  final double runSpacing;
  final VoidCallback? onAchievementTap;

  const AchievementBadgeList({
    Key? key,
    required this.achievements,
    this.crossAxisCount = 3,
    this.spacing = 8,
    this.runSpacing = 8,
    this.onAchievementTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.9,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return AchievementBadge(
          achievement: achievement,
          isLocked: !achievement.isUnlocked,
          onTap: onAchievementTap != null ? () => onAchievementTap!() : null,
          showTooltip: true,
        );
      },
    );
  }
}

// ============================================================
// WIDGET: AchievementDetailModal (Pop-up de détail)
// ============================================================
class AchievementDetailModal extends StatelessWidget {
  final Achievement achievement;

  const AchievementDetailModal({Key? key, required this.achievement})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Color(
      int.parse(achievement.colorHex.replaceFirst('#', ''), radix: 16),
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              achievement.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              achievement.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem('🏷️', achievement.typeDisplay, 'Type'),
                _buildDetailItem('⭐', 'Niveau ${achievement.level}', 'Niveau'),
                _buildDetailItem('💎', '${achievement.points} pts', 'Points'),
              ],
            ),
            const SizedBox(height: 16),

            // Status
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    achievement.isUnlocked ? Icons.check_circle : Icons.lock,
                    color: achievement.isUnlocked ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    achievement.isUnlocked
                        ? '✅ Débloqué le ${DateFormat('dd/MM/yyyy').format(achievement.unlockedAt!)}'
                        : '🔒 À débloquer',
                    style: TextStyle(
                      color: achievement.isUnlocked
                          ? Colors.green[700]
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}
