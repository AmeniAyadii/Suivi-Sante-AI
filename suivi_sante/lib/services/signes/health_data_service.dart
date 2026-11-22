import 'package:health_connector/health_connector.dart';

class HealthDataService {
  HealthConnector? _connector;

  // 1. Initialiser le connecteur
  Future<void> initialize() async {
    // Vérifier la disponibilité de la plateforme [citation:1]
    final status = await HealthConnector.getHealthPlatformStatus();
    if (status != HealthPlatformStatus.available) {
      throw Exception('Health platform not available: $status');
    }

    // Créer l'instance du connecteur
    _connector = await HealthConnector.create(
      const HealthConnectorConfig(
        loggerConfig: HealthConnectorLoggerConfig(
          logProcessors: [PrintLogProcessor()],
        ),
      ),
    );
  }

  // 2. Demander les permissions
  Future<bool> requestPermissions() async {
    if (_connector == null) throw Exception('Connector not initialized');

    final permissions = [
      HealthDataType.steps.readPermission,
      HealthDataType.steps.writePermission,
      HealthDataType.heartRate.readPermission,
      HealthDataType.bloodPressure.readPermission,
      HealthDataType.weight.readPermission,
    ];

    final results = await _connector!.requestPermissions(permissions);
    final granted = results.every((r) => r.status != PermissionStatus.denied);
    return granted;
  }

  // 3. Lire la fréquence cardiaque des dernières 24h
  Future<List<HeartRateRecord>> getHeartRateLast24h() async {
    if (_connector == null) throw Exception('Connector not initialized');

    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 1));

    final response = await _connector!.readRecords(
      HealthDataType.heartRate.readInTimeRange(
        startTime: start,
        endTime: now,
        pageSize: 100,
      ),
    );

    return response.records.cast<HeartRateRecord>();
  }

  // 4. Lire les pas du jour
  Future<int> getStepsToday() async {
    if (_connector == null) throw Exception('Connector not initialized');

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final response = await _connector!.aggregate(
      HealthDataType.steps.aggregateSum(
        startTime: startOfDay,
        endTime: now,
      ),
    );

    return response.value.value.toInt();
  }

  // 5. Lire la pression artérielle de la semaine
  Future<List<BloodPressureRecord>> getBloodPressureThisWeek() async {
    if (_connector == null) throw Exception('Connector not initialized');

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final response = await _connector!.readRecords(
      HealthDataType.bloodPressure.readInTimeRange(
        startTime: startOfWeek,
        endTime: now,
        pageSize: 50,
      ),
    );

    return response.records.cast<BloodPressureRecord>();
  }
}