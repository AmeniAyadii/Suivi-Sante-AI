import 'dart:async';
import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suivi_sante_pro/config/app_config.dart';
import 'package:suivi_sante_pro/models/user.dart';
import 'package:suivi_sante_pro/providers/chatbot/chat_provider.dart';
import 'package:suivi_sante_pro/providers/goals_provider.dart';
import 'package:suivi_sante_pro/providers/notification_provider.dart';
import 'package:suivi_sante_pro/providers/tension_provider.dart';
import 'package:suivi_sante_pro/providers/vital_provider.dart';
import 'package:suivi_sante_pro/screens/add_measure_screen.dart';
import 'package:suivi_sante_pro/screens/admin/admin_appointments_screen.dart';
import 'package:suivi_sante_pro/screens/admin/admin_dashboard_screen.dart';
import 'package:suivi_sante_pro/screens/admin/admin_doctors_screen.dart';
import 'package:suivi_sante_pro/screens/admin/admin_home_screen.dart';
import 'package:suivi_sante_pro/screens/admin/admin_medicaments_screen.dart';
import 'package:suivi_sante_pro/screens/admin/admin_users_screen.dart';
import 'package:suivi_sante_pro/screens/analysis_screen.dart';
import 'package:suivi_sante_pro/screens/auth/role_router_screen.dart';
import 'package:suivi_sante_pro/screens/chatbot/chat_screen.dart';
import 'package:suivi_sante_pro/screens/doctor/doctor_appointments_screen.dart';
import 'package:suivi_sante_pro/screens/doctor/doctor_dashboard_tab.dart';
import 'package:suivi_sante_pro/screens/doctor/doctor_home_screen.dart';
import 'package:suivi_sante_pro/screens/doctor/doctor_patients_screen.dart';
import 'package:suivi_sante_pro/screens/doctor/doctor_prescriptions_screen.dart';
import 'package:suivi_sante_pro/screens/health_assessment_form_screen.dart';
import 'package:suivi_sante_pro/screens/health_bilan_screen.dart';
import 'package:suivi_sante_pro/screens/health_goals_page.dart';
import 'package:suivi_sante_pro/screens/notification_screen.dart';
import 'package:suivi_sante_pro/screens/report_screen.dart';
import 'package:suivi_sante_pro/screens/scan_screen.dart';
import 'package:suivi_sante_pro/screens/settings_screen.dart';
import 'package:suivi_sante_pro/screens/statistiques_screen.dart';
import 'package:suivi_sante_pro/screens/symptome_form_screen.dart';
import 'package:suivi_sante_pro/screens/symptomes_screen.dart';
import 'package:suivi_sante_pro/screens/triage_form_screen.dart';
import 'package:suivi_sante_pro/screens/vital_tracker/historique_constantes_screen.dart';
import 'package:suivi_sante_pro/screens/vital_tracker/vital_tracker_screen.dart';
import 'package:suivi_sante_pro/screens/welcome/onboarding_screen.dart';
import 'package:suivi_sante_pro/screens/welcome/welcome_screen.dart';
import 'package:suivi_sante_pro/services/fcm_service.dart';
import 'package:suivi_sante_pro/services/launch_service.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/medicaments_screen.dart';
import 'screens/rendezvous_screen.dart';
import 'screens/profile_screen.dart';

class GlobalNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

class NotificationManager {
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    final actionKey = receivedAction.buttonKeyPressed;
    if (actionKey == 'TAKE') {
      print('✅ Médicament pris !');
    } else if (actionKey == 'REMIND') {
      print('⏰ Rappel dans 30 minutes');
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecond,
          channelKey: 'scheduled_channel',
          title: '⏰ Rappel',
          body: 'Prenez votre médicament',
        ),
        schedule: NotificationCalendar(minute: DateTime.now().minute + 30, second: 0),
      );
    }
  }
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {}
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {}
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {}
}

