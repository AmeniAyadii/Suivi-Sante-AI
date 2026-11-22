import 'package:flutter/material.dart';
import 'package:suivi_sante_pro/utils/chatbot/colors.dart';

class QuickActions extends StatelessWidget {
  final List<QuickActionItem> actions;

  const QuickActions({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: actions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                action.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              avatar: Icon(action.icon, size: 18, color: AppColors.primary),
              onPressed: action.onTap,
              backgroundColor: Colors.white,
              side: BorderSide(color: AppColors.primaryLight),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: StadiumBorder(
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class QuickActionItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  QuickActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}
