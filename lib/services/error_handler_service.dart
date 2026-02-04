import 'package:flutter/material.dart';
import 'haptic_service.dart';

/// Centralized error handling service
class ErrorHandlerService {
  /// Handle error with optional retry
  static Future<T?> handleError<T>({
    required Future<T> Function() operation,
    required BuildContext context,
    String? customMessage,
    bool showSnackbar = true,
    int maxRetries = 0,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;

    while (attempts <= maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;

        // If we have retries left, wait and try again
        if (attempts <= maxRetries) {
          await Future.delayed(retryDelay);
          continue;
        }

        // Final attempt failed, show error
        if (showSnackbar && context.mounted) {
          HapticService.error();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(customMessage ?? _getErrorMessage(e)),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }

        return null;
      }
    }

    return null;
  }

  /// Handle error with user-friendly message (no retry)
  static void showError(BuildContext context, dynamic error,
      {String? customMessage}) {
    if (!context.mounted) return;

    HapticService.error();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(customMessage ?? _getErrorMessage(error)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show success message
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    HapticService.success();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF66BB6A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Show info message
  static void showInfo(BuildContext context, String message) {
    if (!context.mounted) return;

    HapticService.light();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Get user-friendly error message
  static String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Problém s připojením. Zkontroluj internet.';
    }

    // Auth errors
    if (errorString.contains('auth') ||
        errorString.contains('unauthorized') ||
        errorString.contains('token')) {
      return 'Problém s přihlášením. Zkus se odhlásit a znovu přihlásit.';
    }

    // Timeout errors
    if (errorString.contains('timeout')) {
      return 'Požadavek trval příliš dlouho. Zkus to znovu.';
    }

    // Permission errors
    if (errorString.contains('permission') ||
        errorString.contains('forbidden')) {
      return 'Nemáš oprávnění k této akci.';
    }

    // Not found
    if (errorString.contains('not found') || errorString.contains('404')) {
      return 'Požadovaná data nebyla nalezena.';
    }

    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('server') ||
        errorString.contains('internal')) {
      return 'Problém na serveru. Zkus to později.';
    }

    // Validation errors
    if (errorString.contains('validation') ||
        errorString.contains('invalid')) {
      return 'Neplatná data. Zkontroluj své zadání.';
    }

    // Generic
    return 'Něco se pokazilo. Zkus to znovu.';
  }

  /// Show retry dialog
  static Future<bool> showRetryDialog(
    BuildContext context, {
    String? message,
  }) async {
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Chyba',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message ?? 'Operace selhala. Chceš to zkusit znovu?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Zkusit znovu'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Execute with loading indicator
  static Future<T?> withLoading<T>({
    required BuildContext context,
    required Future<T> Function() operation,
    String? loadingMessage,
  }) async {
    if (!context.mounted) return null;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (loadingMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(loadingMessage),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final result = await operation();
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
      }
      return result;
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading
        showError(context, e);
      }
      return null;
    }
  }
}
