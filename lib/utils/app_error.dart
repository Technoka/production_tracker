import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Tipos de error que el usuario puede ver.
/// Añadir nuevos tipos aquí si en el futuro se necesitan categorías adicionales.
enum AppErrorType {
  internal,    // Error inesperado del sistema
  permission,  // Sin permisos para la acción
  network,     // Sin conexión o timeout
  notFound,    // Recurso no existe
  auth,        // Error de autenticación/sesión
  validation,  // Datos incorrectos o incompletos
  conflict,    // Conflicto de datos (ej: email ya en uso)
}

/// Resultado de error estandarizado.
/// [type] determina el mensaje localizado que ve el usuario.
/// [debugDetail] contiene el mensaje técnico original, solo visible en debug.
class AppError {
  final AppErrorType type;
  final String debugDetail;

  const AppError({
    required this.type,
    required this.debugDetail,
  });

  /// Mensaje localizado para mostrar al usuario.
  /// Usa AppLocalizations para soporte multiidioma.
  String localizedMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case AppErrorType.internal:
        return l10n.errorInternal;
      case AppErrorType.permission:
        return l10n.errorPermission;
      case AppErrorType.network:
        return l10n.errorNetwork;
      case AppErrorType.notFound:
        return l10n.errorNotFound;
      case AppErrorType.auth:
        return l10n.errorAuth;
      case AppErrorType.validation:
        return l10n.errorValidation;
      case AppErrorType.conflict:
        return l10n.errorConflict;
    }
  }

  @override
  String toString() => 'AppError(type: $type, detail: $debugDetail)';
}