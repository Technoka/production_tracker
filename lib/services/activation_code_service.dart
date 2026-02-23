import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activation_code_model.dart';
import '../models/activation_request_model.dart';

/// Service para gestión de códigos de activación de organizaciones
/// 
/// Maneja:
/// - Solicitudes de código (usuarios)
/// - Validación de códigos (usuarios)
/// - Creación y gestión de códigos (admin - manual)
class ActivationCodeService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _error;
  String? get error => _error;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ==================== SOLICITUDES DE CÓDIGO ====================

  /// Crear solicitud de código de activación
  Future<bool> createActivationRequest({
    required String companyName,
    required String contactEmail,
    required String contactName,
    required String contactPhone,
    String? message,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Validar que el email no tenga ya una solicitud pendiente
      // final existingRequest = await _firestore
      //     .collection('activation_requests')
      //     .where('contactEmail', isEqualTo: contactEmail)
      //     .where('status', isEqualTo: 'pending')
      //     .limit(1)
      //     .get();

      // if (existingRequest.docs.isNotEmpty) {
      //   _error = 'Ya existe una solicitud pendiente para este email';
      //   _isLoading = false;
      //   notifyListeners();
      //   return false;
      // }

      // Crear solicitud
      final request = ActivationRequestModel(
        id: '', // Se asignará automáticamente
        companyName: companyName,
        contactEmail: contactEmail,
        contactName: contactName,
        contactPhone: contactPhone,
        message: message,
        requestedAt: DateTime.now(),
        status: 'pending',
      );

      await _firestore
          .collection('activation_requests')
          .add(request.toMap());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al crear solicitud: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Obtener solicitudes pendientes del usuario
  Future<List<ActivationRequestModel>> getUserRequests(String email) async {
    try {
      final snapshot = await _firestore
          .collection('activation_requests')
          .where('contactEmail', isEqualTo: email)
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ActivationRequestModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo solicitudes: $e');
      return [];
    }
  }

  // ==================== VALIDACIÓN DE CÓDIGOS ====================

  /// Validar código de activación
  Future<ActivationCodeModel?> validateActivationCode(String code) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Buscar código
      final snapshot = await _firestore
          .collection('activation_codes')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        _error = 'Código inválido';
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final codeModel = ActivationCodeModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );

      // Verificar estado
      if (!codeModel.canBeUsed) {
        if (codeModel.isUsed) {
          _error = 'Este código ya ha sido utilizado';
        } else if (codeModel.isExpired) {
          _error = 'Este código ha expirado';
        } else {
          _error = 'Este código no está activo';
        }
        _isLoading = false;
        notifyListeners();
        return null;
      }

      _isLoading = false;
      notifyListeners();
      return codeModel;
    } catch (e) {
      _error = 'Error al validar código: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Marcar código como usado
  Future<bool> markCodeAsUsed({
    required String codeId,
    required String userId,
    required String organizationId,
  }) async {
    try {
      await _firestore
          .collection('activation_codes')
          .doc(codeId)
          .update({
        'status': 'used',
        'usedBy': userId,
        'usedAt': FieldValue.serverTimestamp(),
        'organizationId': organizationId,
      });

      return true;
    } catch (e) {
      debugPrint('Error marcando código como usado: $e');
      return false;
    }
  }

  // ==================== ADMIN: GESTIÓN DE CÓDIGOS ====================
  // Nota: Estos métodos son para uso futuro en un panel de admin
  // Por ahora, los códigos se crean manualmente en Firebase Console

  /// Stream de solicitudes pendientes (para admin)
  Stream<List<ActivationRequestModel>> watchPendingRequests() {
    return _firestore
        .collection('activation_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivationRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Obtener código por ID
  Future<ActivationCodeModel?> getCodeById(String codeId) async {
    try {
      final doc = await _firestore
          .collection('activation_codes')
          .doc(codeId)
          .get();

      if (!doc.exists) return null;

      return ActivationCodeModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error obteniendo código: $e');
      return null;
    }
  }

  // ==================== UTILIDADES ====================

  /// Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}