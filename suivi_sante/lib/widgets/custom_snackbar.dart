import 'package:flutter/material.dart';

/// Types de snackbar disponibles
enum SnackbarType {
  success,
  error,
  warning,
  info,
  custom,
}

/// Widget de snackbar personnalisé avec animations
class CustomSnackbar {
  /// Affiche un snackbar personnalisé
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    String? title,
    VoidCallback? onAction,
    String? actionLabel,
    Color? backgroundColor,
    IconData? icon,
    bool isDismissible = true,
    double? width,
  }) {
    // Configuration des couleurs et icônes par type
    Color bgColor;
    IconData iconData;
    Color iconColor;

    switch (type) {
      case SnackbarType.success:
        bgColor = Colors.green.shade700;
        iconData = Icons.check_circle;
        iconColor = Colors.white;
        break;
      case SnackbarType.error:
        bgColor = Colors.red.shade700;
        iconData = Icons.error;
        iconColor = Colors.white;
        break;
      case SnackbarType.warning:
        bgColor = Colors.orange.shade700;
        iconData = Icons.warning;
        iconColor = Colors.white;
        break;
      case SnackbarType.info:
        bgColor = Colors.blue.shade700;
        iconData = Icons.info;
        iconColor = Colors.white;
        break;
      case SnackbarType.custom:
        bgColor = backgroundColor ?? Colors.grey.shade800;
        iconData = icon ?? Icons.notifications;
        iconColor = Colors.white;
        break;
    }

    // Construction du snackbar
    final snackBar = SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: bgColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: width != null ? (MediaQuery.of(context).size.width - width) / 2 : 16,
        right: width != null ? (MediaQuery.of(context).size.width - width) / 2 : 16,
      ),
      elevation: 6,
      dismissDirection: isDismissible ? DismissDirection.down : DismissDirection.none,
      action: onAction != null && actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onAction,
              textColor: Colors.white,
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Affiche un snackbar de succès
  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? title,
  }) {
    show(
      context,
      message: message,
      type: SnackbarType.success,
      duration: duration,
      title: title,
    );
  }

  /// Affiche un snackbar d'erreur
  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? title,
  }) {
    show(
      context,
      message: message,
      type: SnackbarType.error,
      duration: duration,
      title: title,
    );
  }

  /// Affiche un snackbar d'avertissement
  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? title,
  }) {
    show(
      context,
      message: message,
      type: SnackbarType.warning,
      duration: duration,
      title: title,
    );
  }

  /// Affiche un snackbar d'information
  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    String? title,
  }) {
    show(
      context,
      message: message,
      type: SnackbarType.info,
      duration: duration,
      title: title,
    );
  }

  /// Affiche un snackbar avec action
  static void action(
    BuildContext context,
    String message,
    String actionLabel,
    VoidCallback onAction, {
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 5),
    String? title,
  }) {
    show(
      context,
      message: message,
      type: type,
      duration: duration,
      title: title,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

/// Snackbar avec barre de progression
class ProgressSnackbar {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  /// Affiche un snackbar avec indicateur de progression
  static void show(
    BuildContext context, {
    required String message,
    double progress = 0.0,
    Color backgroundColor = Colors.blue,
  }) {
    _remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: backgroundColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: progress,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            backgroundColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: backgroundColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(backgroundColor),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isShowing = true;
  }

  /// Met à jour la progression
  static void updateProgress(double progress) {
    if (_overlayEntry != null && _isShowing) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  /// Supprime le snackbar
  static void remove() {
    _remove();
  }

  static void _remove() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isShowing = false;
    }
  }

  static bool get isShowing => _isShowing;
}

/// Snackbar avec photo/avatar
class AvatarSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    required String avatarText,
    Color? avatarColor,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          CircleAvatar(
            backgroundColor: avatarColor ?? Colors.blue.shade700,
            radius: 24,
            child: Text(
              avatarText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade800,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(16),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
