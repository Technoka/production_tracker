import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gestion_produccion/widgets/ui_widgets.dart';
import '../../utils/app_error.dart';
import '../../utils/error_handler.dart';

/// Widget inline que muestra un error dentro de la pantalla.
/// En debug muestra el detalle técnico; en release solo el mensaje localizado.
///
/// Uso:
/// ```dart
/// if (service.appError != null)
///   AppErrorWidget(error: service.appError!)
/// ```
class AppErrorWidget extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    Key? key,
    required this.error,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userMessage = error.localizedMessage(context);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _iconForType(error.type),
                color: theme.colorScheme.error,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  userMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Icon(Icons.refresh, size: 18),
                ),
            ],
          ),
          // Solo en debug: mostrar detalle técnico
          if (kDebugMode) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '🔴 DEBUG: ${error.debugDetail}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Colors.red.shade900,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconForType(AppErrorType type) {
    switch (type) {
      case AppErrorType.permission:
        return Icons.lock_outline;
      case AppErrorType.network:
        return Icons.wifi_off_outlined;
      case AppErrorType.notFound:
        return Icons.search_off_outlined;
      case AppErrorType.auth:
        return Icons.person_off_outlined;
      case AppErrorType.validation:
        return Icons.warning_amber_outlined;
      case AppErrorType.conflict:
        return Icons.merge_type_outlined;
      case AppErrorType.internal:
        return Icons.error_outline;
    }
  }
}

// ---------------------------------------------------------------------------
// Helpers estáticos para SnackBar (uso rápido desde cualquier pantalla)
// ---------------------------------------------------------------------------

class AppErrorSnackBar {
  AppErrorSnackBar._();

  /// Muestra un SnackBar con el error. En debug añade el detalle técnico.
  static void show(BuildContext context, AppError error) {
    final userMessage = error.localizedMessage(context);
    final message =
        kDebugMode ? '$userMessage\n🔴 ${error.debugDetail}' : userMessage;

    AppSnackBars.error(
      context,
      message,
      duration:
          kDebugMode ? const Duration(seconds: 6) : const Duration(seconds: 3),
    );
  }

  /// Convierte cualquier excepción directamente a SnackBar (atajo).
  static void showFromException(BuildContext context, dynamic exception) {
    show(context, ErrorHandler.from(exception));
  }
}
