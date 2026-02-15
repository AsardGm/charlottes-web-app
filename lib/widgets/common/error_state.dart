import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'empty_state.dart';

/// Enhanced error state widget with better messaging and retry functionality
class ErrorState extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;
  final String? customMessage;
  final bool showDetails;

  const ErrorState({
    super.key,
    required this.error,
    this.stackTrace,
    this.onRetry,
    this.customMessage,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final errorInfo = _parseError(error);

    return EmptyState(
      icon: errorInfo.icon,
      title: errorInfo.title,
      subtitle: customMessage ?? errorInfo.message,
      actionLabel: onRetry != null ? 'Zkusit znovu' : null,
      onAction: onRetry,
      iconColor: errorInfo.color,
    );
  }

  _ErrorInfo _parseError(Object error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('failed host lookup')) {
      return _ErrorInfo(
        icon: Icons.wifi_off_rounded,
        title: 'Žádné připojení',
        message: 'Zkontroluj připojení k internetu\na zkus to znovu.',
        color: AppColors.error,
      );
    }

    // Timeout errors
    if (errorString.contains('timeout') ||
        errorString.contains('deadline')) {
      return _ErrorInfo(
        icon: Icons.access_time_rounded,
        title: 'Vypršel čas',
        message: 'Požadavek trval příliš dlouho.\nZkus to prosím znovu.',
        color: AppColors.warning,
      );
    }

    // Auth errors
    if (errorString.contains('auth') ||
        errorString.contains('unauthorized') ||
        errorString.contains('403') ||
        errorString.contains('401')) {
      return _ErrorInfo(
        icon: Icons.lock_outline_rounded,
        title: 'Nepřihlášený',
        message: 'Přihlas se prosím\npro přístup k tomuto obsahu.',
        color: AppColors.warning,
      );
    }

    // Permission errors
    if (errorString.contains('permission') ||
        errorString.contains('forbidden')) {
      return _ErrorInfo(
        icon: Icons.block_rounded,
        title: 'Nedostatečná oprávnění',
        message: 'Nemáš oprávnění\nk této akci.',
        color: AppColors.error,
      );
    }

    // Not found errors
    if (errorString.contains('404') ||
        errorString.contains('not found')) {
      return _ErrorInfo(
        icon: Icons.search_off_rounded,
        title: 'Nenalezeno',
        message: 'Požadovaný obsah\nneexistuje nebo byl smazán.',
        color: AppColors.textMuted,
      );
    }

    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('502') ||
        errorString.contains('503') ||
        errorString.contains('server')) {
      return _ErrorInfo(
        icon: Icons.cloud_off_rounded,
        title: 'Chyba serveru',
        message: 'Server právě nereaguje.\nZkus to prosím později.',
        color: AppColors.error,
      );
    }

    // Rate limit errors
    if (errorString.contains('rate limit') ||
        errorString.contains('too many requests') ||
        errorString.contains('429')) {
      return _ErrorInfo(
        icon: Icons.speed_rounded,
        title: 'Příliš mnoho požadavků',
        message: 'Zpomal prosím.\nZkus to za chvíli.',
        color: AppColors.warning,
      );
    }

    // Database errors
    if (errorString.contains('database') ||
        errorString.contains('query') ||
        errorString.contains('sql')) {
      return _ErrorInfo(
        icon: Icons.storage_rounded,
        title: 'Chyba databáze',
        message: 'Problém s uložením dat.\nZkus to prosím znovu.',
        color: AppColors.error,
      );
    }

    // Generic error
    return _ErrorInfo(
      icon: Icons.error_outline_rounded,
      title: 'Něco se pokazilo',
      message: 'Omlouváme se za nepříjemnosti.\nZkus to prosím znovu.',
      color: AppColors.error,
    );
  }
}

class _ErrorInfo {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  _ErrorInfo({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });
}

/// Compact error widget for inline display
class InlineErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const InlineErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.error_outline_rounded,
            color: AppColors.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: const Text('Zkusit znovu'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Snackbar-style error notification
class ErrorNotification {
  static void show(
    BuildContext context,
    Object error, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    final errorMessage = _getErrorMessage(error);

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Zkusit znovu',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static String _getErrorMessage(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('socket')) {
      return 'Žádné připojení k internetu';
    }
    if (errorString.contains('timeout')) {
      return 'Vypršel čas požadavku';
    }
    if (errorString.contains('404')) {
      return 'Obsah nenalezen';
    }
    if (errorString.contains('500')) {
      return 'Chyba serveru';
    }
    if (errorString.contains('auth')) {
      return 'Chyba přihlášení';
    }

    return 'Něco se pokazilo';
  }
}
