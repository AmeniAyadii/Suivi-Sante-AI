// lib/services/logger_service.dart
import 'dart:developer' as developer;
import 'package:stack_trace/stack_trace.dart';

class LoggerService {
  static const String _tag = '📋 ReportScreen';
  
  // Log d'information
  static void info(String message, {String? tag}) {
    developer.log(
      '${tag ?? _tag} - ℹ️ $message',
      name: 'INFO',
      time: DateTime.now(),
    );
  }
  
  // Log de debug
  static void debug(String message, {String? tag}) {
    developer.log(
      '${tag ?? _tag} - 🐛 $message',
      name: 'DEBUG',
      time: DateTime.now(),
    );
  }
  
  // Log d'erreur avec stack trace
  static void error(String message, {dynamic error, StackTrace? stackTrace, String? tag}) {
    final stack = stackTrace ?? StackTrace.current;
    final trace = Trace.from(stack);
    final frames = trace.frames.take(5).toList();
    final stackInfo = frames.map((frame) => '  ${frame.toString()}').join('\n');
    
    developer.log(
      '${tag ?? _tag} - ❌ $message\n'
      'Erreur: $error\n'
      'Stack trace:\n$stackInfo',
      name: 'ERROR',
      time: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  // Log de succès
  static void success(String message, {String? tag}) {
    developer.log(
      '${tag ?? _tag} - ✅ $message',
      name: 'SUCCESS',
      time: DateTime.now(),
    );
  }
  
  // Log de warning
  static void warning(String message, {String? tag}) {
    developer.log(
      '${tag ?? _tag} - ⚠️ $message',
      name: 'WARNING',
      time: DateTime.now(),
    );
  }
  
  // Log pour les appels API
  static void api(String method, String endpoint, {Map<String, dynamic>? request, Map<String, dynamic>? response, int? statusCode}) {
    developer.log(
      '${_tag} - 🌐 $method $endpoint\n'
      'Status: $statusCode\n'
      'Request: ${request != null ? _formatJson(request) : 'N/A'}\n'
      'Response: ${response != null ? _formatJson(response) : 'N/A'}',
      name: 'API',
      time: DateTime.now(),
    );
  }
  
  // Formatage JSON pour les logs
  static String _formatJson(Map<String, dynamic> data) {
    try {
      return data.toString().replaceAll('{', '{\n  ').replaceAll('}', '\n}').replaceAll(',', ',\n  ');
    } catch (_) {
      return data.toString();
    }
  }
  
  // Log de performance
  static void performance(String operation, Duration duration, {String? tag}) {
    developer.log(
      '${tag ?? _tag} - ⏱️ $operation: ${duration.inMilliseconds}ms',
      name: 'PERFORMANCE',
      time: DateTime.now(),
    );
  }
  
  // Log d'état
  static void state(String component, Map<String, dynamic> state, {String? tag}) {
    developer.log(
      '${tag ?? _tag} - 📊 $component state:\n${_formatJson(state)}',
      name: 'STATE',
      time: DateTime.now(),
    );
  }

  

  
}