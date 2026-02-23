import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'app_error.dart';

/// Convierte cualquier excepción en un [AppError] estandarizado.
///
/// Uso en servicios:
/// ```dart
/// } catch (e) {
///   _appError = ErrorHandler.from(e);
///   notifyListeners();
/// }
/// ```
class ErrorHandler {
  ErrorHandler._(); // No instanciable

  /// Punto de entrada único. Acepta cualquier tipo de excepción.
  static AppError from(dynamic error) {
    final detail = _extractDetail(error);

    if (kDebugMode) {
      debugPrint('🔴 [ErrorHandler] $detail');
    }

    final type = _mapToType(error);
    return AppError(type: type, debugDetail: detail);
  }

  // ---------------------------------------------------------------------------
  // Mapeo de tipos de error
  // ---------------------------------------------------------------------------

  static AppErrorType _mapToType(dynamic error) {
    //Error de permisos
    if (error is PermissionException) return AppErrorType.permission;

    // FirebaseAuthException hereda de FirebaseException, hay que comprobarlo primero
    if (error is FirebaseAuthException) {
      return _mapAuthCode(error.code);
    }

    // FirebaseException cubre Firestore, Storage y cualquier otro plugin Firebase
    if (error is FirebaseException) {
      return _mapFirebaseCode(error.code, error.plugin);
    }

    // Errores de red genéricos lanzados como Exception o String
    final msg = error?.toString().toLowerCase() ?? '';
    if (_isNetworkError(msg)) return AppErrorType.network;
    if (_isValidationError(msg)) return AppErrorType.validation;

    // Detectar errores de permisos lanzados manualmente desde servicios
    if (_isPermissionError(msg)) return AppErrorType.permission;

    return AppErrorType.internal;
  }

  static AppErrorType _mapAuthCode(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'email-already-in-use':
      case 'user-disabled':
      case 'invalid-email':
      case 'requires-recent-login':
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
        return AppErrorType.auth;
      case 'weak-password':
        return AppErrorType.validation;
      case 'too-many-requests':
      case 'network-request-failed':
        return AppErrorType.network;
      default:
        return AppErrorType.internal;
    }
  }

  /// Mapea códigos de FirebaseException (Firestore, Storage, Functions, etc.)
  /// El campo [plugin] permite diferenciar comportamientos si fuera necesario.
  static AppErrorType _mapFirebaseCode(String code, String plugin) {
    switch (code) {
      case 'permission-denied':
      case 'unauthenticated':
      case 'unauthorized': // Storage
        return AppErrorType.permission;
      case 'not-found':
      case 'object-not-found': // Storage
        return AppErrorType.notFound;
      case 'already-exists':
        return AppErrorType.conflict;
      case 'unavailable':
      case 'deadline-exceeded':
      case 'cancelled':
      case 'resource-exhausted':
        return AppErrorType.network;
      case 'invalid-argument':
      case 'failed-precondition':
      case 'out-of-range':
        return AppErrorType.validation;
      default:
        return AppErrorType.internal;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static bool _isNetworkError(String msg) {
    return msg.contains('network') ||
        msg.contains('timeout') ||
        msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('unreachable') ||
        msg.contains('internet');
  }

  static bool _isValidationError(String msg) {
    return msg.contains('validation') ||
        msg.contains('invalid') ||
        msg.contains('required') ||
        msg.contains('obligatorio') ||
        msg.contains('formato');
  }

  static bool _isPermissionError(String msg) {
    return msg.contains('permisos') ||
        msg.contains('permission') ||
        msg.contains('autorizado') ||
        msg.contains('unauthorized') ||
        msg.contains('no tienes');
  }

  /// Extrae el mensaje técnico completo para debug.
  static String _extractDetail(dynamic error) {
    if (error is FirebaseAuthException) {
      return '[FirebaseAuth] code=${error.code} | ${error.message}';
    }
    if (error is FirebaseException) {
      return '[Firebase/${error.plugin}] code=${error.code} | ${error.message}';
    }
    return error?.toString() ?? 'Unknown error';
  }
}

/// Excepción semántica de permisos.
/// Lanzada por servicios cuando el usuario no tiene autorización.
/// ErrorHandler la mapea automáticamente a AppErrorType.permission.
class PermissionException implements Exception {
  final String message;
  const PermissionException(this.message);
  @override
  String toString() => message;
}
