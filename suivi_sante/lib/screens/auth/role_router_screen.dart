import 'package:flutter/material.dart';
import 'package:suivi_sante_pro/core/constants/enums/user_role.dart';

import '../../models/user.dart';
import '../dashboard_screen.dart';
import '../doctor/doctor_home_screen.dart';
import '../admin/admin_home_screen.dart';

class RoleRouterScreen extends StatelessWidget {
  final User user;
  const RoleRouterScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    switch (user.userRole) {
      case UserRole.doctor:
        return DoctorHomeScreen(user: user);
      case UserRole.admin:
        return AdminHomeScreen(user: user);
      case UserRole.patient:
      default:
        return const DashboardScreen();
    }
  }
}