void main() async {
  // ✅ Ignore les erreurs d'overflow (les dégrade en simple warning)
  // ⚠️ À retirer en production après résolution définitive
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('overflowed')) {
      debugPrint('⚠️ Overflow ignoré (à corriger): ${details.exceptionAsString()}');
      return;
    }
    originalOnError?.call(details);
  };
  // ✅ 1. OBLIGATOIRE : Initialiser le binding en tout premier
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Affiche la stack trace complète des erreurs de layout
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('❌ ERREUR FLUTTER: ${details.exception}');
    debugPrint('📍 CONTEXTE: ${details.context}');
    debugPrint('📍 LIBRARY: ${details.library}');
    debugPrint('📍 STACK:\n${details.stack}');
  };

  // ✅ 2. Lancer l'application dans la même zone
  runZonedGuarded(
    () async {
      // Capture des erreurs Flutter
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        print('❌ ERREUR FLUTTER: ${details.exceptionAsString()}');
      };

      // Initialisation Firebase
      try {
        const FirebaseOptions options = FirebaseOptions(
          apiKey: 'AIzaSyDVF190jIrdSLtsrPU_OXEVq7OwaXfmwsA',
          appId: '1:458697508979:android:73273e7b7e7a68b608c206',
          messagingSenderId: '458697508979',
          projectId: 'suivi-sante-pro',
          storageBucket: 'suivi-sante-pro.firebasestorage.app',
        );
        await Firebase.initializeApp(options: options);
        debugPrint('✅ Firebase initialisé');
        
        await FCMService.initialize();
        debugPrint('✅ FCMService initialisé');
      } catch (e) {
        debugPrint('❌ Erreur Firebase: $e');
      }

      // Initialisation des dates
      try {
        await initializeDateFormatting('fr_FR', null);
      } catch (e) {
        print('⚠️ Erreur dates: $e');
      }

      // ✅ LANCEMENT DE L'APP (dans le même zone)
      runApp(
        MultiProvider(
          providers: [
            Provider<AuthService>(create: (_) => AuthService()),
            Provider<ApiService>(create: (_) => ApiService()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
            ChangeNotifierProvider(create: (_) => TensionProvider()),
            ChangeNotifierProvider(create: (_) => GoalsProvider()),
            ChangeNotifierProvider(create: (_) => VitalProvider()),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      print('❌ ERREUR ASYNCHRONE GLOBALE: $error');
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  bool _isLoading = true;
  bool _isFirstLaunch = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      _isFirstLaunch = await LaunchService.isFirstLaunch();
      final authService = AuthService();
      _isLoggedIn = await authService.isLoggedIn();

      User? currentUser;
      if (_isLoggedIn) {
        currentUser = await authService.getCurrentUser();
      }

      if (mounted) {
        setState(() {
          _currentUser = currentUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFirstLaunch = true;
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
        debugShowCheckedModeBanner: false,
      );
    }

    Widget homeScreen;
    if (_isLoggedIn && _currentUser != null) {
      switch (_currentUser!.role) {
        case 'doctor':
          homeScreen = DoctorHomeScreen(user: _currentUser!);
          break;
        case 'admin':
          homeScreen = AdminHomeScreen(user: _currentUser!);
          break;
        case 'patient':
        default:
          homeScreen = const DashboardScreen();
          break;
      }
    } else if (_isLoggedIn) {
      homeScreen = const LoginScreen();
    } else if (_isFirstLaunch) {
      homeScreen = const OnboardingScreen();
    } else {
      homeScreen = const LoginScreen();
    }

    return MaterialApp(
      title: 'Suivi Santé AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: homeScreen,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/medicaments': (context) => const MedicamentsScreen(),
        '/rendezvous': (context) => const RendezvousScreen(),
        '/symptomes': (context) => const SymptomesScreen(),
        '/symptomes/ajout': (context) => const SymptomeFormScreen(),
        '/chatbot': (context) => const ChatbotScreen(),
        '/chat': (context) => const ChatScreen(),
        '/statistiques': (context) => const StatistiquesScreen(),
        '/reports': (context) => const ReportScreen(),
        '/bilan': (context) => const HealthBilanScreen(),
        '/bilan/form': (context) => const HealthAssessmentFormScreen(),
        '/scan': (context) => const ScanScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/profile/edit': (context) => const UnderConstructionPage(title: 'Édition'),
        '/goals': (context) => const HealthGoalsPage(),
        '/vital-tracker': (context) => const VitalTrackerScreen(),
        '/tension/ajout': (context) => const AddMeasureScreen(),
        '/tension/analyse': (context) => const AnalysisScreen(),
        '/triage': (context) => const TriageFormScreen(),
        '/doctor/patients': (_) => const DoctorPatientsScreen(),
        '/doctor/appointments': (_) => const DoctorAppointmentsScreen(),
        '/admin/dashboard': (_) => const AdminDashboardScreen(),
        '/admin/users': (_) => const AdminUsersScreen(),
        '/admin/doctors': (_) => const AdminDoctorsScreen(),
        '/admin/appointments': (_) => const AdminAppointmentsScreen(),
        '/admin/medicaments': (_) => const AdminMedicamentsScreen(),
        '/doctor/dashboard': (_) => const DoctorDashboardTab(),
        '/doctor/prescriptions': (_) => const DoctorPrescriptionsScreen(),
        // ✅ AJOUTE CETTE LIGNE :
    '/historique-constantes': (context) => const HistoriqueConstantesScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/role-router') {
          final args = settings.arguments;
          if (args is Map<String, dynamic>) {
            return MaterialPageRoute(builder: (_) => RoleRouterScreen(user: args['user']));
          }
        }
        if (settings.name == '/doctor/home') {
          final args = settings.arguments;
          if (args is Map<String, dynamic>) {
            return MaterialPageRoute(builder: (_) => DoctorHomeScreen(user: args['user']));
          }
        }
        if (settings.name == '/admin/home') {
          final args = settings.arguments;
          if (args is Map<String, dynamic>) {
            return MaterialPageRoute(builder: (_) => AdminHomeScreen(user: args['user']));
          }
        }
        return null;
      },
    );
  }
}

class UnderConstructionPage extends StatelessWidget {
  final String title;
  const UnderConstructionPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text('Page en cours de construction', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
            ),
          ],
        ),
      ),
    );
  }
}